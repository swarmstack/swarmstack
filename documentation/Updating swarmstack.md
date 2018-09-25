## MANUAL SWARMSTACK INSTALLATION
Manual installation of the Docker cluster and swarmstack is documented below.

You'll need to bring your own 3+ node cluster of physical or virtual machines or ec2 instances, each running Docker configured as a swarm with 1 or more managers, plus [etcd](https://docs.portworx.com/maintain/etcd.html) and [Portworx PX-Developer](https://docs.portworx.com/developer/) or PX-Enterprise _(or change pxd in _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_ to your persistent storage layer of choice)_. The instuctions below were tested on EL7 (RHEL/CentOS), but can be adapted to your linux distribution of choice. The inital release of ansible installation playbooks will focus on EL7, but support for CoreOS and ubuntu hosts will be added over time to the same playbooks.

Before proceeding, make sure your hosts have their time in sync via NTP

_Hint_: While you can follow the instructions at [Portworx PX-Developer](https://docs.portworx.com/developer/) to try out Portworx using Docker containers, you should consider instead installing Portworx as a standalone [OCI runC container](https://docs.portworx.com/runc/) on each node in order to eliminate circular dependancies between Docker and Portworx. You can follow the instructions on the runC page to install a 30 day trial of PX-Enterprise running their latest code (which cannot later be downgraded to PX-Developer), or you can replace the `$latest_stable` variable and instead supply `portworx/px-dev` to install the Portworx developer OCI files and license:

    # docker run --entrypoint /runc-entry-point.sh \
    --rm -i --privileged=true \
    -v /opt/pwx:/opt/pwx -v /etc/pwx:/etc/pwx \
    portworx/px-dev


## INSTALL OR UPDATE SWARMSTACK ON AN EXISTING ETCD / PORTWORX / DOCKER SWARM CLUSTER:
Download the git archive below onto a Docker manager node and deploy swarmstack as a Docker stack using the _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_ file:

    # cd /usr/local/src
    # git clone https://github.com/swarmstack/swarmstack.git
    # rsync -aq --exclude=.git swarmstack/ localswarmstack/
    $ cd localswarmstack

    # ADMIN_USER=admin ADMIN_PASSWORD=admin \
    PUSH_USER=pushuser PUSH_PASSWORD=pushpass \
    docker stack deploy -c docker-compose.yml swarmstack

Or just take most of the defaults above:

    # ADMIN_PASSWORD=somepassword docker stack deploy -c docker-compose.yml swarmstack

If everything works out you can explore the ports listed in the main [README.md](https://github.com/swarmstack/swarmstack/blob/master/README.md)

_Hint_: If installing behind a web proxy, see [documentation/Working with swarmstack behind a web proxy.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Working%20with%20swarmstack%20behind%20a%20web%20proxy.md)

_Hint_: For documentation on using LDAP for authentication with swarmstack, see [documentation/Using LDAP.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Using%20LDAP.md)

## UPDATING SWARMSTACK

    # docker stack rm swarmstack
    # cd /usr/local/src/swarmstack
    # git pull https://github.com/swarmstack/swarmstack.git

You can diff and see what changed and move the changes into your own /usr/local/src/localswarmstack directory, or just move aside your old localswarmstack directory where you've made any changes and re-rsync as above:

    # rsync -aq --exclude=.git swarmstack/ localswarmstack/
    $ cd localswarmstack

And then deploy the stack again as above. Persistent volumes, or containers you've created local volumes and placement constraints for, will be reattached as the newest containers are deployed and should pick up right where they left off. If you wish to initialize (lose all data) one or more swarmstack services (such as Prometheus or Swarmpit's CouchDB), before re-deploying the stack:

    # docker volume rm swarmstack_prometheus
    # docker volume rm swarmstack_swarmpit-couchdb

### CRON JOBS

You can add some cron entries to each node to forward dockerd/portworx/etcd metrics into the Pushgateway so that Prometheus can scrape them too (`crontab -e`):

    */1 * * * * curl http://127.0.0.1:9001/metrics > /tmp/portworx.metrics 2>/dev/null && sed '/go_/d' /tmp/portworx.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/portworx/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 2 && curl http://127.0.0.1:9323/metrics > /tmp/dockerd.metrics 2>/dev/null && sed '/go_/d' /tmp/dockerd.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 4 && curl http://127.0.0.1:2379/metrics > /tmp/etcd.metrics 2>/dev/null && cat /tmp/etcd.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

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

## ADD YOUR APPLICATION CONTAINERS AND MONITOR THEM

You can see from the section CRON JOBS (above) one way to push metrics into Prometheus, using the externally exposed Pushgateway on port 9091 of any Docker swarm node. This would allow you to run a simple container on any docker node in the fleet and publish metrics into Prometheus, or to publish metrics into Prometheus from anywhere really if your firewall is configured to expose port 9091 to other hosts outside the swarm.

However, it's better if your application can be made to serve it's metrics directly on a non-exposed port (e.g. 9080:/metrics) with access to the _swarmstack_net_ (you can also add _swarmstack_net_ as an additional network to your service if needed). If your container application can already serve HTTP or HTTPS, you can either have it serve it's metrics at it's own port:/metrics, or via a second port altogether. In some cases you might even need to create a helper container that has access in some way to the stats of another application container or data-source and can publish them in Prometheus format, Prometheus calls this an "exporter". You can deploy your containers as services, or preferably as a stack of services (so that they can be started and stopped together), and add the external _swarmstack_net_ network to your service so that Prometheus can scrape it directly:

```
# docker service create \
--replicas 3 \
--network swarmstack_net \
--name my-web \
nginx
```
or better, as a Docker stack (see _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_, also [Use a pre-existing network](https://docs.docker.com/compose/networking/#configure-the-default-network)):

```
    networks:
      default:
        external:
          name: swarmstack_net
```
You'll need to add a scrape config to prometheus/conf/prometheus.yml:
```
  - job_name: 'myapp'
    dns_sd_configs:
    - names:
      - 'tasks.myapp'
      type: 'A'
      port: 9080
```
### USE CADDY TO HANDLE HTTP/S FOR YOUR SERVICES
While your own applications can expose HTTP/S directly on swarm node ports if needed, you could also instead choose to configure Caddy to proxy your HTTP/S traffic to your application, and optionally handle automatic HTTPS certificates and/or basic authentication for you. Your application's security may be enhanced by adding the indirection, and adding HTTPS to a non-HTTPS application becomes a breeze. To accomplish this, after adding the _swarmstack_net_ network to your service you can update the swarmstack _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_ to expose your own application port via Caddy, and proxy the traffic to your service listening on a non-exposed port within the _swarmstack_net_:
```
  caddy:
    image: swarmstack/caddy:no-stats
    ports:
      - "9080:9080"
```
Then update caddy/Caddyfile to terminate HTTPS traffic and reverse proxy it to your service ports. You can choose to use either a self_signed certificate (default, stored in-memory within Caddy and rotated each week) and accept the occasional browser warnings, or see [Automatic HTTPS](https://caddyserver.com/docs/automatic-https) within Caddy documentation for various ways to have Caddy automatically create signed certificates, or bring your own certificatess (you'll need to vi/copy/curl them directly into a running Caddy container into it's _/etc/caddycerts/_ folder). All certificates will be stored in a persistent container volume and used for the named host in caddy/Caddyfile the next time swarmstack is redeployed.

Caddy has a featured called On-Demand TLS, where it can register a free Let's Encrypt account for you and can manage the generation and update of CA-signed certificates automatically. You can then remove the (2) stanzas :80 and :443 in _caddy/Caddyfile_, and replace with just:
```
*.example.com {
    tls email@example.com
    tls {
      max_certs 10
    }
    basicauth / {$ADMIN_USER} {$ADMIN_PASSWORD}
    root /www
}
```
From [Caddy - Automatic HTTPS](https://caddyserver.com/docs/automatic-https): "Caddy will also redirect all HTTP requests to their HTTPS equivalent if the plaintext variant of the hostname is not defined in the Caddyfile."

## NETWORK URLs:

Connect to https://swarmhost of any Docker swarm node and authenticate with your ADMIN_PASSWORD to view these links:

DevOps Tools:     | Port(s):                  | Current Distribution / Installation
---------------- | -------------------------- | ---------------
[Alertmanager](https://github.com/prometheus/alertmanager) | https://swarmhost:9093<br>_caddy:swarmstack_net:alertmanager:9093_ | prom/alertmanager:latest
AlertmanagerB    | https://swarmhost:9095<br>_caddy:swarmstack_net:alertmanagerB:9093_ | prom/alertmanager:latest
[Grafana](https://github.com/grafana/grafana) | https://swarmhost:3000<br>_caddy:swarmstack_net:grafana:3000_ | grafana/grafana:5.2.4
[Prometheus](https://github.com/prometheus/prometheus) | https://swarmhost:9090<br>_caddy:swarmstack_net:prometheus:9090_ | prom/prometheus:latest
[Pushgateway](https:/github.com/prometheus/pushgateway) | https://swarmhost:9091<br>_caddy:swarmstack_net:pushgateway:9091_ | prom/pushgateway:latest
[Swarmpit](https://github.com/swarmpit/swarmpit) | https://swarmhost:9092<br>_caddy:swarmstack_net:swarmpit:8080_ | swarmpit/swarmpit:latest
[Unsee](https://github.com/cloudflare/unsee) | https://swarmhost:9094<br>_caddy:swarmstack_net:unsee:8080_ | cloudflare/unsee:v0.9.2

---

Security: | | |
--------- | - | -
Firewall management | iptables | ansible->/etc/swarmstack_fw
[Caddy](https://hub.docker.com/r/swarmstack/caddy/) | https://swarmhost (80->443, 3000, 9090-9095) _swarmstack_net:http://caddy:9180/metrics_ | swarmstack/caddy:no-stats

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

### Caddy Link Dashboard:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen1.png)
### Grafana Dashboards List:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen2.png)
### Grafana - Docker Swarm Nodes:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/docker_swarm_nodes.png)
### Grafana - Docker Swarm Services:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/docker_swarm_services.png)
### Grafana - etcd:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/etcd.png)
### Grafana - Portworx Cluster Status:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portworx_cluster_status.png)
### Grafana - Portworx Volume Status:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/portworx_volumes.png)
### Grafana - Prometheus Stats:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus.png)
### Alertmanager:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen9.png)
### Prometheus - Graphs:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/screen10.png)
### Prometheus - Alerts:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus_alerts.png)
### Prometheus - Targets:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/prometheus_targets.png)
### Swarmpit:
![](https://raw.githubusercontent.com/swarmstack/swarmstack/master/documentation/screens/swarmpit.png)

--- 

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
    # cd /usr/local/src/
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
* optional, if you are instead bringing your own persistent storage be sure to update the pxd driver in _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_ 
```
# ansible-playbook -i clusters/swarmstack playbooks/swarmstack.yml -k
```
* deploy or redeploy the swarmstack DevOps monitoring stack to the cluster
