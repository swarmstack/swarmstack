## ADD YOUR APPLICATION CONTAINERS AND MONITOR THEM

One way to push metrics into Prometheus is by using the externally exposed Pushgateway on port 9091 of any Docker swarm node. This would allow you to run a simple container on any docker node in the fleet and publish metrics into Prometheus, or to publish metrics into Prometheus from anywhere really if your firewall is configured to expose port 9091 to other hosts outside the swarm.

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
