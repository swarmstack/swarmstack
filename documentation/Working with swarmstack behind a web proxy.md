# Working with swarmstack behind a web proxy

For Docker to retrieve images from the internet, you'll need to add the following file on each Docker node:

    /etc/systemd/system/docker.service.d/http-proxy.conf


    [Service]
    Environment="http_proxy=proxy.example.com:80" "https_proxy=proxy.example.com:443" "no_proxy=*.example.com"

Then reload systemd and restart Docker on each node:

    # systemctl daemon-reload
    # systemctl restart docker

_Hint:_ You may find that varying applications within containers parse their environment for proxies with differing requirements, such as requiring leading URI:// _(e.g. http_proxy=proxy.example.com:80 or http_proxy=http://proxy.example.com:80)_. Some applications might want to see HTTPS_PROXY instead. Consult application documentation in these cases, and add the appropriate environent statements to the individual container that requires internet access via proxy.

## Grafana (and other containers)

If you plan to install plugins using internet sources, you'll need add your https_proxy to to containers within the docker-compose.yml:

```
  grafana:
    image: grafana/grafana:latest
    networks:
      - net
    environment:
      - http_proxy=http://proxy.example.com:80
      - https_proxy=https://proxy.example.com:443
      - no_proxy=example.com,10.0.0.0/8
      - GF_SECURITY_ADMIN_USER=${ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
```

While this will work for many containers, it looks like Grafana is waiting on [this commit](https://github.com/golang/net/commit/c21de06aaf072cea07f3a65d6970e5c7d8b6cd6d) to trickle through to the Grafana build using a newer version of golanc, which currently lacks sufficient no_proxy support to prevent the external internet proxy from being used for Graphite datasources. This means that Grafana won't be able to talk to Prometheus without traversing proxy, which may likely be configured not to allow proxying traffic to internal destinations. Currently you'll break Grafana's access to Prometheus if you enable the above. Check back soon. Grafana will work for you in the stack as-is, but trying to install Grafana plugins (such as worldPing) that require internet access while behind a required web proxy may be difficult at present.




