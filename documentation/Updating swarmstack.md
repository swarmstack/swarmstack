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
    # docker volume rm swarmstack_grafana

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
