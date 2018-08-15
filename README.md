# ungravity
## A docker swarm / prometheus / alertmanager / grafana stack with optional persistent storage and  high-availability features

### Easily deploy and grow a docker swarm across (3) or more Enterprise Linux 7 (RHEL/CentOS) hosts _(baremetal, VM, or combination)_ that can be used to host highly-available containerized applications.

### Includes a working modern DevOps stack based on [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + HA [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides optional automatic installation of [Portworx PX-Dev](https://portworx.com), for persistant storage for containers volumes across nodes, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray)).

---

# (WIP) Aug 15 2018 initial github release TBA

## Features a collection of ansible playbooks and a docker-compose stack that:
- Tunes EL7 sysctls for optimal network performance
- Optionally brings up HA ETCD cluster (used by Portworx for cluster metadata)
- Optionally brings up HA Portworx PX-Dev storage cluster (used to persistent container volumes across nodes)
- Optionally brings up a 3+ node docker swarm cluster
- Deploys and configures a turn-key HA DevOps docker swarm stack, based on Prometheus and various exporters, Alertmanager, Grafana and Grafana dashboards
- Automatically prunes unused docker containers / volumes / images from nodes


---

# NETWORK URLs:
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
Firewall management | iptables                 | ansible->/etc/caa_fw
caddy reverse proxy	| 3000,9090-9091,9093-9095 | stefanprodan/caddy:latest

---

Telemetry: | | | 
--------- | - | -
cAdvisor      | mon_net:8080/metrics | google/cadvisor
Etcd3         | 2379:/metrics        | ansible->git clone coreos/etcdv3.3.9
Node-exporter | mon_net:9100/metrics | stefanprodan/swarmprom-node-exporter:v0.15.2
Pushgateway   | 9091:/metrics        | prom/pushgateway

---

High Availability: | |
------------------ | - |
Alertmanager       |
Docker Swarm       |
Etcd3              |
Portworx storage   | Limits per 3-node cluster:  1TB / 40 attached volumes - [Portworx PX Developer version](https://github.com/portworx/px-dev)
Prometheus         | [optionally run 2 for HA]


# REQUIREMENTS:

3 or more Enterprise Linux 7 (RHEL/CentOS) hosts _(baremetal / VM or a combination)_, with each contributing (1) or more additional virtual or physical _unused_ block devices to the storage cluster. _More devices = better performance_.

 With [Portworx PX Developer version](https://github.com/portworx/px-dev) we'll install a storage cluster for each set of (3) hosts added to the cluster, which will provide up to _1TB_ of persistent storage for up to _40_ volumes across those 3 nodes. When deploying more than 3 nodes in the docker swarm, you'll use constraints and node tags within your docker services to pin them to one particular grouping of 3 hosts within the larger cluster _(e.g. nodes 1 2 3, nodes 4 5 6,  etc)_. Containers not needing persistent storage can be scheduled across the entire cluster. Only a subset of your application containers will likely require persistent storage. 
 
 When using [Portworx PX Enterprise](https://portworx.com/) or bringing another storage solution, these limitations may no longer apply and the storage can be made available simultaneously to a larger number of nodes the swarm cluster. 

# INSTALLATION:
`git clone https://github.com/swarmstack/ungravity.git`

Edit these files: | |
---- | - |
clusters/ungravity-dev | _(defines the nodes and IP addresses of the cluster)_ |
roles/files/etc/ungravity_fw/rules/firewall.rules | _(used to permit traffic to the hosts themselves)_ |
roles/files/etc/ungravity_fw/rules/docker.rules | _(used to limit access to docker service ports)_ |

`ansible-playbook -i clusters/ungravity-dev playbooks/docker.html -k` 

- _(optional if you haven't already brought up a docker swarm)_

`ansible-playbook -i clusters/ungravity-dev playbooks/firewall.html -k` 

- _(run and re-run to manage firewalls on all docker swarm nodes)_

`ansible-playbook -i clusters/ungravity-dev playbooks/portworx.html -k`

- _(optional if bringing your own persistant storage, be sure to update the pxd driver in docker-compose.yml)_

`ansible-playbook -i clusters/ungravity-dev playbooks/swarmstack.html -k`

- _(re)deploy the docker monitoring stack to the cluster_