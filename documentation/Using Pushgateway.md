## USING THE PROMETHEUS PUSHGATEWAY

Here's one example of using cron entries on each node to forward dockerd/portworx/etcd metrics into the Pushgateway so that Prometheus can scrape them. This isn't actually needed as swarmstack configures Prometheus to talk directly to the hosts in your swarm, this is only being provided as working examples with real metrics and one way to retrieve your own ephemeral/batch metrics and push them into Prometheus via the Pushgateway:

    */1 * * * * curl http://127.0.0.1:9001/metrics > /tmp/portworx.metrics 2>/dev/null && sed '/go_/d' /tmp/portworx.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/portworx/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 2 && curl http://127.0.0.1:9323/metrics > /tmp/dockerd.metrics 2>/dev/null && sed '/go_/d' /tmp/dockerd.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

    */1 * * * * sleep 4 && curl http://127.0.0.1:2379/metrics > /tmp/etcd.metrics 2>/dev/null && cat /tmp/etcd.metrics | curl -k -u pushuser:pushpass --data-binary @- https://127.0.0.1:9091/metrics/job/dockerd/instance/`hostname -a` >/dev/null 2>&1

