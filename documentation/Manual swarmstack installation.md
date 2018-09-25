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

_If installing behind a web proxy, see [documentation/Working with swarmstack behind a web proxy.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Working%20with%20swarmstack%20behind%20a%20web%20proxy.md)_

_For documentation on using LDAP for authentication with swarmstack, see [documentation/Using LDAP.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Using%20LDAP.md)_

_Instructions for updating swarmstack are available at [documentation/Updating swarmstack.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Updating%20swarmstack.md)_

_To deploy and monitor your own applications on the cluster, see [documentation/Adding your own applications to monitoring.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Adding%20your%20own%20applications%20to%20monitoring.md)

-To manually push ephemeral or batch metrics into Prometheus, see [documentation/Using Pushgateway.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Using%20Pushgateway.md)

_Some basic commands for working with swarmstack and Portworx storage are noted in [documentation/Notes.md](https://github.com/swarmstack/swarmstack/blob/master/documentation/Notes.md)

---

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

## FIREWALL MANAGEMENT USING ANSIBLE:
You should consider using the ansible playbook in the [ansible](https://github.com/swarmstack/swarmstack/blob/master/ansible/README.md) folder to manage the firewalls on your EL7 Docker swarm cluster. For other distributions, see the manual method below for now.

## MANUAL FIREWALL MANAGEMENT:

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
