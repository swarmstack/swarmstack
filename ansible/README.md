# ansible playbooks for swarmstack

### Please note that the ansible playbooks in this folder are WORK-IN-PROGRESS. Currently the firewall playbook is available and supports only EL7 (RHEL/CentOS) targets at the present time. It will remove firewalld if present and install iptables to manage kernel iptables chains.

From any host on your network that can route to your Docker hosts, including any of the hosts in your Docker swarm:

```
# yum install epel-release
# yum install ansible
# yum install git
# cd /usr/local/src
# git clone https://github.com/swarmstack/swarmstack.git

```

Edit these files in the swarmstack/ansible folder: 

* ansible/clusters/swarmstack-dev _(define the nodes in your cluster)_

* ansible/roles/swarmstack-dev/files/etc/swarmstack_fw/rules/firewall.rules _(used to permit traffic via the hosts INPUT chain)_

* ansible/roles/swarmstack-dev/files/etc/swarmstack_fw/rules/docker.rules _(used to limit access to Docker service ports)_

Afterwards you can run the playbook below against your entire cluster, and re-run it any time you need to make firewall changes:

```
# cd ansible; ansible-playbook -i clusters/swarmstack-dev \
 playbooks/firewall.yml -k

```
Or apply changes to particular hosts in the cluster using regex patterns supported by ansible's -l (limit) option:
```
# cd ansible; ansible-playbook -i clusters/swarmstack-dev \
 playbooks/firewall.yml -k -l host[12].exampl*
```

You can create and manage separate clusters by cloning the existing swarmstack-dev cluster's files:
```
# cp ansible/clusters/swarmstack-dev ansible/clusters/another-cluster
# rsync -aq ansible/roles/swarmstack-dev/ ansible/roles/another-cluster
```
