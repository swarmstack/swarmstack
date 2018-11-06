# Using customer certificates with Caddyserver

- Place your own cert.pem and key.pem in this directory under your local copy of swarmstack

- un-comment the (8) related caddy_key and caddy_cert config lines in your local docker-compose.yml

- set CADDY_USER_CERTS=true in your local ansible/clusters/_cluster-file_ before running the swarmstack.yml playbook on the cluster
