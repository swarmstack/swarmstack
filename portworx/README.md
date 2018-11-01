# PX-Lighthouse swarmstack for Portworx PX-Enterprise

You can use this stack after deploying swarmstack if you chose to set PORTWORX_INSTALL=px-enterprise:1.5.1

```
cd /usr/local/src/localswarmstack/portworx
docker stack deploy -c docker-compose.yml px-lighthouse 
```

You'll then need to configure your localswarmstack/docker-compose.yml caddy service and add the ports 9096 (http:) and 9097 (https:)

```
  caddy:
    image: swarmstack/caddy:no-stats
    ports:
      - "80:80"
      - "443:443"
      - "3000:3000"
      - "9000:9000"
      - "9090:9090"
      - "9091:9091"
      - "9093:9093"
      - "9094:9094"
      - "9095:9093"
      - "9096:9096"
      - "9097:9097"
      - "19998:19999"
```

Also update caddy/Caddyfile or caddy/Caddyfile.ldap and add these sections:

```
:9096 {
  errors stderr
  proxy / http://lighthouse {
    transparent
  }
}

:9097 {
  tls self_signed
  errors stderr
  proxy / https://lighthouse {
    transparent
  }
}
```

Finally, remove and re-deploy swarmstack, which will re-configure caddy to proxy the PX-Lighthouse traffic:

```
cd /usr/local/src/localswarmstack
docker stack rm swarmstack
ADMIN_PASSWORD='changeme!42' docker stack deploy -c docker-compose.yml swarmstack
# or cd ansible; ansible-playbook -i clusters/swarmstack playbooks/swarmstack.yml -k
```
