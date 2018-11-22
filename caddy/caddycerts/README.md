# Using user-supplied certificates with Caddyserver and swarmstack

This has security considerations, and you might want to build your own Caddy image by cloning the https://github.com/swarmstack/caddy repo and building your own caddy:no-stats container image with your certificate files baked into the build. Anyone with just read-access to the Docker swarm API, via mis-configured firewall, swarm /var/run/docker.sock file, or administrative access in containers (such as Portainer) are able to see the full contents of files that Docker swarm configs are pushing into container files.

Place your own separate cert.pem and key.pem files in this directory within your local copy of swarmstack.

## swarmstack HA users:

- un-comment and edit all the related caddy_key and caddy_cert config lines in your local docker-compose.yml

- set CADDY_CERT, CADDY_KEY, and CADDY_URL as noted in your local ansible/clusters/_cluster-file_ before running swarmstack.yml playbook

---

## swarmstack singlebox users:

- un-comment and edit all related caddy_key and caddy_cert config lines in your local docker-compose-singlebox.yml

```
ADMIN_PASSWORD='changeme!42' \
CADDY_URL=fqdn.example.com \
CADDY_CERT=/etc/caddycerts/cert.pem' \
CADDY_KEY=/etc/caddycerts/key.pem \
docker stack deploy -c docker-compose-singlebox.yml swarmstack
```
