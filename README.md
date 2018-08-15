# ungravity
## A docker swarm / prometheus / alertmanager / grafana stack with optional persistent storage and  high-availability features

### Easily deploy docker to a set of 3+ EL7 hosts (baremetal, VM, or a combination) that can be used to host highly-available containerized applications.

### Includes a working modern DevOps stack based on [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + HA [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides optional automatic installation of [Portworx PX-Dev](https://portworx.com), for persistant storage for containers volumes across nodes, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray)).

---

# (WIP) Aug 15 2018 initial github release TBA

Features a collection of ansible playbooks and a docker-compose stack that:
- Tunes EL7 sysctls for optimal network performance
- Brings up a 3-node HA ETCD cluster (used by Portworx for storage clustering)
- Brings up a 3-node Portworx PX-Dev cluster (used for persist)
- Installs and configures docker service
- Installs and configures a turn-key DevOps stack based on Prometheus and various exporters, Alertmanager, Grafana and Grafana dashboards
- Automatic pruning of unused docker containers / volumes / images from nodes


---

# Network URLs
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
Portworx storage   | 1TB / 3 host / 40 attached volumes - [Portworx PX Developer version](https://github.com/portworx/px-dev)
Prometheus         | [optionally run 2 for HA]



# INSTALLATION

### The following assumes 3 EL7 hosts (baremetal/VM/combination) each contributing (1) 350gb block device (or 2 175gb+ devices for better performance)

`git clone https://github.com/swarmstack/ungravity.git`

Edit these files: |
---- |
clusters/ungravity-dev |
roles/files/etc/ungravity_fw/rules/firewall.rules |
roles/files/etc/ungravity_fw/rules/docker.rules |

`ansible-playbook -i clusters/ungravity-dev playbooks/docker.html -k` _(optional - if you haven't already brought up a docker swarm)_

`ansible-playbook -i clusters/ungravity-dev playbooks/firewall.html -k` _(re-run to manage docker host firewalls)_

`ansible-playbook -i clusters/ungravity-dev playbooks/portworx.html -k` _(optional if bringing your own persistant storage, be sure to update the pxd driver in docker-compose.yml)_

`ansible-playbook -i clusters/ungravity-dev playbooks/swarmstack.html -k` _((re)deploy the docker monitoring stack to the cluster)_