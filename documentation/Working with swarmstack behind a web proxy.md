# Working with swarmstack behind a web proxy

_Hint:_ You may find that varying applications within containers parse their environment variables for proxies using differing names and syntax requirements, such as http_proxy=proxy.example.com:80 or http_proxy=http://proxy.example.com:80. Some applications might look for HTTPS_PROXY instead. Consult application documentation in these cases, and add the appropriate environent variables to the specific services which requires internet access via web proxy. Your web proxy administrator should be able to provide the correct hostname and port to use for HTTP traffic, and perhaps a different host:port for HTTPS traffic. Some web proxies are configured to handle both at the same port.

For Docker to retrieve images from the internet, you'll need to add the following file on each Docker node:

* /etc/systemd/system/docker.service.d/http-proxy.conf

```
[Service]
Environment="http_proxy=proxy.example.com:80"
Environment="https_proxy=proxy.example.com:443"
Environment="no_proxy=.mydomain.com"
```

Then update systemd and restart Docker on each node:

    # systemctl daemon-reload
    # systemctl restart docker

## Caddy

If you want to have Caddy register automatic SSL certificates for you while behind a web proxy, you'll need to add the https_proxy and no_proxy directives to the swarmstack _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_:

```
      - CADDYPATH=/etc/caddycerts
      - https_proxy=https://proxy.example.com:443
      - no_proxy=10.0.0.0/8,.example.com
```
You can then remove the :80 and :443 stanzas in _caddy/Caddyfile_, and replace them with:
```
*.example.com:443 {
    tls email@example.com
    tls {
      max_certs 10
    }
    basicauth / {$ADMIN_USER} {$ADMIN_PASSWORD}
    root /www
}
```
From [Caddy - Automatic HTTPS](https://caddyserver.com/docs/automatic-https): "Caddy will also redirect all HTTP requests to their HTTPS equivalent if the plaintext variant of the hostname is not defined in the Caddyfile."

## Grafana (and other containers)

If you plan to install plugins using internet sources, you'll need add your https_proxy to to containers within the _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_:

```
  grafana:
    image: grafana/grafana:latest
    networks:
      - net
    environment:
      - http_proxy=http://proxy.example.com:80
      - https_proxy=https://proxy.example.com:443
      - no_proxy=.mydomain.com
      - GF_SECURITY_ADMIN_USER=${ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
```

While this will work for many containers, Grafana has been waiting on [this commit](https://github.com/golang/net/commit/c21de06aaf072cea07f3a65d6970e5c7d8b6cd6d) to trickle through to the Grafana build using a newer version of the Go language compiler, which currently lacks sufficient no_proxy support to prevent the external internet proxy from being used for Graphite datasources. This means that Grafana won't be able to talk to Prometheus without traversing the proxy, which may likely be configured not to allow proxying traffic back to internal destinations. Currently you'll break Grafana's access to Prometheus if you enable the above. Grafana will work for you in the stack as-is, but trying to install Grafana plugins (such as worldPing) that require internet access while behind a required web proxy may be difficult at present.

UPDATE: [Go 1.11](https://github.com/golang/go/releases) which includes proper NO_PROXY support for Go binaries was released August 24 2018, hopefully Grafana will soon update their Docker image using this Go build soon - [https://github.com/grafana/grafana/issues/13030](https://github.com/grafana/grafana/issues/13030)
