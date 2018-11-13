# ansible playbooks for swarmstack

Please note that the ansible playbooks in this folder only support EL7 (RHEL/CentOS) target hosts. It will mask off firewalld if present and install iptables to manage kernel iptables chains. 

Be sure to 'yum update kernel' and reboot this node first if the node you are running the ansible playbooks from needs kernel updates and will run the _playbooks/docker.yml_ playbook, as it may reboot this host and would not be able to continue with running the ansible playbooks.

From any host on your network that can route to your Docker hosts, including any of the eventual manager hosts of your Docker swarm:

```
# yum install epel-release
# yum install ansible
# yum install git
# cd /usr/local/src
# git clone https://github.com/swarmstack/swarmstack.git
# rsync -aq swarmstack/ localswarmstack/
# cd localswarmstack/
```

Edit these files in the swarmstack/ansible folder: 

* ansible/clusters/swarmstack _(define the nodes in your cluster)_

* ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/firewall.rules _(used to permit traffic via the INPUT chain)_

* ansible/roles/swarmstack/files/etc/swarmstack_fw/rules/docker.rules _(used to limit access to Docker services via the FORWARD chain)_

Afterwards you can run the playbook below against your entire cluster, and re-run it any time you need to make firewall changes:

```
# cd ansible; ansible-playbook -i clusters/swarmstack \
 playbooks/firewall.yml -k

```
Or apply changes to particular hosts in the cluster using regex patterns supported by ansible's -l (limit) option:
```
# cd ansible; ansible-playbook -i clusters/swarmstack \
 playbooks/firewall.yml -k -l host[12].exampl*
```

You can create and manage separate clusters by cloning the existing swarmstack cluster and files:
```
# cp ansible/clusters/swarmstack ansible/clusters/cluster2
# rsync -aq ansible/roles/swarmstack/ ansible/roles/cluster2
```

### The remaining playbooks in the playbooks/ directory work similarly. Please see the main swarmstack README.md for usage instructions.
