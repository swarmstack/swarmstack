# swarmstack

A starting point for the installation, maintenance, and monitoring of highly-available Docker swarm-based containerized applications. Features a modern DevOps toolset (Prometheus / Alertmanager / Grafana) for monitoring and alerting, persistent storage, firewall management, HTTPS by default, LDAP and web-proxied network support, dynamic swarm service discovery, optional Errbot, and other HA and enterprise-grade features that your applications can take advantage of. Installation requires only cut and paste of a few commands and editing some documented files.

[![swarmstack](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/logos/swarmstack150x150.png "swarmstack")](https://youtu.be/3FpTcVnvfRg)
 
<!-- TOC -->

- [swarmstack introduction video](https://youtu.be/3FpTcVnvfRg)
- [swarmstack playlist videos](https://www.youtube.com/playlist?list=PLffspZ58HP-Nv8tDHGJoawAZQStkNzA7u)
    - [WHY?](#why)
    - [FEATURES](#features)
    - [REQUIREMENTS](#requirements)
    - [INSTALLATION](#installation)
    - [MONITORING AND ALERTING](#monitoring-and-alerting)
        - [Monitoring](#monitoring)
        - [Alerting](#alerting)
    - [SCALING](#scaling)
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
        - [Portainer - Cluster Visualizer](#portainer---cluster-visualizer)
        - [Portainer - Dashboard](#portainer---dashboard)
        - [Portainer - Stacks](#portainer---stacks)
        - [Prometheus - Graphs](#prometheus---graphs)
        - [Prometheus - Alerts](#prometheus---alerts)
        - [Prometheus - Targets](#prometheus---targets)
    - [CREDITS](#credits)
    - [FILETREE](#filetree)

<!-- /TOC -->

Easily deploy and update Docker swarm nodes as you scale up from at least (3) baremetal servers, AWS/GCE/etc instances, virtual machine(s) or just a single macOS laptop if you really need to, which will host your monitored containerized applications.

Manage one or more Docker swarm host clusters via ansible playbooks that can _(optionally)_ help you install and maintain Docker swarms, automatically install [Portworx](https://portworx.com) Developer or Enterprise persistent storage for your application's HA container volumes replicated across your swarm nodes, and also automatically update firewall configurations on all of your nodes.

swarmstack includes a modern DevOps workflow for monitoring and alerting about your containerized applications running within Docker swarms, including monitoring and alerting of the cluster health itself as well as the health of your own applications. swarmstack installs and updates [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides an optional automatic installation of [Portworx](https://portworx.com) for persistent storage for containers such as databases that need storage that can move to another Docker swarm node instantly, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray), or local volumes and add placement constraints to _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_) 

The included Grafana dashboards will help you examine the health of the cluster, and the same metrics pipeline can easily be used by your own applications and visualized in Grafana and/or alerted upon via Prometheus rules and sent to redundant Alertmanagers to perform slack/email/etc notifications.

For an overview of the flow of metrics into Prometheus, exploring metrics using the meager PromQL interface Prometheus provides, and ultimately using Grafana and other visualizers to create dashboards while using the Prometheus time-series database as a datasource, watch [Monitoring, the Prometheus way](https://www.youtube.com/watch?v=PDxcEzu62jk), read at [Prometheus: Monitoring at SoundCloud](https://developers.soundcloud.com/blog/prometheus-monitoring-at-soundcloud) and watch [How Prometheus Revolutionized Monitoring at SoundCloud](https://youtu.be/hhZrOHKIxLw).

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

A set of ansible playbooks and a docker-compose stack that:

- Tunes EL7 sysctls for optimal network performance
- _optional:docker_ Installs and configures a 3+ node Docker swarm cluster from minimal EL7 hosts (or use existing swarm)
- _optional:docker_ Automatically prunes unused Docker containers / volumes / images from nodes
- _optional:storage_ Installs and configures a 3-node etcd cluster, used by Portworx for cluster metadata
- _optional:storage_ Installs and configures HA Portworx storage cluster: default is PX Developer, change to PX Enterprise in portworx.yml (used to replicate persistent container volumes across Docker nodes)
- _swarmstack:DevOps_ Configures and deploys the swarmstack tool chain, including Prometheus and Pushgateway, redundant Alertmanager instances, Grafana, and Portainer to manage the Docker swarm via GUI. All tools are secured using HTTPS by a Caddy reverse proxy. Optional [Errbot](https://github.com/swarmstack/errbot-docker) to connect alerts to social rooms to not natively supported by Alertmanager

---

## REQUIREMENTS

There is a [docker-compose-singlebox.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose-singlebox.yml) stack that can be used to evaluate swarmstack on a single Docker swarm host without requiring etcd and Portworx or other persistent storage. Please see the INSTALLATION section for instructions on installing this _singlebox_ version of swarmstack.

3 or more Enterprise Linux 7 (RHEL 7/CentOS 7) hosts _(baremetal / VM or a combination)_, with each contributing (1) or more additional virtual or physical _unused_ block devices or partitions into the storage cluster. _More devices usually equals better performance_.

Using the [Portworx PX-Developer](https://github.com/portworx/px-dev) version by default, we'll install a storage cluster for each set of (3) hosts added to the cluster, which must provide a minimum 40GB (needed by swarmstack) up to the Portworx developer version limits of 1TB of persistent storage for up to _40_ volumes across those 3 nodes. Adding 334GB from each node would be optimal to fill out the 1TB of space. You can contribute unused block device(s) or partition(s), adding more smaller SSDs on bare-metal or cloud-provider high-IOPS block devices would provide Portworx faster storage, but Portworx functions even across 3 VMs on the same machine each contributing storage from a single shared USB2 NAS, so scale your storage depending on your expected persistent-storage workloads. Block devices or partitions larger than 1TB can be contributed, but only 1TB of persistent storage will be available without licensing the PX-Enterprise version.

When deploying or later adding more than 3 nodes in the Docker swarm, you'll add nodes in multiples of 3 and use _constraints_ such as _- node.label.storagegroup == RED_ to pin your individual services requiring persistent storage to one particular group of 3 hosts within the larger swarm cluster _(e.g. nodes 1 2 3, nodes 4 5 6,  etc)_.  Only a subset of your application services will require persistent storage and will require manual pinning, including swarmstack, if you deploy more than 3 nodes. The Portworx storage space is available for your applications to use.

Containers not requiring persistent storage can be scheduled across the entire swarm cluster.
 
When choosing [Portworx PX-Enterprise](https://portworx.com/) during installation, or when bringing another storage solution, these limitations may no longer apply and a single larger storage cluster could be made available simultaneously to more nodes across the swarm cluster without regards to pinning them to certain nodes as when using the Portworx PX-Developer version.

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

You may want to perform installation from a host outside the cluster, as running the docker.yml playbook may reboot hosts if kernels are updated (you can re-run it in the future to keep your hosts up-to-date). You can work around this by performing a 'yum update kernel' and rebooting if updated on one of your swarm hosts first and then running the ansible playbooks from that host.
```
# yum -y install epel-release && yum install git ansible

# cd /usr/local/src/

# git clone https://github.com/swarmstack/swarmstack.git

# rsync -aq --exclude=.git --exclude=.gitignore swarmstack/ localswarmstack/

# cd localswarmstack/ansible
```

There is a [docker-compose-singlebox.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose-singlebox.yml) stack that can be used to evaluate swarmstack on a single Docker swarm host without requiring etcd and Portworx or other persistent storage. This stack will save persistent named volumes to the single swarm host instead. Please see the file for installation instructions and _skip all other steps below_.

---

Edit these (4) files: | |
---- | - |
[clusters/swarmstack](https://github.com/swarmstack/swarmstack/blob/master/ansible/clusters/swarmstack) | _Configure all of your cluster nodes and storage devices_ |
[alertmanager/conf/alertmanager.yml](https://github.com/swarmstack/swarmstack/blob/master/alertmanager/conf/alertmanager.yml) | _Optional: Configure where the Alertmanagers send notifications_ |
[roles/swarmstack/files/etc/swarmstack_fw/rules/cluster.rules](https://github.com/swarmstack/swarmstack/blob/master/ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/cluster.rules) | _Used to permit traffic to the hosts themselves_ |
[roles/swarmstack/files/etc/swarmstack_fw/rules/docker.rules](https://github.com/swarmstack/swarmstack/blob/master/ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/docker.rules) | _Used to limit access to Docker service ports_ |

All of the playbooks below are idempotent and can be re-run as needed when making firewall changes or adding Docker or storage nodes to your clusters.

After execution of the swarmstack.yml playbook, you'll log into most of the tools as 'admin' and the ADMIN_PASSWORD set in [ansible/clusters/swarmstack](https://github.com/swarmstack/swarmstack/blob/master/ansible/clusters/swarmstack). You can update the ADMIN_PASSWORD later by executing _docker stack rm swarmstack_ (persistent data volumes will be preserved) and then re-running the swarmstack.yml playbook. 

Instances such as Grafana and Portainer will save credential configuration in their respective persistent data volumes. These volumes can be manually removed and would be automatically re-initialized if you ever encounter issues with a particular tool container. You would lose any historical information such as metrics if you choose to initialize an application by executing _docker volume rm swarmstack_volumename_ before re-running the swarmstack.yml playbook.

---

* ansible-playbook -i clusters/swarmstack [playbooks/firewall.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/firewall.yml) -k

    _optional (but HIGHLY recommended), you can run and re-run this playbook to manage firewalls on all of your nodes whether they run Docker or not._

---

* ansible-playbook -i clusters/swarmstack [playbooks/docker.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/docker.yml) -k

    _optional, use this if you haven't already brought up a Docker swarm, or just need to add additional nodes to a new or existing cluster. This playbook will also update all yum packages on each node when run, and will reboot each host serially if kernels are updated. You should develop a process to perform this type of update maintenance on your hosts regularly just by running this playbook again._

---

* ansible-playbook -i clusters/swarmstack [playbooks/etcd.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/etcd.yml) -k

    _optional: used by Portworx to store storage cluster metadata in a highly-available manner. Only 3 nodes need to be defined to run etcd, and you'll probably just need to run this playbook once to establish the initial etcd cluster (which can be used by multiple Portworx clusters)._
---

* ansible-playbook -i clusters/swarmstack [playbooks/portworx.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/portworx.yml) -k

    _optional, installs Portworx in groups of 3 nodes each. If you are instead bringing your own persistent storage, be sure to update the pxd driver in [docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml). Add new groups of 3 hosts later as your cluster grows._

---

* ansible-playbook -i clusters/swarmstack [playbooks/swarmstack.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/swarmstack.yml) -k

    _This deploys or redeploys the swarmstack DevOps monitoring stack to the Docker swarm cluster. This includes installing or updating NetData on each node in order for Prometheus to collect metrics from it._

---

## MONITORING AND ALERTING

### Monitoring

The Grafana _Cluster Nodes_ dashboard will provide the best visual indicators if something goes off the rails, but your DevOps team will want to keep an eye on _karma_ (which watches both Alertmanager instances in one place), or your Alertmanager instances, or and consult the Prometheus _Alerts_ tab for rules.

To attach your own applications into Prometheus monitoring, you'll need to make sure you deploy your services to attach to the swarmstack monitoring network in your own docker-compose files. See [swarmstack/errbot-docker/docker-compose-swarmstack.yml](https://github.com/swarmstack/errbot-docker/blob/master/docker-compose-swarmstack.yml) to see an example service attaching to swarmstack_net with:

```
networks:
  default:
    external:
      name: swarmstack_net
```

You'll need to expose your metrics in a Prometheus-compatible format on an HTTP port (traffic on the swarmstack_net overlay network is encrypted), and add the following labels to your service so that Prometheus will quickly start to scrape it. See [swarmstack/swarmstack/docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml) for examples of services requesting to be monitored by Prometheus:

```
    deploy:
      mode: replicated
      replicas: 1
      labels:
        prometheus.enable: "true"
        prometheus.port: "9093"
        prometheus.path: "/metrics"
```

You can use PromQL expressions within Grafana and Prometheus alike to create graphs and also Prometheus alert rules based on the same expressions, such as to alert when the availability status of some of your critical persistent volumes falls below 2. Try these:

```
px_volume_capacity_bytes
px_volume_capacity_bytes{volumename="my_volumename"}
px_volume_currhalevel
count(up)
```

See [Querying Prometheus](https://prometheus.io/docs/prometheus/latest/querying/basics/) for the basics of PromQL syntax. The limited video playlist at the top of this page is an excellent resource to understand the tools deeper.

### Alerting

You can configure the Alertmanager instances to send emails or other notifications whenever Prometheus fires an alert to them. Alerts will be sent to both Alertmanager instances, and de-duplicated using a gossip protocol between them. Please see [Alertmanager Configuration](https://prometheus.io/docs/alerting/configuration/) to understand it's built-in delivery mechanisms.

You can configure the routes and receivers for the swarmstack Alertmanager instances by editing /usr/local/src/localswarmstack/[alertmanager/conf/alertmanager.yml](https://github.com/swarmstack/swarmstack/blob/master/alertmanager/conf/alertmanager.yml)

If you need to connect to a service that isn't supported natively by Alertmanager, you have the option to configure it to fire a webhook towards a target URL, with some JSON data about the alert being sent in the payload. You can provide the receiving service yourself, or consume cloud services such as [https://www.built.io/](https://www.built.io/).

One option would be to configure a bot listening for alerts from Alertmanager instances (you could use it also as an alerting target for your code as well). Upon receiving alerts via a web server port, the bot would then relay them to an instant-message destination. swarmstack builds a Docker image of Errbot, one of many bot programs that can provide a conduit between receiving a webhook, processing the received data, and then connecting to something else (in this case, instant-messaging networks) and relaying the message to a recipient or a room's occupants. If this sounds like the option for you, please see the following project:

[https://github.com/swarmstack/errbot-docker](https://github.com/swarmstack/errbot-docker)

---

## SCALING

The data retention period for Prometheus is defaulted to 48 hours within the docker compose files, and a default 10GB Prometheus tsdb data volume will be created for HA swarmstack users. Prometheus itself is not designed for long-term storage and retrival of data, but can work with several storage back-ends as remote-read and remote-write targets. If you find that you need to perform queries on metrics data older than a few days, you should explore deploying other options for long-term storage and retrieval of Prometheus data. Prometheus can optionally replicate metrics stored within it's own internal time-series database (tsdb) out to one or more external tsdb such as InfluxDB and supports efficient remote-read and write from these longer-term storage sources.

InfluxDB and Postgres (even streaming read-replication) can be used to persist metrics data in a way that Prometheus can consume it, other [storage back-ends for Prometheus](https://prometheus.io/docs/operating/integrations/) are also available. The project [swarmstack/influxdb](https://github.com/swarmstack/influxdb) can help swarmstack users quickly bring up an optional InfluxDB remote read-write back-end for hosting longer-term Prometheus metrics.

You might instead choose to scale your Prometheus using a federated architecture across multiple Prometheus shards using [Thanos](https://github.com/improbable-eng/thanos), see [PromCon 2018: Thanos - Prometheus at Scale](https://youtu.be/Fb_lYX01IX4)

If you want to centralize your Prometheus data-sources rather than federating them, scalable designs such as [Cortex](https://github.com/cortexproject/cortex) are available for self-hosting. Commerical offerings such as [GrafanaCloud - Hosted Metrics](https://grafana.com/cloud/metrics), [InfluxDB with HA](https://docs.openstack.org/developer/performance-docs/methodologies/monitoring/influxha.html), and [Weave Cloud](https://www.weave.works/product/cloud/) are also available.

As your needs for this stack grow, you may find yourself replacing some of the services within this stack with your own tools. Hope this got you or your team heading in a great direction running applications at scale. Kubernetes is also your friend, and should be used where needed to scale parts that need to scale beyond [several](https://blog.online.net/2016/07/29/docker-swarm-an-analysis-of-a-very-large-scale-container-system/) dozen swarm nodes. You might just choose to deploy some applications (such as Cortex) on Kubernetes, and also run some of your services or development on Docker swarm. Both can be used together to solve your needs.

## NETWORK URLs

Below is mainly for documentation. After installing swarmstack, just connect to https://swarmhost of any Docker swarm node and authenticate with your ADMIN_PASSWORD to view the links below

DevOps Tools    | Connection URL<br>(proxied by Caddy) | Source / Image 
--------------- | --------------------------------- | --------------
[Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) | https://swarmhost:9093<br>https://swarmhost:9095 | Source:[https://github.com/prometheus/alertmanager](https://github.com/prometheus/alertmanager)<br>Image:[https://hub.docker.com/r/prom/alertmanager](https://hub.docker.com/r/prom/alertmanager) v0.15.2
[Karma](https://github.com/prymitive/karma/blob/master/README.md) | https://swarmhost:9094 | Source:[https://github.com/swarmstack/karma](https://github.com/swarmstack/karma)<br>Image:[https://hub.docker.com/r/swarmstack/karma](https://hub.docker.com/r/swarmstack/karma) healthcheck
[Grafana](https://grafana.com) | https://swarmhost:3000 | Source:[https://github.com/grafana/grafana](https://github.com/grafana/grafana)<br>Image:[https://hub.docker.com/r/grafana/grafana](https://hub.docker.com/r/grafana/grafana) 5.3.2
[NetData](https://my-netdata.io/) | https://swarmhost:19998/hostname/ | [ansible/playbooks/swarmstack.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/swarmstack.yml) latest
[Portainer](https://portainer.io) | https://swarmhost:9000 | Source:[https://github.com/portainer/portainer](https://github.com/portainer/portainer)<br>Image:[https://hub.docker.com/r/portainer/portainer](https://hub.docker.com/r/portainer/portainer) 1.19.2
[Prometheus](https://prometheus.io/) | https://swarmhost:9090 | Source:[https://github.com/prometheus/prometheus](https://github.com/prometheus/prometheus)<br>Image:[https://hub.docker.com/r/prom/prometheus](https://hub.docker.com/r/prom/prometheus) v2.5.0
[Pushgateway](https://prometheus.io/docs/practices/pushing/) | https://swarmhost:9091 | Source:[https:/github.com/prometheus/pushgateway](https:/github.com/prometheus/pushgateway)<br>Image:[https://hub.docker.com/r/prom/pushgateway](https://hub.docker.com/r/prom/pushgateway) v0.6.0

---

Security | Notes | Source / Image
-------- | ----- | --------------
[Caddy](https://caddyserver.com/) | Reverse proxy - see above for URLs | Source:[https://github.com/swarmstack/caddy](https://github.com/swarmstack/caddy)<br>Image:[https://hub.docker.com/r/swarmstack/caddy](https://hub.docker.com/r/swarmstack/caddy) 0.11.1:no-stats
[fail2ban](https://www.fail2ban.org) | Brute-force prevention | [ansible/playbooks/firewall.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/firewall.yml)
[iptables](https://en.wikipedia.org/wiki/Iptables) | Firewall management | [ansible/playbooks/firewall.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/firewall.yml)
[Portainer Agent](https://portainer.io) | no monitoring, contacts Portainer | Source:[https://github.com/portainer/portainer](https://github.com/portainer/portainer)<br>Image:[https://hub.docker.com/r/portainer/portainer](https://hub.docker.com/r/portainer/portainer) 1.1.2
[swarm-discovery-server](https://github.com/jmendiara/prometheus-swarm-discovery) | server: swarmstack_net:8080<br>client: no monitoring, contacts server and writes to a volume shared with Prometheus | Source:[https://github.com/jmendiara/prometheus-swarm-discovery](https://github.com/jmendiara/prometheus-swarm-discovery) 0.2.0

---

Monitoring / Telemetry | Metrics URL | Source / Image 
---------------------- | ----------- | --------------
[cAdvisor](https://github.com/google/cadvisor) | Docker overlay network:<br>http://cadvisor:8080/metrics | Source:[https://github.com/google/cadvisor](https://github.com/google/cadvisor)<br>Image:[https://hub.docker.com/r/google/cadvisor](https://hub.docker.com/r/google/cadvisor) v0.32.0
[Docker Swarm](https://docs.docker.com/engine/swarm/) | Docker Node IP:<br>http://swarmhost:9323/metrics | [ansible/playbooks/docker.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/docker.yml)
[etcd3](https://github.com/etcd-io/etcd) | Docker Node IP:<br>http://swarmhost:2379/metrics | [ansible/playbooks/etcd.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/etcd.yml)
[Grafana](https://grafana.com) | Docker overlay network:<br>http://grafana:3000/metrics | Source:[https://github.com/grafana/grafana](https://github.com/grafana/grafana)<br>Image:[https://hub.docker.com/r/grafana/grafana](https://hub.docker.com/r/grafana/grafana) 5.3.4
[NetData](https://my-netdata.io/) | Docker Node IP:<br>http://swarmhost:19999/api/v1/allmetrics | [ansible/playbooks/swarmstack.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/swarmstack.yml) latest
[Portworx](https://portworx.com) | Docker Node IP:<br>http://swarmhost:9001/metrics | [ansible/playbooks/portworx.yml](https://github.com/swarmstack/swarmstack/blob/master/ansible/playbooks/portworx.yml) px-dev or px-enterprise
[Prometheus](https://prometheus.io) | Docker overlay network:<br>http://prometheus:9090/metrics | Source:[https://github.com/prometheus/prometheus](https://github.com/prometheus/prometheus)<br>Image:[https://hub.docker.com/r/prom/prometheus](https://hub.docker.com/r/prom/prometheus) v2.5.0
[Pushgateway](https://prometheus.io/docs/practices/pushing/) | Docker overlay network:<br>https://pushgateway:9091/metrics | Source:[https:/github.com/prometheus/pushgateway](https:/github.com/prometheus/pushgateway)<br>Image:[https://hub.docker.com/r/prom/pushgateway](https://hub.docker.com/r/prom/pushgateway) v0.6.0

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
### Portainer - Cluster Visualizer
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portainer_cluster.png)
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

## CREDITS

Credit is due to the excellent DevOps stack proposed and maintained by [Stefan Prodan](https://stefanprodan.com/) and his project [swarmprom](https://github.com/stefanprodan/swarmprom).

Thanks to Mark Sullivan at Cisco for his work on the Cisco Webex Teams backend for Errbot.

Thank you Carl Bergquist at Grafana Labs for the golang updates.

Thanks goes to the team at Portworx for their excellent storage product and support.

---

## FILETREE

```
.
├── LICENSE
├── PRIVACY.md
├── README.md
├── alertmanager
│   └── conf
│       └── alertmanager.yml
├── ansible
│   ├── README.md
│   ├── clusters
│   │   └── swarmstack
│   ├── playbooks
│   │   ├── docker.yml
│   │   ├── etcd.yml
│   │   ├── firewall.yml
│   │   ├── includes
│   │   │   └── tasks
│   │   │       ├── prompt_colors
│   │   │       │   ├── set_prompt.yml
│   │   │       │   ├── set_prompts_blue.yml
│   │   │       │   ├── set_prompts_green.yml
│   │   │       │   └── set_prompts_red.yml
│   │   │       └── sysctl_el7.yml
│   │   ├── portworx.yml
│   │   ├── swarmstack.yml
│   │   └── util.yml
│   └── roles
│       ├── common
│       │   └── files
│       │       └── etc
│       │           ├── cron.daily
│       │           │   └── clean-docker
│       │           ├── docker
│       │           │   └── daemon.json
│       │           ├── swarmstack_fw
│       │           │   └── rules
│       │           │       └── common.rules
│       │           ├── systemd
│       │           │   └── system
│       │           │       └── docker.service.d
│       │           │           └── docker.conf
│       │           ├── udev
│       │           │   └── rules.d
│       │           │       └── 59-custom-txqueuelen.rules
│       │           └── yum.repos.d
│       │               ├── docker-edge.repo
│       │               ├── docker-stable.repo
│       │               └── docker-test.repo
│       └── swarmstack
│           └── files
│               └── etc
│                   ├── swarmstack_fw
│                   │   └── rules
│                   │       ├── cluster.rules
│                   │       └── docker.rules
│                   └── systemd
│                       └── system
│                           └── docker.service.d
│                               ├── docker.conf
│                               └── proxy.conf
├── caddy
│   ├── Caddyfile
│   ├── Caddyfile-singlebox
│   ├── Caddyfile.ldap
│   ├── caddycerts
│   │   └── README.md
│   ├── index-singlebox.html
│   └── index.html
├── docker-compose-singlebox.yml
├── docker-compose.yml
├── documentation
│   ├── Adding\ your\ own\ applications\ to\ monitoring.md
│   ├── Manual\ swarmstack\ installation.md
│   ├── Notes.md
│   ├── Updating\ swarmstack.md
│   ├── Using\ LDAP.md
│   ├── Using\ Pushgateway.md
│   ├── Working\ with\ swarmstack\ behind\ a\ web\ proxy.md
│   ├── logos
│   │   ├── swarmstack150x150.png
│   │   ├── swarmstack300x300.png
│   │   └── swarmstack500x500.png
│   └── screens
│       ├── docker_swarm_nodes.png
│       ├── docker_swarm_services.png
│       ├── etcd.png
│       ├── portainer-dashboard.png
│       ├── portainer-stacks.png
│       ├── portainer_cluster.png
│       ├── portworx_cluster_status.png
│       ├── portworx_volumes.png
│       ├── prometheus.png
│       ├── prometheus_alerts.png
│       ├── prometheus_targets.png
│       ├── screen1.png
│       ├── screen10.png
│       ├── screen2.png
│       ├── screen9.png
│       └── swarmstack-diagram.png
├── grafana
│   ├── dashboards
│   │   ├── cluster-nodes.json
│   │   ├── docker-containers.json
│   │   ├── etcd-dash.json
│   │   ├── portworx-cluster-dash.json
│   │   ├── portworx-volumes-dash.json
│   │   └── prometheus-2-stats.json
│   ├── dashboards.yml
│   ├── datasources
│   │   └── prometheus.yaml
│   ├── grafana.ini
│   └── ldap.toml
├── portworx
│   ├── README.md
│   └── docker-compose.yml
├── prometheus
│   ├── conf
│   │   ├── prometheus-singlebox.yml
│   │   └── prometheus.yml
│   └── rules
│       ├── container_nodes.yml
│       ├── docker_containers.yml
│       └── portworx.yml
├──karma 
│   └── karma.yaml
└── utils
    ├── itdock
    ├── lgdock
    ├── lsdock
    └── psdock

44 directories, 85 files
```
