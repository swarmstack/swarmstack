# Using user-supplied certificates with Caddyserver and swarmstack

- Place your own cert.pem and key.pem in this directory under your local copy of swarmstack

- un-comment the (8) related caddy_key and caddy_cert config lines in your local docker-compose.yml

- set CADDY_TLS and CADDY_URL in your local ansible/clusters/_cluster-file_ before running swarmstack.yml playbook
