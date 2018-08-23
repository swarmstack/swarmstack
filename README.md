# swarmstack
## A Docker swarm / Prometheus / Alertmanager / Grafana DevOps stack for running containerized applications, with optional persistent storage and high-availability features

Easily deploy and grow a docker swarm across (3) or more baremetal servers, ec2 instances, or VMs _(in any combination)_ that can be used to host highly-available containerized applications.

Includes a working modern DevOps monitoring stack based on [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + HA [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides an optional automatic installation of [Portworx PX-Developer](https://portworx.com), for persistent storage for container volume across nodes, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray)). The built-in Grafana dashboards will help you stay aware of the health of the cluster, and the same metrics pipeline can be used by your own applications and visualized in Grafana or alerted upon via Prometheus rules and sent to redundant Alertmanagers to perform slack/email/etc notifications. Metrics from Prometheus can be persisted out to one or more external timeseries databases (tsdb) such as InfluxDB, or to cloud services such as [Weave Cloud](https://www.weave.works/product/cloud/) or the like. 

For an overview of the flow of metrics into Prometheus, exploring metrics using the meager PromQL interface Prometheus provides, and ultimately using Grafana and other visualizers to create dashboards while using the Prometheus tsdb as a datasource, see: [Monitoring, the Prometheus way](https://www.youtube.com/watch?v=PDxcEzu62jk)

---

## WHY? 

A modern data-driven monitoring and alerting solution helps DevOps teams develop and support containerized applications, providing the ability to observe metrics about how the application performs over time, and alerting the team when things go off-the-rails. This project, like others before it, attempts to reduce the installation steps necessary to install and configure such a stack, in a way that can be easily deployed to one of more clusters of Docker swarm.

Portworx provides a high-availability storage solution that seeks to eliminate "ERROR: volume still attached to another node" situations that can be encountered with some other block device pooling storage solutions, [situations can arise](https://portworx.com/ebs-stuck-attaching-state-docker-containers/) such as RexRay or EBS volumes getting stuck detaching from the old node and can't be mounted to the new node that a container moved to. Portworx replicates volumes across nodes in real-time so the data is already present on the new node when the new container starts up, speeding service recovery and reconvergence times.

---

## THIS IS A WORK-IN-PROGRESS (WIP) AUGUST 2018: Full ansible release soon

While you wait for the full ansible playbook release that will install the cluster for you including etcd, Portworx, Docker swarm, feel free to get a head-start by learning the DevOps stack itself, borrowed heavily from [stefanprodan/swarmprom](https://github.com/stefanprodan/swarmprom). You'll need to bring some kit of your own at the moment, namely install a 3-node cluster of physical or virtual nodes, each running Docker configured as a swarm with 1 or more managers, plus [etcd](https://docs.portworx.com/maintain/etcd.html) and [Portworx PX-Developer](https://docs.portworx.com/developer/) or PX-Enterprise _(or change pxd in docker-compose.yml to your persistent storage layer of choice)_. The instuctions below were tested on EL7 (RHEL/CentOS), but can be adapted to your linux distribution of choice. The inital release of ansible installation playbooks will focus on EL7, but support for CoreOS and ubuntu hosts will be added over time to the same playbooks.

Before proceeding, make sure your hosts have their time in sync via NTP

_Hint_: If installing [Portworx PX-Developer](https://docs.portworx.com/developer/), after configuring an HA etcd across the cluster (run from systemd rather than from container so that Portworx doesn't depend on Docker running), install portworx/px-dev as [standalone OCI runC containers](https://docs.portworx.com/runc/) on each node in order to eliminate circular dependancies between Docker and Portworx. Rather than setting the `$latest_stable` variable per instructions on that page (which returns a PX-Enterprise version), you can supply `portworx/px-dev` instead:

    # sudo docker run --entrypoint /runc-entry-point.sh \
    --rm -i --privileged=true \
    -v /opt/pwx:/opt/pwx -v /etc/pwx:/etc/pwx \
    portworx/px-dev

_Hint_: If installing behind a web proxy, see [documentation/Working with swarmstack behind a web proxy.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Working%20with%20swarmstack%20behind%20a%20web%20proxy.md)

## INSTALLING SWARMSTACK TO AN EXISTING ETCD / PORTWORX / DOCKER SWARM CLUSTER:
Download the git archive below onto a Docker manager node and deploy swarmstack services as a Docker stack using the docker-compose.yml file:

    # git clone https://github.com/swarmstack/swarmstack.git

    # ADMIN_USER=admin ADMIN_PASSWORD=admin \
    PUSH_USER=pushuser PUSH_PASSWORD=pushpass \
    docker stack deploy -c docker-compose.yml mon

Or just take most of the defaults above:

    # ADMIN_PASSWORD=somepassword docker stack deploy -c docker-compose.yml mon

If everything works out you can explore the ports listed lower on this page to access the DevOps tools, which should now be running.

You can add some cron entries to each node to forward dockerd/portworx/etcd metrics into the Pushgateway so that Prometheus can scrape them too (`crontab -e`):

    */1 * * * * curl http://127.0.0.1:9001/metrics > /tmp/portworx.metrics 2>/dev/null && sed '/go_/d' /tmp/portworx.metrics | curl -u pushuser:pushpass --data-binary @- http://127.0.0.1:9091/metrics/job/portworx/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 2 && curl http://127.0.0.1:9323/metrics > /tmp/dockerd.metrics 2>/dev/null && sed '/go_/d' /tmp/dockerd.metrics | curl -u pushuser:pushpass --data-binary @- http://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 4 && curl http://127.0.0.1:2379/metrics > /tmp/etcd.metrics 2>/dev/null && cat /tmp/etcd.metrics | curl -u pushuser:pushpass --data-binary @- http://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

---

### FIREWALL MANAGEMENT USING ANSIBLE:
You should consider using the ansible playbook in the [ansible](https://github.com/swarmstack/swarmstack/blob/master/ansible/README.md) folder to manage the firewalls on your EL7 Docker swarm cluster. For other distributions, see the manual method below for now.

### MANUAL FIREWALL MANAGEMENT:

You'll want to configure a firewall if you need to limit access to the exposed Docker service ports below, and any others your other applications bring. Generally speaking this means allowing access to specific IPs and then to no others by modifying the DOCKER-USER iptables chain. This is because routing for exposed Docker service ports happens through the kernel FORWARD chain. firewalld or iptables (recommended: `yum remove firewalld; yum install iptables iptables-services`) can be used to program the kernel's firewall chains:

    # iptables -F DOCKER-USER  # blank out the DOCKER-USER chain
    # iptables -A DOCKER-USER -s 10.0.138.1/32 -p tcp -m tcp --dport 3000 -j ACCEPT  # allow Grafana from 1 IP
    # iptables -A DOCKER-USER -p tcp -m tcp --dport 3000 -j DROP  # block all others

_The default action of the chain should just return, so that the FORWARD chain can continue into the other forwarding chains that Docker maintains :_

    iptables -A DOCKER-USER -j RETURN

You'll need to similarly protect each node in the swarm, as Docker swarm will accept traffic to service ports on all nodes and forward to the correct node.

## DOCKER NODE DISK CLEANUP
You'll also want to add something to each host to keep the local filesystem clear of unneeded containers, local volumes, and images:

    sudo cat <<EOF >>/etc/cron.daily/clean-docker
    #!/bin/bash

    /bin/docker container prune -f > /dev/null 2>&1
    sleep 10
    /bin/docker volume prune -f > /dev/null 2>&1
    sleep 10
    /bin/docker image prune -a -f > /dev/null 2>&1
    EOF
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
Firewall management | iptables                 | ansible->/etc/swarmstack_fw
caddy reverse proxy	| 3000,9090-9091,9093-9095 | stefanprodan/caddy:latest

---

Telemetry: | | | 
--------- | - | -
cAdvisor      | mon_net:8080/metrics | google/cadvisor
Etcd3         | 2379:/metrics        | ansible->git clone coreos/etcdv3.3.9
Node-exporter | mon_net:9100/metrics | stefanprodan/swarmprom-node-exporter:v0.15.2
Pushgateway   | 9091:/metrics        | prom/pushgateway

---

## Metrics Dashboards

![Host](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen1.png)

![Host](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen3.png)

![Host](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen4.png)

![Host](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen6.png)

![Host](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen7.png)

![Host](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen8.png)

# (please ignore everything below for now, but this is what's coming):

## Features a collection of ansible playbooks and a docker-compose stack that:
- Tunes EL7 sysctls for optimal network performance
- Optionally brings up HA etcd cluster (used by Portworx for cluster metadata)
- Optionally brings up HA Portworx PX-Dev storage cluster (used to replicate persistent container volumes across Docker nodes)
- Optionally brings up a 3+ node docker swarm cluster
- Deploys and configures a turn-key HA DevOps Docker swarm stack, based on Prometheus and various exporters, Alertmanager, Grafana and Grafana dashboards
- Automatically prunes unused Docker containers / volumes / images from nodes

---

## REQUIREMENTS:

3 or more Enterprise Linux 7 (RHEL/CentOS) hosts _(baremetal / VM or a combination)_, with each contributing (1) or more additional virtual or physical _unused_ block devices to the storage cluster. _More devices = better performance_.

 With [Portworx PX-Developer](https://github.com/portworx/px-dev) version we'll install a storage cluster for each set of (3) hosts added to the cluster, which will provide up to _1TB_ of persistent storage for up to _40_ volumes across those 3 nodes. When deploying more than 3 nodes in the Docker swarm, you'll use constraints and node tags within your Docker services to pin them to one particular grouping of 3 hosts within the larger cluster _(e.g. nodes 1 2 3, nodes 4 5 6,  etc)_. Containers not needing persistent storage can be scheduled across the entire cluster. Only a subset of your application containers will likely require persistent storage. 
 
 When using [Portworx PX-Enterprise](https://portworx.com/) or bringing another storage solution, these limitations may no longer apply and the storage can be made available simultaneously to a number of nodes across the swarm cluster.

 ---
 
## CLUSTER INSTALLATION: (not yet available)
    # git clone https://github.com/swarmstack/swarmstack.git

Edit these files: | |
---- | - |
clusters/swarmstack-dev | _(defines the nodes and IP addresses of the cluster)_ |
roles/files/etc/swarmstack_fw/rules/firewall.rules | _(used to permit traffic to the hosts themselves)_ |
roles/files/etc/swarmstack_fw/rules/docker.rules | _(used to limit access to Docker service ports)_ |
```
# ansible-playbook -i clusters/swarmstack-dev playbooks/docker.html -k
```
* optional, use this if you haven't already brought up a Docker swarm
```
# ansible-playbook -i clusters/swarmstack-dev playbooks/firewall.html -k`
```
* you can run and re-run this playbook to manage firewalls on all Docker swarm nodes
```
# ansible-playbook -i clusters/swarmstack-dev playbooks/portworx.html -k
```
* optional, if bringing your own persistent storage be sure to update the pxd driver in docker-compose.yml
```
# ansible-playbook -i clusters/swarmstack-dev playbooks/swarmstack.html -k
```
* deploy or redeploy the swarmstack DevOps monitoring stack to the cluster
