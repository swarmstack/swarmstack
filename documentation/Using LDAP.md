# Using LDAP

LDAP configuration can be applied automatically to the Caddy proxy that fronts most of the tools, as well as Grafana. You'll need to set LDAP_ENABLE=true and uncomment and configure the rest of the LDAP settings within one of your ansible/cluster files. Portainer requires manual LDAP configuration (uses similar settings) currently.

The documentation below is for reference about what the swarmstack playbook will apply when configured as above, and can be used as a reference if you need to make changes to your local copy of swarmstack.

### Caddy - LDAP

Caddy is the webserver/reverse proxy used to terminate HTTP/S connections and proxy connections to the other tools. To enable LDAP rather than basic authenticaion, you can edit _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_ and replace:

```
  caddy_config:
    file: ./caddy/Caddyfile
```
with
```
  caddy_config:
    file: ./caddy/Caddyfile.ldap
```
You'll need to edit that file before deploying and replace with your organization's LDAP settings. The username filter _uid=%s_ may need to be changed to _sAMAccountName=%s_ or something else for your environment. Consult your LDAP administrator or documentation for the proper mappings.

### Grafana - LDAP
You'll need to add the following to _[docker-compose.yml](https://github.com/swarmstack/swarmstack/blob/master/docker-compose.yml)_:

```
configs:
  grafana_configuration:
    file: ./grafana/grafana.ini
  grafana_ldap:
    file: ./grafana/ldap.toml
```
and under later in the file:
```
    volumes:
      - grafana:/var/lib/grafana
    configs:
      - source: grafana_configuration
        target: /etc/grafana/grafana.ini
      - source: grafana_ldap
        target: /etc/grafana/ldap.toml

```
The supplied _[grafana/grafana.ini](https://github.com/swarmstack/swarmstack/blob/master/grafana/grafana.ini)_ changes just:
```
#################################### Auth LDAP ##########################
[auth.ldap]
enabled = true
allow_sign_up = true
;config_file = /etc/grafana/ldap.toml  # Default location Grafana will look for LDAP settings
```
You'll need to edit _[grafana/ldap.toml](https://github.com/swarmstack/swarmstack/blob/master/grafana/ldap.toml)_ and configure your LDAP settings. At the bottom of the file you'll see that authenticated users are registered upon first LDAP login as a _Viewer_. There are commented sections above that that provide examples for creating users as 'Editor' or even as 'Admin'.
