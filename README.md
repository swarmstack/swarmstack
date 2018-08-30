# swarmstack
## HA Docker swarm / Prometheus / Alertmanager / Grafana DevOps stack for running containerized applications, with optional persistent storage, firewall management, and high-availability features 

Easily deploy and update Docker swarm nodes as you scale up from at least (3) baremetal servers, ec2 instances, or virtual machines, which will host and monitor your highly-available containerized applications using a modern DevOps workflow and toolset.

Manage one or more Docker clusters via ansible playbooks that can _(optionally)_ help you install Docker swarm, [Portworx](https://portworx.com) persistent storage for container volumes between Docker swarm nodes, and update firewall rules between the nodes as well as Docker service ports exposed by your applications.

swarmstack includes a modern DevOps stack of tools for operating Docker swarms, including monitoring and alerting of the cluster health itself as well as the health of your own applications. Swarmstack installs and updates [Prometheus](https://github.com/prometheus/prometheus/blob/master/README.md) + [Grafana](https://grafana.com) + [Alertmanager](https://github.com/prometheus/alertmanager/blob/master/README.md). Provides an optional automatic installation of [Portworx](https://portworx.com) for persistent storage for containers such as databases that need storage that can move to another Docker swarm node instantly, or bring your own persistent storage layer for Docker (e.g. [RexRay](https://github.com/rexray/rexray), or local volumes and add placement constraints to docker-compose.yml) 

The built-in Grafana dashboards will help you stay aware of the health of the cluster, and the same metrics pipeline can easily be used by your own applications and visualized in Grafana and/or alerted upon via Prometheus rules and sent to redundant Alertmanagers to perform slack/email/etc notifications. Prometheus can optionally replicate metrics stored within it's internal own time-series database (tsdb) out to one or more external tsdb such as InfluxDB for analysis or longer-term storage, or to cloud services such as [Weave Cloud](https://www.weave.works/product/cloud/) or the like. 

For an overview of the flow of metrics into Prometheus, exploring metrics using the meager PromQL interface Prometheus provides, and ultimately using Grafana and other visualizers to create dashboards while using the Prometheus time-series database as a datasource, watch [Monitoring, the Prometheus way](https://www.youtube.com/watch?v=PDxcEzu62jk), and take a look at [Prometheus: Monitoring at SoundCloud](https://developers.soundcloud.com/blog/prometheus-monitoring-at-soundcloud)

![](https://developers.soundcloud.com/assets/posts/prometheus_architecture-4b9254066c366c0a3f2b96d20730a4e3.svg "Prometheus architecture")

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

## THIS IS A WORK-IN-PROGRESS (WIP) - Full ansible release soon

Currently the firewall management ansible playbook and the Docker DevOps tool stack has been released. While you wait for the full ansible playbook release that will install the cluster for you including etcd, Portworx, and Docker swarm, feel free to get a head-start by installing the DevOps stack itself - borrowed heavily from [stefanprodan/swarmprom](https://github.com/stefanprodan/swarmprom). You'll need to bring some kit of your own at the moment, namely install a 3-node cluster of physical or virtual machines or ec2 instances, each running Docker configured as a swarm with 1 or more managers, plus [etcd](https://docs.portworx.com/maintain/etcd.html) and [Portworx PX-Developer](https://docs.portworx.com/developer/) or PX-Enterprise _(or change pxd in docker-compose.yml to your persistent storage layer of choice)_. The instuctions below were tested on EL7 (RHEL/CentOS), but can be adapted to your linux distribution of choice. The inital release of ansible installation playbooks will focus on EL7, but support for CoreOS and ubuntu hosts will be added over time to the same playbooks.

Before proceeding, make sure your hosts have their time in sync via NTP

_Hint_: While you can follow the instructions at [Portworx PX-Developer](https://docs.portworx.com/developer/) to try out Portworx using Docker containers, you should consider instead installing Portworx as a standalone [OCI runC container](https://docs.portworx.com/runc/) on each node in order to eliminate circular dependancies between Docker and Portworx. You can follow the instructions on the runC page to install a 30 day trial of PX-Enterprise running their latest code (which cannot later be downgraded to PX-Developer), or you can replace the `$latest_stable` variable and instead supply `portworx/px-dev` to install the Portworx developer OCI files and license:

    # docker run --entrypoint /runc-entry-point.sh \
    --rm -i --privileged=true \
    -v /opt/pwx:/opt/pwx -v /etc/pwx:/etc/pwx \
    portworx/px-dev

_Hint_: If installing behind a web proxy, see [documentation/Working with swarmstack behind a web proxy.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Working%20with%20swarmstack%20behind%20a%20web%20proxy.md)

## INSTALL OR UPDATE SWARMSTACK ON AN EXISTING ETCD / PORTWORX / DOCKER SWARM CLUSTER:
Download the git archive below onto a Docker manager node and deploy swarmstack as a Docker stack using the docker-compose.yml file:

    # cd /usr/local/src
    # git clone https://github.com/swarmstack/swarmstack.git

    # ADMIN_USER=admin ADMIN_PASSWORD=admin \
    PUSH_USER=pushuser PUSH_PASSWORD=pushpass \
    docker stack deploy -c swarmstack/docker-compose.yml swarmstack

Or just take most of the defaults above:

    # ADMIN_PASSWORD=somepassword docker stack deploy -c swarmstack/docker-compose.yml swarmstack

If everything works out you can explore the ports listed lower on this page to access the DevOps tools, which should now be running.

### UPDATING SWARMSTACK

    # docker stack rm swarmstack
    # cd /usr/local/src/swarmstack
    # git pull https://github.com/swarmstack/swarmstack.git

And then deploy the stack again as above. Persistent volumes, or containers you've created local volumes and placement constraints for, will be reattached as the newest containers are deployed and should pick up right where they left off. If you wish to initialize (lose all data) one or more swarmstack services (such as Prometheus or Swarmpit's CouchDB), before re-deploying the stack:

    # docker volume rm swarmstack_prometheus
    # docker volume rm swarmstack_swarmpit-couchdb

### CRON JOBS

You can add some cron entries to each node to forward dockerd/portworx/etcd metrics into the Pushgateway so that Prometheus can scrape them too (`crontab -e`):

    */1 * * * * curl http://127.0.0.1:9001/metrics > /tmp/portworx.metrics 2>/dev/null && sed '/go_/d' /tmp/portworx.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/portworx/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 2 && curl http://127.0.0.1:9323/metrics > /tmp/dockerd.metrics 2>/dev/null && sed '/go_/d' /tmp/dockerd.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 4 && curl http://127.0.0.1:2379/metrics > /tmp/etcd.metrics 2>/dev/null && cat /tmp/etcd.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

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

### DOCKER NODE DISK CLEANUP
You'll also want to add something to each host to keep the local filesystem clear of unneeded containers, local volumes, and images:

    # cat <<EOF >>/etc/cron.daily/clean-docker
    #!/bin/bash

    /bin/docker container prune -f > /dev/null 2>&1
    sleep 10
    /bin/docker volume prune -f > /dev/null 2>&1
    sleep 10
    /bin/docker image prune -a -f > /dev/null 2>&1
    EOF
---

## NETWORK URLs:

Connect to https://swarmhost of any Docker swarm node and authenticate with your ADMIN_PASSWORD to view these links:

DevOps Tools:     | Port(s):                  | Current Distribution / Installation
---------------- | -------------------------- | ---------------
[Alertmanager](https://github.com/prometheus/alertmanager) | https://swarmhost:9093<br>_caddy:swarmstack_net:alertmanager:9093_ | prom/alertmanager:latest
AlertmanagerB    | https://swarmhost:9095<br>_caddy:swarmstack_net:alertmanagerB:9093_ | prom/alertmanager:latest
[Grafana](https://github.com/grafana/grafana) | https://swarmhost:3000<br>_caddy:swarmstack_net:grafana:3000_ | grafana/grafana:latest
[Prometheus](https://github.com/prometheus/prometheus) | https://swarmhost:9090<br>_caddy:swarmstack_net:prometheus:9090_ | prom/prometheus:latest
[Pushgateway](https:/github.com/prometheus/pushgateway) | https://swarmhost:9091<br>_caddy:swarmstack_net:pushgateway:9091_ | prom/pushgateway:latest
[Swarmpit](https://github.com/swarmpit/swarmpit) | https://swarmhost:9092<br>_caddy:swarmstack_net:swarmpit:8080_ | swarmpit/swarmpit:latest
[Unsee](https://github.com/cloudflare/unsee) | https://swarmhost:9094<br>_caddy:swarmstack_net:unsee:8080_ | cloudflare/unsee:v0.9.2

---

Security: | | |
--------- | - | -
Firewall management | iptables | ansible->/etc/swarmstack_fw
[caddy](https://hub.docker.com/r/stefanprodan/caddy/) | 80->443, 3000, 9090-9095 | stefanprodan/caddy:latest

Telemetry: | | |
--------- | - | -
[cAdvisor](https://github.com/google/cadvisor) | _swarmstack_net:http://cadvisor:8080/metrics_ | google/cadvisor:latest
[CouchDB](https://hub.docker.com/_/couchdb/) | _swarmstack_net:couchdb:5984_ | couchdb:latest
[Docker](https://docs.docker.com/engine/swarm/) | http://swarmhost:9323/metrics | ansible->yum docker
[etcd3](https://github.com/etcd-io/etcd) | http://swarmhost:2379/metrics | ansible->git clone coreos/etcdv3.3.9
[Grafana](https://github.com/grafana/grafana) | _swarmstack_net:http://grafana:3000/metrics_ | grafana/grafana:latest
[Node-exporter](https://github.com/stefanprodan/swarmprom) | _swarmstack_net:http://node-exporter:9100/metrics_ | stefanprodan/swarmprom-node-exporter:v0.15.2
[Portworx](https://portworx.com) | http://swarmhost:9001:/metrics | ansible->portworx/px-dev
[Prometheus](https://github.com/prometheus/prometheus) | _swarmstack_net:http://prometheus:9090/metrics_ | prom/prometheus
[Pushgateway](https://github.com/prometheus/pushgateway) | https://swarmhost:9091/metrics<br>_swarmstack_net:http://pushgateway:9091/metrics_ | prom/pushgateway

---

## Metrics Dashboards

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen1.png)

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen3.png)

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen4.png)

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen6.png)

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen7.png)

![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen8.png)

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
 
## ANSIBLE CLUSTER INSTALLATION: (not yet available)
    # cd /usr/local/src
    # git clone https://github.com/swarmstack/swarmstack.git

Edit these files: | |
---- | - |
clusters/swarmstack | _(defines the nodes and IP addresses of the cluster)_ |
roles/files/etc/swarmstack_fw/rules/firewall.rules | _(used to permit traffic to the hosts themselves)_ |
roles/files/etc/swarmstack_fw/rules/docker.rules | _(used to limit access to Docker service ports)_ |
```
# ansible-playbook -i clusters/swarmstack playbooks/docker.yml -k
```
* optional, use this if you haven't already brought up a Docker swarm
```
# ansible-playbook -i clusters/swarmstack playbooks/firewall.yml -k
```
* you can run and re-run this playbook to manage firewalls on all Docker swarm nodes
```
# ansible-playbook -i clusters/swarmstack playbooks/portworx.yml -k
```
* optional, if you are instead bringing your own persistent storage be sure to update the pxd driver in docker-compose.yml
```
# ansible-playbook -i clusters/swarmstack playbooks/swarmstack.yml -k
```
* deploy or redeploy the swarmstack DevOps monitoring stack to the cluster
