Monitor your Portworx volumes and alert when consuming too many, includes snapshots whereas px_volume_* doesn't:

## EXAMPLE PROMETHEUS DATA

```
px_monitor{node="dev-swarm01",clusterid="RED",clusteruuid="f9077725-9b7a-4d72-aece-f040fa64a3bc",created="2019-05-24T00:10:07Z",ha_level="2",format="ext4",state="detached",block_size="4096",cos="low",size="6442450944",usage="0",volume_name="swarmstack_grafana",volumefill="1732608"} 0.03
```

## INSTALLATION

On all of your Docker swarm nodes that run Portworx (possibly all swarm  nodes):

The package 'jq' should be installed so that JSON can be parsed by the script:

```
yum install jq
cp bin/monitor_portworx.sh /usr/local/bin/
cp etc/push* /etc/
```

Edit /etc/pushgatway and /etc/pushgateway.credentials to specify your Prometheus Pushgateway info

Add prometheus/rules/portworx.yml content to your existing Prometheus rules

Add the script to run from root (or docker-capable user) crontab every minute:

```
crontab -e

* * * * *  /usr/local/bin/monitor_portworx.sh >/dev/null 2>&1
```

---

You could also chain other monitors that you want crontab to run every minute to the end of this shell script, so that the additional monitors will run in serial rather than simultaneously every minute via cron (reducing monitoring-induced load on your nodes). For example, at the end of /usr/local/bin/monitor_portworx.sh, add the following line to the shell script on ONLY your Docker swarm MANAGER nodes:

```
/usr/local/bin/monitor_swarm_services.sh
```

---

The optional grafana/panels/portworx-px-dev-volumes panel JSON can be added to an existing Grafana dashboard
