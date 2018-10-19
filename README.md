__swarmstack__

__A Docker swarm stack for operating highly-available containerized applications. Features a modern DevOps toolset (Prometheus / Alertmanager / Grafana) for monitoring and alerting, persistent storage, firewall management, HTTPS by default, LDAP and web-proxied network support, optional Errbot, and other high-availability features that your applications can take advantage of. Installation requires only cut and paste of a few commands and editing some documented files.__

<!-- TOC -->

- [WHY?](#why)
- [FEATURES](#features)
- [REQUIREMENTS](#requirements)
- [INSTALLATION](#installation)
- [MONITORING AND ALERTING](#monitoring-and-alerting)
- [NETWORK URLs](#network-urls)
- [SCREENSHOTS](#screenshots)
    - [Caddy Link Dashboard](#caddy-link-dashboard)
    - [Grafana Dashboards List](#grafana-dashboards-list)
    - [Grafana - Docker Swarm Nodes](#grafana---docker-swarm-nodes)
    - [Grafana - Docker Swarm Services](#grafana---docker-swarm-services)
    - [Grafana - etcd](#grafana---etcd)
    - [Grafana - Portworx Cluster Status](#grafana---portworx-cluster-status)
    - [Grafana - Portworx Volume Status](#grafana---portworx-volume-status)
    - [Grafana - Prometheus Stats](#grafana---prometheus-stats)
    - [Alertmanager](#alertmanager)
    - [Portainer - Dashboard](#portainer---dashboard)
    - [Portainer - Stacks](#portainer---stacks)
    - [Prometheus - Graphs](#prometheus---graphs)
    - [Prometheus - Alerts](#prometheus---alerts)
    - [Prometheus - Targets](#prometheus---targets)

<!-- /TOC -->

Easily deploy and update Docker swarm nodes as you scale up from at least (3) baremetal servers, ec2 instances, or virtual machines, which will host and monitor your highly-available containerized applications.

Manage one or more Docker clusters via ansible playbooks that can _(optionally)_ help you install Docker swarm, [Portworx](https://portworx.com) persistent storage for container volumes between Docker swarm nodes, and update firewall rules between the nodes as well as Docker service ports exposed by your applications.

swarmstack includes a modern DevOps workflow for operating containerized applications within Docker swarms, including monitoring and alerting of the cluster health itself as well as the health of your own applications. swarmstack installs and updates [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides an optional automatic installation of [Portworx](https://portworx.com) for persistent storage for containers such as databases that need storage that can move to another Docker swarm node instantly, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray), or local volumes and add placement constraints to _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_) 

The built-in Grafana dashboards will help you stay aware of the health of the cluster, and the same metrics pipeline can easily be used by your own applications and visualized in Grafana and/or alerted upon via Prometheus rules and sent to redundant Alertmanagers to perform slack/email/etc notifications. Prometheus can optionally replicate metrics stored within it's own internal time-series database (tsdb) out to one or more external tsdb such as InfluxDB for analysis or longer-term storage, or to cloud services such as [Weave Cloud](https://www.weave.works/product/cloud/) or the like. 

For an overview of the flow of metrics into Prometheus, exploring metrics using the meager PromQL interface Prometheus provides, and ultimately using Grafana and other visualizers to create dashboards while using the Prometheus time-series database as a datasource, watch [Monitoring, the Prometheus way](https://www.youtube.com/watch?v=PDxcEzu62jk), and take a look at [Prometheus: Monitoring at SoundCloud](https://developers.soundcloud.com/blog/prometheus-monitoring-at-soundcloud)

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/swarmstack-diagram.png "swarmstack architecture")

## WHY? 

A modern data-driven monitoring and alerting solution helps even the smallest of DevOps teams to develop and support containerized applications, and provides an ability to observe how applications perform over time, correlated to events occuring on the platform running them as well. Data-driven alerting makes sure the team knows when things go off-the-rails, but Prometheus also brings with it an easier way to configure alerts based on aggregated time-series data, for example:

```
alert: node_disk_fill_rate_6h
expr: predict_linear(node_filesystem_free{mountpoint="/"}[1h],
  6 * 3600) * on(instance) group_left(node_name) node_meta < 0
for: 1h
labels:
  severity: critical
annotations:
  description: Swarm node {{ $labels.node_name }} disk is going to fill up in 6h.
  summary: Disk fill alert for Swarm node '{{ $labels.node_name }}'
```

![](https://raw.githubusercontent.com/portworx/px-dev/master/images/mysql.png "Portworx replicating volumes")

Portworx provides a high-availability storage solution that seeks to eliminate "ERROR: volume still attached to another node" situations that can be encountered with some other block device pooling storage solutions, [situations can arise](https://portworx.com/ebs-stuck-attaching-state-docker-containers/) such as RexRay or EBS volumes getting stuck detaching from the old node and can't be mounted to the new node that a container moved to. Portworx replicates volumes across nodes in real-time so the data is already present on the new node when the new container starts up, speeding service recovery and reconvergence times.

---

## FEATURES

- A collection of ansible playbooks and a docker-compose stack that:
- Tunes EL7 sysctls for optimal network performance
- Optionally brings up a 3+ node docker swarm cluster from minimal EL7 hosts
- Optionally brings up HA etcd cluster (used by Portworx for cluster metadata)
- Optionally brings up HA Portworx PX-Dev storage cluster (used to replicate persistent container volumes across Docker nodes)
- Configures and deploys a turn-key HA DevOps stack Docker, based on Prometheus and various exporters, Alertmanager,Grafana dashboards
- Automatically prunes unused Docker containers / volumes / images from nodes

---

## REQUIREMENTS

3 or more Enterprise Linux 7 (RHEL 7/CentOS 7) hosts _(baremetal / VM or a combination)_, with each contributing (1) or more additional virtual or physical _unused_ block devices or partitions into the storage cluster. _More devices usually equals better performance_.

 With [Portworx PX-Developer](https://github.com/portworx/px-dev) version we'll install a storage cluster for each set of (3) hosts added to the cluster, which will provide up to _1TB_ of persistent storage for up to _40_ volumes across those 3 nodes. When deploying or later adding more than 3 nodes in the Docker swarm, you'll add nodes in multiples of 3 and use node.label.storagegroup constraints within your Docker services to pin them to one particular grouping of 3 hosts within the larger cluster each running their own 3-node Portworx storage cluster _(e.g. nodes 1 2 3, nodes 4 5 6,  etc)_. Containers not needing persistent storage can be scheduled across the entire cluster. Only a subset of your application containers will likely require persistent storage, including swarmstack.
 
 When using [Portworx PX-Enterprise](https://portworx.com/), or bringing another storage solution, these limitations may no longer apply and a single larger storage cluster could be made available simultaneously to more nodes across the swarm cluster.

 ---
 
## INSTALLATION

- _Before proceeding, make sure your hosts have their time in sync via NTP_

- _For manual swarmstack installation instructions, see [Manual swarmstack installation.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Manual%20swarmstack%20installation.md)_

- _When installing behind a required web proxy, see [Working with swarmstack behind a web proxy.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Working%20with%20swarmstack%20behind%20a%20web%20proxy.md)_

- _Instructions for updating swarmstack are available at [Updating swarmstack.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Updating%20swarmstack.md)_

- _To deploy and monitor your own applications on the cluster, see [Adding your own applications to monitoring.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Adding%20your%20own%20applications%20to%20monitoring.md)_

- _To manually push ephemeral or batch metrics into Prometheus, see [Using Pushgateway.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Using%20Pushgateway.md)_

- _For reference on what swarmstack configures when enabling LDAP, see [Using LDAP.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Using%20LDAP.md)_

- _Some basic commands for working with swarmstack and Portworx storage are noted in [Notes.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Notes.md)_

- _Open an issue. [How do I use this project?](https://github.com/swarmstack/swarmstack/issues/1)_ 

You should perform installation from a host outside the cluster, as the docker.yml playbook may need to reboot hosts if kernels are updated.
```
# yum install git ansible epel-release
# cd /usr/local/src/
# git clone https://github.com/swarmstack/swarmstack.git
# rsync -aq --exclude=.git swarmstack/ localswarmstack/
# cd localswarmstack/ansible
```
Edit these files: | |
---- | - |
[clusters/swarmstack](https://github.com/swarmstack/swarmstack/blob/master/ansible/clusters/swarmstack) | _Configure all of your cluster nodes and storage devices_ |
[alertmanager/conf/alertmanager.yml](https://github.com/swarmstack/swarmstack/blob/master/alertmanager/conf/alertmanager.yml) | _Optional: Configure where the Alertmanagers send notifications_ |
[roles/swarmstack/files/etc/swarmstack_fw/rules/firewall.rules](https://github.com/swarmstack/swarmstack/blob/master/ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/cluster.rules) | _Used to permit traffic to the hosts themselves_ |
[roles/swarmstack/files/etc/swarmstack_fw/rules/docker.rules](https://github.com/swarmstack/swarmstack/blob/master/ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/docker.rules) | _Used to limit access to Docker service ports_ |

All of the playbooks below are idempotent and can be re-run as needed when making firewall changes or adding Docker or storage nodes to your clusters.

After execution of the swarmstack.yml playbook, you'll log into most of the tools as 'admin' and the ADMIN_PASSWORD you've set. You can update the ADMIN_PASSWORD later by executing _docker stack rm swarmstack_ (persistent data volumes will be preserved) and then re-running the swarmstack.yml playbook. Instances such as Grafana and Portainer will save credential configuration in their respective persistent data volumes. These volumes can be manually removed and would be automatically re-initialized if you ever encounter issues with a particular tool container. You would lose any historical information such as metrics if you choose to initialize an application by executing _docker volume rm swarmstack_volumename_ before re-running the swarmstack.yml playbook.

---
```
# ansible-playbook -i clusters/swarmstack playbooks/firewall.yml -k
```
* _optional (but HIGHLY recommended), you can run and re-run this playbook to manage firewalls on all of your nodes whether they run Docker or not._
---
```
# ansible-playbook -i clusters/swarmstack playbooks/docker.yml -k
```
* _optional, use this if you haven't already brought up a Docker swarm, or just need to add additional nodes to a new or existing cluster. This playbook will also update all yum packages on each node when run, and will reboot each host as kernels are updated._
---
```
# ansible-playbook -i clusters/swarmstack playbooks/etcd.yml -k
```
* _optional: used by Portworx to store storage cluster metadata in a highly-available manner. Only 3 nodes need to be defined to run etcd, and you'll probably just need to run this playbook once to establish the initial etcd cluster (which can be used by multiple Portworx clusters)._
---
```
# ansible-playbook -i clusters/swarmstack playbooks/portworx.yml -k
```
* _optional, installs Portworx in groups of 3 nodes each. If you are instead bringing your own persistent storage, be sure to update the pxd driver in [docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml). Add new groups of 3 hosts later as your cluster grows._
---
```
# ansible-playbook -i clusters/swarmstack playbooks/swarmstack.yml -k
```
* _deploys or redeploys the swarmstack DevOps monitoring stack to the Docker swarm cluster. This includes installing NetData on each node in order for Prometheus to collect metrics from it._

---

## MONITORING AND ALERTING

### Monitoring

The Grafana _Cluster Nodes_ dashboard will provide the best visual indicators if something goes off the rails, but your DevOps team will want to keep an eye on _Unsee_ (which watches both Alertmanager instances in one place), or the Prometheus _Alerts_ tab.

### Alerting

You can configure the Alertmanager instances to send emails or other notifications whenever Prometheus fires an alert to them. Alerts will be sent to both Alertmanager instances, and de-duplicated using a gossip protocol between them. Please see [Alertmanager Configuration](https://prometheus.io/docs/alerting/configuration/) to understand it's built-in delivery mechanisms.

You can configure the routes and receivers for the swarmstack Alertmanager instances by editing /usr/local/src/localswarmstack/[alertmanager/conf/alertmanager.yml](https://github.com/swarmstack/swarmstack/blob/master/alertmanager/conf/alertmanager.yml)

If you need to connect to a service that isn't supported natively by Alertmanager, you have the option to configure it to fire a webhook towards a target URL, with some JSON data about the alert being sent in the payload. You can provide the receiving service yourself, or consume cloud services such as [https://www.built.io/](https://www.built.io/).

One option would be to configure a bot listening for alerts from Alertmanager instances (you could use it also as an alerting target for your code as well). Upon receiving alerts via a web server port, the bot would then relay them to an instant-message destination. swarmstack builds Docker images of Errbot, one of many bot programs that can provide a conduit between receiving a webhook, processing the received data, and then connecting to something else (in this case, instant-messaging networks) and relaying the message to a recipient or a room's occupants. If this sounds like the option for you, swarmstack currently builds 2 Docker images, one includes just the Alertmanager receiver and Errbot itself, which has built-in support for several instant-message networks, and a second Docker image to support Cisco Webex Teams connections where needed:

[https://github.com/swarmstack/errbot-docker-alertmanager](https://github.com/swarmstack/errbot-docker-alertmanager)

[https://github.com/swarmstack/errbot-docker-webex-alertmanager](https://github.com/swarmstack/errbot-docker-webex-alertmanager) _Currently only supports direct-message channel with the bot, but is under active development to support room announcements as well_

---

## NETWORK URLs

Below is mainly for documentation. After installing swarmstack below, just connect to https://swarmhost of any Docker swarm node and authenticate with your ADMIN_PASSWORD to view the links below

DevOps Tools    | Connection URL<br>(proxied by Caddy) | Source / Image 
--------------- | --------------------------------- | --------------
[Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) | _https://swarmhost:9093_ | Source:[https://github.com/prometheus/alertmanager](https://github.com/prometheus/alertmanager)<br>Image:[https://hub.docker.com/r/prom/alertmanager](https://hub.docker.com/r/prom/alertmanager) v0.15.2
[Alertmanager](https://prometheus.io/docs/alerting/alertmanager/)B | _https://swarmhost:9095_ | Source:[https://github.com/prometheus/alertmanager](https://github.com/prometheus/alertmanager)<br>Image:[https://hub.docker.com/r/prom/alertmanager](https://hub.docker.com/r/prom/alertmanager) v0.15.2
[Grafana](https://grafana.com) | _https://swarmhost:3000_ | Source:[https://github.com/grafana/grafana](https://github.com/grafana/grafana)<br>Image:[https://hub.docker.com/r/grafana/grafana](https://hub.docker.com/r/grafana/grafana) 5.3.1
[NetData](https://my-netdata.io/) | _https://swarmhost:19998/hostname/_ | [ansible/playbooks/swarmstack.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/swarmstack.yml)
[Portainer](https://portainer.io) | _https://swarmhost:9000_ | Source:[https://github.com/portainer/portainer](https://github.com/portainer/portainer)<br>Image:[https://hub.docker.com/r/portainer/portainer](https://hub.docker.com/r/portainer/portainer) 1.19.2
[Prometheus](https://prometheus.io/) | _https://swarmhost:9090_ | Source:[https://github.com/prometheus/prometheus](https://github.com/prometheus/prometheus)<br>Image:[https://hub.docker.com/r/prom/prometheus](https://hub.docker.com/r/prom/prometheus) v2.4.3
[Pushgateway](https://prometheus.io/docs/practices/pushing/) | _https://swarmhost:9091_ | Source:[https:/github.com/prometheus/pushgateway](https:/github.com/prometheus/pushgateway)<br>Image:[https://hub.docker.com/r/prom/pushgateway](https://hub.docker.com/r/prom/pushgateway) v0.6.0
[Unsee](https://github.com/cloudflare/unsee/blob/master/README.md) | _https://swarmhost:9094_ | Source:[https://github.com/cloudflare/unsee](https://github.com/cloudflare/unsee)<br>Image:[https://hub.docker.com/r/cloudflare/unsee](https://hub.docker.com/r/cloudflare/unsee) v0.9.2

---

Security | Notes | Source / Image
-------- | ----- | --------------
[Caddy](https://caddyserver.com/) | Reverse proxy - see above for URLs | Source:[https://github.com/swarmstack/caddy](https://github.com/swarmstack/caddy)<br>Image:[https://hub.docker.com/r/swarmstack/caddy](https://hub.docker.com/r/swarmstack/caddy) no-stats
[fail2ban](https://www.fail2ban.org) | Brute-force prevention | [ansible/playbooks/firewall.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/firewall.yml)
[iptables](https://en.wikipedia.org/wiki/Iptables) | Firewall management | [ansible/playbooks/firewall.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/firewall.yml)

---

Monitoring / Telemetry | Metrics URL | Source / Image 
---------------------- | ----------- | --------------
[cAdvisor](https://github.com/google/cadvisor) | Docker overlay network swarmstack_net:<br>_http://cadvisor:8080/metrics_ | Source:[https://github.com/google/cadvisor](https://github.com/google/cadvisor)<br>Image:[https://hub.docker.com/r/google/cadvisor](https://hub.docker.com/r/google/cadvisor) v0.31.0
[Docker Swarm](https://docs.docker.com/engine/swarm/) | Docker Node IP:<br>_http://swarmhost:9323/metrics_ | [ansible/playbooks/docker.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/docker.yml)
[etcd3](https://github.com/etcd-io/etcd) | Docker Node IP:<br>_http://swarmhost:2379/metrics_ | [ansible/playbooks/etcd.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/etcd.yml)
[Grafana](https://grafana.com) | Docker overlay network swarmstack_net:<br>_http://grafana:3000/metrics_ | Source:[https://github.com/grafana/grafana](https://github.com/grafana/grafana)<br>Image:[https://hub.docker.com/r/grafana/grafana](https://hub.docker.com/r/grafana/grafana) 5.3.1
[NetData](https://my-netdata.io/) | Docker Node IP:<br>_http://swarmhost:19999/api/v1/allmetrics_ | [ansible/playbooks/swarmstack.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/swarmstack.yml)
[Portworx](https://portworx.com) | Docker Node IP:<br>_http://swarmhost:9001/metrics_ | [ansible/playbooks/portworx.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/portworx.yml)
[Prometheus](https://prometheus.io) | Docker overlay network swarmstack_net:<br>_http://prometheus:9090/metrics_ | Source:[https://github.com/prometheus/prometheus](https://github.com/prometheus/prometheus)<br>Image:[https://hub.docker.com/r/prom/prometheus](https://hub.docker.com/r/prom/prometheus) v2.4.3
[Pushgateway](https://prometheus.io/docs/practices/pushing/) | Docker overlay network swarmstack_net:<br>_https://pushgateway:9091/metrics_ | Source:[https:/github.com/prometheus/pushgateway](https:/github.com/prometheus/pushgateway)<br>Image:[https://hub.docker.com/r/prom/pushgateway](https://hub.docker.com/r/prom/pushgateway) v0.6.0

---

## SCREENSHOTS

### Caddy Link Dashboard
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen1.png)
### Grafana Dashboards List
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen2.png)
### Grafana - Docker Swarm Nodes
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/docker_swarm_nodes.png)
### Grafana - Docker Swarm Services
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/docker_swarm_services.png)
### Grafana - etcd
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/etcd.png)
### Grafana - Portworx Cluster Status
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portworx_cluster_status.png)
### Grafana - Portworx Volume Status
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portworx_volumes.png)
### Grafana - Prometheus Stats
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus.png)
### Alertmanager
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen9.png)
### Portainer - Dashboard
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portainer-dashboard.png)
### Portainer - Stacks
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portainer-stacks.png)
### Prometheus - Graphs
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen10.png)
### Prometheus - Alerts
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus_alerts.png)
### Prometheus - Targets
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus_targets.png)
---
Credit is due to the excellent DevOps stack proposed and maintained by [Stefan Prodan](https://stefanprodan.com/) and his project [swarmprom](https://github.com/stefanprodan/swarmprom).
