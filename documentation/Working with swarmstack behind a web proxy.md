# Working with swarmstack behind a web proxy

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

## Grafana (and other containers)

_Hint:_ You may find that varying applications within containers parse their environment for proxies with differing requirements, such as requiring leading URI:// _(e.g. http_proxy=proxy.example.com:80 or http_proxy=http://proxy.example.com:80)_. Some applications might want to see HTTPS_PROXY instead. Consult application documentation in these cases, and add the appropriate environent statements to the individual container that requires internet access via proxy.

If you plan to install plugins using internet sources, you'll need add your https_proxy to to containers within the docker-compose.yml:

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
