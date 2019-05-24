#!/bin/bash

donotsnap="swarmstack_alertmanager,swarmstack_alertmanagerB,swarmstack_portainer_certs,swarmstack_portainer_data,swarmstack_prometheus,swarmstack_swarm-endpoints"

weekly=Fri

####### NO CHANGES ARE NEEDED BELOW
nonsnaps=$(/usr/local/bin/pxctl volume list | grep -v SNAP-ENABLED | grep -v snapshot_ | awk '{print $2}')
snaps=$(/usr/local/bin/pxctl volume list | grep -v SNAP-ENABLED | grep snapshot_ | awk '{print $2}')
theday=$(date +"%a")
today=$(date --date="today 00:00:00" +"%s")
lastweekly=$(date --date="last ${weekly}" +"%s")

for snapname in ${nonsnaps}; do

  for skipname in $(echo ${donotsnap} | sed "s/,/ /g"); do
    if [ "${skipname}" == "${snapname}" ]; then
       echo "Skipping ${snapname}"
       continue 2
    fi
  done

  # WEEKLY SNAPSHOTS

  # Remove previous weekly snapshots
  oldsnaps=$(echo "${snaps}" | egrep "^snapshot_weekly_[0-9]+_${snapname}$" | egrep -v "^snapshot_weekly_${lastweekly}_${snapname}$")
  for oldsnap in ${oldsnaps}; do
    echo "Removing old weekly snapshot volume ${oldsnap}"
    /usr/local/bin/pxctl volume delete ${oldsnap} -f
  done

  # Create weekly snapshot if it doesn't exist
  if [ "${theday}" == "${weekly}" ]; then
    echo "${snaps}" | egrep "^snapshot_weekly_${today}_${snapname}$" > /dev/null 2>&1
    if [ "$?" == "1" ]; then
      echo "Creating weekly snapshot for volume ${snapname}"
      /usr/local/bin/pxctl volume snapshot create --name snapshot_weekly_${lastweekly}_${snapname} ${snapname}
    fi
  fi

  # DAILY SNAPSHOTS

  # Remove previous daily snapshots
  oldsnaps=$(echo "${snaps}" | egrep "^snapshot_daily_[0-9]+_${snapname}$" | egrep -v "^snapshot_daily_${today}_${snapname}$")
  for oldsnap in ${oldsnaps}; do
    echo "Removing old daily snapshot volume ${oldsnap}"
    /usr/local/bin/pxctl volume delete ${oldsnap} -f
  done

  # Create daily snapshot if it doesn't exist
  echo "${snaps}" | egrep "^snapshot_daily_${today}_${snapname}$" > /dev/null 2>&1
  if [ "$?" == "1" ]; then
    if [ "${theday}" != "${weekly}" ]; then
      echo "Creating daily snapshot for volume ${snapname}"
      /usr/local/bin/pxctl volume snapshot create --name snapshot_daily_${today}_${snapname} ${snapname}
    fi
  fi

done
