# ungravity
## A docker swarm / prometheus / alertmanager / grafana stack with optional persistent storage and  high availability features

DevOps Tools:     | Port(s):                 | Distribution/Installation
---------------- | ------------------------- | ---------------
Alertmanager     | 9093,9095(->mon_net:9093) | prom/alertmanager
Docker Swarm     | 9323:/metrics             | ansible->yum docker
Grafana          | 3000 (/metrics)           | grafana:latest
Portworx storage | 9001:/metrics             | ansible->portworx/px-dev
Prometheus       | 9090 (/metrics)           | prom/prometheus
Unsee            | 9094                      | cloudflare/unsee::v0.8.0

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
