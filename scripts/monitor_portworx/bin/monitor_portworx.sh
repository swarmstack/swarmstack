#!/bin/sh

# Monitor your Portworx volumes and alert when consuming too many volumes.
# Includes snapshots, whereas px_volume_* does not. Value is calculated as the percent of volume filled.
# "pxctl volume list --all" (-j) doesn't indicate usage within snapshots, so "pxctl volume inspect" is used.

# Example Prometheus data:
#
# px_monitor{node="dev-swarm01",clusterid="RED",clusteruuid="f9077725-9b7a-4d72-aece-f040fa64a3bc",created="2019-05-24T00:10:07Z",ha_level="2",format="ext4",state="detached",block_size="4096",cos="low",size="6442450944",usage="0",volume_name="swarmstack_grafana",volumefill="1732608",parent=""} 0.03

pxclusterid=$(/usr/local/bin/pxctl status | egrep "Cluster ID:" | awk '{print $NF}')
pxclusteruuid=$(/usr/local/bin/pxctl status | egrep "Cluster UUID:" | awk '{print $NF}')

> /tmp/monitor_portworx.tmp
> /tmp/monitor_portworx.tmp2

output=$(/usr/local/bin/pxctl volume list --all -j |  jq -r '.[] | "created=\"\(.ctime)\",ha_level=\"\(.spec.ha_level)\",format=\"\(.format)\",state=\"\(.state)\",block_size=\"\(.spec.block_size)\",cos=\"\(.spec.cos)\",size=\"\(.spec.size)\",usage=\"\(.usage)\",volume_name=\"\(.locator.name)\",parent=\"\(.source.parent)\""')

if [ "$?" == "0" ]; then

  echo "${output}" > /tmp/monitor_portworx.tmp
  hostname=$(hostname -a)
  pushcreds=$(cat /etc/pushgateway.credentials)
  pushgateway=$(cat /etc/pushgateway)

  echo "# HELP px_monitor volume" >> /tmp/monitor_portworx.tmp2
  echo "# TYPE px_monitor gauge" >> /tmp/monitor_portworx.tmp2

  while IFS='' read -r line || [[ -n "$line" ]]; do

    #created="2019-03-12T06:07:19Z",ha_level="2",format="ext4",state="attached",block_size="4096",cos="low",size="21474836480",usage="474279936",volume_name="dna_backups1"

    volumefill=$(/usr/local/bin/pxctl volume inspect -j `echo "${line}" | cut -f 18 -d '"'` | jq '.[].usage' | cut -f 2 -d '"')
    volumesize=$(echo "${line}" | cut -f 14 -d '"')
    volumeusage=$(printf "%.2f\n" `echo "(100 / ${volumesize}) * ${volumefill}" | bc -l`)

    echo "px_monitor{node=\"${hostname}\",clusterid=\"${pxclusterid}\",clusteruuid=\"${pxclusteruuid}\",${line},volumefill=\"${volumefill}\"} ${volumeusage}" >> /tmp/monitor_portworx.tmp2

  done < /tmp/monitor_portworx.tmp

  cat /tmp/monitor_portworx.tmp2 | curl -k -u ${pushcreds} --data-binary @- https://{$pushgateway}:9091/metrics/job/swarm/instance/${hostname} #>/dev/null 2>&1

fi


