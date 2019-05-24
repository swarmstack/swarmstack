#!/bin/bash

#  This script runs on all manager nodes in a swarm and reports service replication levels - finds 0 of X (0/1) containers running
#
#  An alert within Prometheus alerts when this condition exists for over 10 minutes


> /tmp/monitor_swarm_services.tmp
> /tmp/monitor_swarm_services.tmp2

output=$(/bin/docker service ls --format "{{.Replicas}} {{.Name}} {{.Image}}")

if [ "$?" == "0" ]; then

  echo "${output}" > /tmp/monitor_swarm_services.tmp
  hostname=$(hostname -a)
  pushcreds=$(cat /etc/pushgateway.credentials)
  pushgateway=$(cat /etc/pushgateway)

  echo "# HELP swarm_monitor number of running replicas" >> /tmp/monitor_swarm_services.tmp2
  echo "# TYPE swarm_monitor gauge" >> /tmp/monitor_swarm_services.tmp2
  echo "# HELP swarm_desired number of desired replicas" >> /tmp/monitor_swarm_services.tmp2
  echo "# TYPE swarm_desired gauge" >> /tmp/monitor_swarm_services.tmp2

  while IFS='' read -r line || [[ -n "$line" ]]; do

    #1/1 swarmstack_caddy swarmstack/caddy:no-stats-1.0.0
    #6/6 swarmstack_cadvisor google/cadvisor:v0.33.0
    #6/6 swarmstack_portainer-agent portainer/agent:1.2.1
    #1/1 swarmstack_prometheus prom/prometheus:v2.9.2

    replicas=$( echo ${line} | cut -f 1 -d ' ' | cut -f 1 -d '/')
    desired=$( echo ${line} | cut -f 1 -d ' ' | cut -f 2 -d '/')
    servicename=$( echo ${line} | cut -f 2 -d ' ' | sed -e 's/[^a-zA-Z0-9_]/_/g')
    imagename=$( echo ${line} | cut -f 3 -d ' ')

    echo "swarm_monitor{node=\"${hostname}\",service=\"${servicename}\",image=\"${imagename}\",desired=\"${desired}\"} ${replicas}" >> /tmp/monitor_swarm_services.tmp2

    echo "swarm_desired{node=\"${hostname}\",service=\"${servicename}\",image=\"${imagename}\",replicas=\"${replicas}\"} ${desired}" >> /tmp/monitor_swarm_services.tmp2

  done < /tmp/monitor_swarm_services.tmp

  cat /tmp/monitor_swarm_services.tmp2 | curl -k -u ${pushcreds} --data-binary @- https://{$pushgateway}:9091/metrics/job/swarm/instance/${hostname} #>/dev/null 2>&1

fi
