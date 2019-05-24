Monitor your swarm services and alert when 0 replicas are running for 10 minutes:

## EXAMPLE PROMETHEUS DATA
```
swarm_monitor{node="dev-swarm01",service="swarmstack_cadvisor",image="google/cadvisor:v0.33.0",desired="6"} 6
swarm_desired{node="dev-swarm01",service="swarmstack_cadvisor",image="google/cadvisor:v0.33.0",replicas="6"} 6
```

## INSTALLATION

On all of your Docker swarm MANAGER nodes (not on worker nodes):

```
cp bin/monitor_swarm_services.sh /usr/local/bin/
cp etc/push* /etc/
```

Edit /etc/pushgatway and /etc/pushgateway.credentials to specify your Prometheus Pushgateway info

Add prometheus/rules/containers.yml content to your existing Prometheus rules

Add the script to run from root (or docker-capable user) crontab every minute:

```
crontab -e

* * * * *  /usr/local/bin/monitor_swarm_services.sh >/dev/null 2>&1
```

---

The optional grafana/panels/services-without-desited-containers panel JSON can be added to an existing Grafana dashboard
