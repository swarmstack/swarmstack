# Using user-supplied certificates with Caddyserver and swarmstack

swarmstack ansible users:

- Place your own cert.pem and key.pem or other files in this directory under your local copy of swarmstack

- un-comment the related caddy_key and caddy_cert config lines in your local docker-compose.yml and add more as needed for your cert files

- set CADDY_TLS and CADDY_URL as commented in your local ansible/clusters/_cluster-file_ before running swarmstack.yml playbook

---

swarmstack singlebox users:

- un-comment all related caddy_key and caddy_cert config lines in your local docker-compose-singlebox.yml

- add CADDY_URL='fqdn.example.com' and CADDY_TLS='{ load /etc/caddycerts }' when deploying swarmstack:

```
ADMIN_PASSWORD='changeme!42' \
CADDY_URL='fqdn.example.com' \
CADDY_TLS='{ load /etc/caddycerts }' \
docker stack deploy -c docker-compose-singlebox.yml swarmstack
```
