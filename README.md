# ungravity
## A Docker swarm / Prometheus / Alertmanager / Grafana DevOps stack for running containerized applications, with optional persistent storage and high-availability features

Easily deploy and grow a docker swarm across (3) or more Enterprise Linux 7 (RHEL/CentOS) hosts _(baremetal, VM, or combination)_ that can be used to host highly-available containerized applications.

Includes a working modern DevOps monitoring stack based on [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + HA [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides optional automatic installation of [Portworx PX-Dev](https://portworx.com), for persistant storage for containers volumes across nodes, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray)). The built-in Grafana dashboards will help you browse the health of the cluster, and the same metrics pipeline through Prometheus can be used by your own applications and visualized in Grafana or alerted upon via Prometheus rules and sent to redundant Alertmanagers to perform slack/email/etc notifications.

---

## THIS IS A WORK-IN-PROGRESS (WIP) AUG 15 2018: Full ansible release soon

While you wait for the full ansible playbook release that will install the cluster for you including etcd, Portworx, Docker swarm, feel free to get a head-start by learning the DevOps stack itself, borrowed heavily from [stefanprodan/swarmprom](https://github.com/stefanprodan/swarmprom). You'll need to bring some kit of your own at the moment, namely install a 3-node cluster of baremetal or VMs running EL7 (RHEL/CentOS), each running Docker configured as a swarm with 1 or more managers, plus [etcd and Portworx PX-Developer](https://docs.portworx.com/developer/) _(or change pxd in docker-compose.yml to your persistant storage layer of choice)_.

Afterwards, download the git archive below onto a Docker manager node and deploy the docker-compose.yml file. If everything works out you can consult the charts further down this page for the locations of the DevOps tools.

\# `git clone https://github.com/swarmstack/ungravity.git`

\# `ADMIN_USER=admin ADMIN_PASSWORD=somepassword PUSH_USER=pushuser PUSH_PASSWORD=pushpass  docker stack deploy -c docker-compose.yml mon`

You can add some cron entries to each node to forward dockerd/portworx/etcd metrics into the Pushgateway so that Prometheus can scrape them too (`crontab -e`):

`*/1 * * * * curl http://127.0.0.1:9001/metrics > /tmp/portworx.metrics 2>/dev/null && sed '/go_/d' /tmp/portworx.metrics | curl -u pushuser:pushpass --data-binary @- http://127.0.0.1:9091/metrics/job/portworx/instance/`hostname -a` >/dev/null 2>&1`

`*/1 * * * * sleep 2 && curl http://127.0.0.1:9323/metrics > /tmp/dockerd.metrics 2>/dev/null && sed '/go_/d' /tmp/dockerd.metrics | curl -u pushuser:pushpass --data-binary @- http://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1`

`*/1 * * * * sleep 4 && curl http://127.0.0.1:2379/metrics > /tmp/etcd.metrics 2>/dev/null && cat /tmp/etcd.metrics | curl -u pushuser:pushpass --data-binary @- http://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1`


You'll want to configure a firewall if you need to limit access to the exposed Docker service ports below, and any others your other applications bring. Generally speaking this means allowing access to specific IPs and then to no others by modifying the DOCKER-USER iptables chain. This is because routing for exposed Docker service ports happens through the kernel FORWARD chain. firewalld or iptables (recommended: `yum remove firewalld; yum install iptables iptables-services`) can be used to program the kernel's firewall chains:

`iptables -F DOCKER-USER  # blank out the DOCKER-USER chain`

`iptables -A DOCKER-USER -s 10.0.138.1/32 -p tcp -m tcp --dport 3000 -j ACCEPT  # allow Grafana from 1 IP`

`iptables -A DOCKER-USER -p tcp -m tcp --dport 3000 -j DROP  # block all others`

_The default action of the chain should just return, so that the FORWARD chain can continue into the other forwarding chains that Docker maintains :_

`iptables -A DOCKER-USER -j RETURN`


You'll need to similarly protect each node in the swarm, as Docker swarm will accept traffic to service ports on all nodes and forward to the correct node. An ansible playbook will soon be included here that can be used to manage the firewalls on all of the Docker nodes.

---

## WHY? 

Portworx provides a high-availability storage solution that seeks to eliminate "ERROR: volume still attached to another node" situations that can be encountered with some other block device pooling storage solutions, [situations can arise](https://portworx.com/ebs-stuck-attaching-state-docker-containers/) such as RexRay or EBS volumes getting stuck detaching from another node. 

---

## Features a collection of ansible playbooks and a docker-compose stack that:
- Tunes EL7 sysctls for optimal network performance
- Optionally brings up HA ETCD cluster (used by Portworx for cluster metadata)
- Optionally brings up HA Portworx PX-Dev storage cluster (used to persistent container volumes across nodes)
- Optionally brings up a 3+ node docker swarm cluster
- Deploys and configures a turn-key HA DevOps Docker swarm stack, based on Prometheus and various exporters, Alertmanager, Grafana and Grafana dashboards
- Automatically prunes unused Docker containers / volumes / images from nodes

---

## NETWORK URLs:
DevOps Tools:     | Port(s):                  | Distribution/Installation
---------------- | -------------------------- | ---------------
Alertmanager     | 9093,9095 (->mon_net:9093) | prom/alertmanager
Docker Swarm     | 9323:/metrics              | ansible->yum docker
Grafana          | 3000 (/metrics)            | grafana:latest
Portworx storage | 9001:/metrics              | ansible->portworx/px-dev
Prometheus       | 9090 (/metrics)            | prom/prometheus
Unsee            | 9094                       | cloudflare/unsee::v0.8.0

---

Security: | | |
--------- | - | -
Firewall management | iptables                 | ansible->/etc/ungravity_fw
caddy reverse proxy	| 3000,9090-9091,9093-9095 | stefanprodan/caddy:latest

---

Telemetry: | | | 
--------- | - | -
cAdvisor      | mon_net:8080/metrics | google/cadvisor
Etcd3         | 2379:/metrics        | ansible->git clone coreos/etcdv3.3.9
Node-exporter | mon_net:9100/metrics | stefanprodan/swarmprom-node-exporter:v0.15.2
Pushgateway   | 9091:/metrics        | prom/pushgateway

---

## REQUIREMENTS:

3 or more Enterprise Linux 7 (RHEL/CentOS) hosts _(baremetal / VM or a combination)_, with each contributing (1) or more additional virtual or physical _unused_ block devices to the storage cluster. _More devices = better performance_.

 With [Portworx PX-Developer](https://github.com/portworx/px-dev) version we'll install a storage cluster for each set of (3) hosts added to the cluster, which will provide up to _1TB_ of persistent storage for up to _40_ volumes across those 3 nodes. When deploying more than 3 nodes in the Docker swarm, you'll use constraints and node tags within your Docker services to pin them to one particular grouping of 3 hosts within the larger cluster _(e.g. nodes 1 2 3, nodes 4 5 6,  etc)_. Containers not needing persistent storage can be scheduled across the entire cluster. Only a subset of your application containers will likely require persistent storage. 
 
 When using [Portworx PX-Enterprise](https://portworx.com/) or bringing another storage solution, these limitations may no longer apply and the storage can be made available simultaneously to a number of nodes across the swarm cluster.

 ---
 
## INSTALLATION (please ignore for now, but this is what's coming):
`git clone https://github.com/swarmstack/ungravity.git`

Edit these files: | |
---- | - |
clusters/ungravity-dev | _(defines the nodes and IP addresses of the cluster)_ |
roles/files/etc/ungravity_fw/rules/firewall.rules | _(used to permit traffic to the hosts themselves)_ |
roles/files/etc/ungravity_fw/rules/docker.rules | _(used to limit access to Docker service ports)_ |

`ansible-playbook -i clusters/ungravity-dev playbooks/docker.html -k` 

- _(optional if you haven't already brought up a Docker swarm)_

`ansible-playbook -i clusters/ungravity-dev playbooks/firewall.html -k` 

- _(run and re-run to manage firewalls on all Docker swarm nodes)_

`ansible-playbook -i clusters/ungravity-dev playbooks/portworx.html -k`

- _(optional if bringing your own persistant storage, be sure to update the pxd driver in docker-compose.yml)_

`ansible-playbook -i clusters/ungravity-dev playbooks/swarmstack.html -k`

- _(re)deploy the Docker monitoring stack to the cluster_
