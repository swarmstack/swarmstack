__swarmstack__

__A Docker swarm stack for operating highly-available containerized applications. Features a modern DevOps toolset (Prometheus / Alertmanager / Grafana) for monitoring and alerting, persistent storage, firewall management, HTTPS by default, and other high-availability features that your applications can take advantage of.__

<!-- TOC -->

- [WHY?](#why)
- [FEATURES](#features)
- [REQUIREMENTS:](#requirements)
- [SWARMSTACK INSTALLATION](#swarmstack-installation)
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
    - [Prometheus - Graphs](#prometheus---graphs)
    - [Prometheus - Alerts](#prometheus---alerts)
    - [Prometheus - Targets](#prometheus---targets)

<!-- /TOC -->

Easily deploy and update Docker swarm nodes as you scale up from at least (3) baremetal servers, ec2 instances, or virtual machines, which will host and monitor your highly-available containerized applications.

Manage one or more Docker clusters via ansible playbooks that can _(optionally)_ help you install Docker swarm, [Portworx](https://portworx.com) persistent storage for container volumes between Docker swarm nodes, and update firewall rules between the nodes as well as Docker service ports exposed by your applications.

swarmstack includes a modern DevOps stack of tools for operating Docker swarms, including monitoring and alerting of the cluster health itself as well as the health of your own applications. Swarmstack installs and updates [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides an optional automatic installation of [Portworx](https://portworx.com) for persistent storage for containers such as databases that need storage that can move to another Docker swarm node instantly, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray), or local volumes and add placement constraints to _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_) 

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

## REQUIREMENTS:

3 or more Enterprise Linux 7 (RHEL 7/CentOS 7) hosts _(baremetal / VM or a combination)_, with each contributing (1) or more additional virtual or physical _unused_ block devices or partitions into the storage cluster. _More devices usually equals better performance_.

 With [Portworx PX-Developer](https://github.com/portworx/px-dev) version we'll install a storage cluster for each set of (3) hosts added to the cluster, which will provide up to _1TB_ of persistent storage for up to _40_ volumes across those 3 nodes. When deploying or later adding more than 3 nodes in the Docker swarm, you'll add nodes in multiples of 3 and use node.label.storagegroup constraints within your Docker services to pin them to one particular grouping of 3 hosts within the larger cluster each running their own 3-node Portworx storage cluster _(e.g. nodes 1 2 3, nodes 4 5 6,  etc)_. Containers not needing persistent storage can be scheduled across the entire cluster. Only a subset of your application containers will likely require persistent storage, including swarmstack.
 
 When using [Portworx PX-Enterprise](https://portworx.com/), or bringing another storage solution, these limitations may no longer apply and a single larger storage cluster could be made available simultaneously to more nodes across the swarm cluster.

 ---
 
## SWARMSTACK INSTALLATION

- _Before proceeding, make sure your hosts have their time in sync via NTP_

- _For manual swarmstack installation instructions, see [Manual swarmstack installation.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Manual%20swarmstack%20installation.md)_

- _When installing behind a required web proxy, see [Working with swarmstack behind a web proxy.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Working%20with%20swarmstack%20behind%20a%20web%20proxy.md)_

- _Instructions for updating swarmstack are available at [Updating swarmstack.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Updating%20swarmstack.md)_

- _To deploy and monitor your own applications on the cluster, see [Adding your own applications to monitoring.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Adding%20your%20own%20applications%20to%20monitoring.md)_

- _To manually push ephemeral or batch metrics into Prometheus, see [Using Pushgateway.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Using%20Pushgateway.md)_

- _Some basic commands for working with swarmstack and Portworx storage are noted in [Notes.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Notes.md)_

```
# You should perform installation from a host outside the cluster, as the docker.yml playbook may need to reboot hosts if kernels are updated.
#
# yum install git ansible epel-release
# cd /usr/local/src/
# git clone https://github.com/swarmstack/swarmstack.git
# rsync -aq --exclude=.git swarmstack/ localswarmstack/
# cd localswarmstack/ansible
```
Edit these files: | |
---- | - |
[clusters/swarmstack](https://github.com/swarmstack/swarmstack/blob/master/ansible/clusters/swarmstack) | _Configure all of your cluster nodes and storage devices_ |
[roles/files/etc/swarmstack_fw/rules/firewall.rules](https://github.com/swarmstack/swarmstack/blob/master/ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/cluster.rules) | _Used to permit traffic to the hosts themselves_ |
[roles/files/etc/swarmstack_fw/rules/docker.rules](https://github.com/swarmstack/swarmstack/blob/master/ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/docker.rules) | _Used to limit access to Docker service ports_ |

- All of the playbooks below are idempotent and can be re-run as needed when making firewall changes or adding Docker or storage nodes to your clusters.
```
# ansible-playbook -i clusters/swarmstack playbooks/firewall.yml -k
```
* _optional (but HIGHLY recommended), you can run and re-run this playbook to manage firewalls on all of your nodes whether they run Docker or not._
```
# ansible-playbook -i clusters/swarmstack playbooks/docker.yml -k
```
* _optional, use this if you haven't already brought up a Docker swarm, or just need to add additional nodes to a new or existing cluster. This playbook will also update all yum packages on each node when run, and will reboot each host as kernels are updated._
```
# ansible-playbook -i clusters/swarmstack playbooks/etcd.yml -k
```
* _optional: used by Portworx to store storage cluster metadata in a highly-available manner. Only 3 nodes need to be defined to run etcd, and you'll probably just need to run this playbook once to establish the initial etcd cluster (which can be used by multiple Portworx clusters)._
```
# ansible-playbook -i clusters/swarmstack playbooks/portworx.yml -k
```
* _optional, installs Portworx in groups of 3 nodes each. If you are instead bringing your own persistent storage, be sure to update the pxd driver in [docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml). Add new groups of 3 hosts later as your cluster grows._ 
```
# ansible-playbook -i clusters/swarmstack playbooks/swarmstack.yml -k
```
* _deploys or redeploys the swarmstack DevOps monitoring stack to the Docker swarm cluster. This includes installing NetData on each node in order for Prometheus to collect metrics from it._

---

## NETWORK URLs

Below is mainly for documentation. After installing swarmstack below, just connect to https://swarmhost of any Docker swarm node and authenticate with your ADMIN_PASSWORD to view the links below

DevOps Tools:     | Port orservice:             | Current Distribution / Installation
---------------- | -------------------------- | ---------------
[Alertmanager](https://github.com/prometheus/alertmanager) | https://swarmhost:9093<br>_caddy:swarmstack_net:alertmanager:9093_ | prom/alertmanager:latest
AlertmanagerB    | https://swarmhost:9095<br>_caddy:swarmstack_net:alertmanagerB:9093_ | prom/alertmanager:latest
[Grafana](https://github.com/grafana/grafana) | https://swarmhost:3000<br>_caddy:swarmstack_net:grafana:3000_ | grafana/grafana:5.2.4
[Portainer](https://github.com/portainer/portainer) | https://swarmhost:9000<br>_caddy:swarmstack_net:portainer:9000_ | portainer:latest
[Prometheus](https://github.com/prometheus/prometheus) | https://swarmhost:9090<br>_caddy:swarmstack_net:prometheus:9090_ | prom/prometheus:latest
[Pushgateway](https:/github.com/prometheus/pushgateway) | https://swarmhost:9091<br>_caddy:swarmstack_net:pushgateway:9091_ | prom/pushgateway:latest
[Unsee](https://github.com/cloudflare/unsee) | https://swarmhost:9094<br>_caddy:swarmstack_net:unsee:8080_ | cloudflare/unsee:v0.9.2

---

Security: | | |
--------- | - | -
Firewall management | iptables | ansible/playbooks/firewall.yml
[Caddy](https://hub.docker.com/r/swarmstack/caddy/) | https://swarmhost:(80->443, 3000, 9090-9095, 19998) _swarmstack_net:http://caddy:9180/metrics_ | swarmstack/caddy:no-stats

Telemetry: | | |
--------- | - | -
[cAdvisor](https://github.com/google/cadvisor) | _swarmstack_net:http://cadvisor:8080/metrics_ | google/cadvisor:latest
[CouchDB](https://hub.docker.com/_/couchdb/) | _swarmstack_net:couchdb:5984_ | couchdb:latest
[Docker](https://docs.docker.com/engine/swarm/) | http://swarmhost:9323/metrics | ansible/playbooks/docker_host.yml
[etcd3](https://github.com/etcd-io/etcd) | http://swarmhost:2379/metrics | ansible/playbooks/etcd_host.yml
[Grafana](https://github.com/grafana/grafana) | _swarmstack_net:http://grafana:3000/metrics_ | grafana/grafana:latest
[NetData](https://my-netdata.io/) | (firewalled)http://swarmhost:19999 (external)https://swarmhost:19998 | ansible/playbooks/swarmstack.yml
[Portworx PX-Dev or PX-Enterprise](https://portworx.com) | http://swarmhost:9001/metrics | ansible/playbooks/portworx.yml
[Prometheus](https://github.com/prometheus/prometheus) | _swarmstack_net:http://prometheus:9090/metrics_ | prom/prometheus
[Pushgateway](https://github.com/prometheus/pushgateway) | https://swarmhost:9091/metrics<br>_swarmstack_net:http://pushgateway:9091/metrics_ | prom/pushgateway

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
### Prometheus - Graphs
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen10.png)
### Prometheus - Alerts
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus_alerts.png)
### Prometheus - Targets
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus_targets.png)

