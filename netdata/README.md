# Installing NetData on your nodes

swarmstack is in the process of moving from Google's cAdvisor and the Prometheus node-exporter to NetData, which provides many more system metrics and allows for much higher resolution capture and averaging of samples. Currently NetData must be installed separately on each host as a Docker container rather than as a Docker swarm service, this is because swarm doesn't yet provide access to entitled service capabilites that are a requirement of using NetData. When this capability gets added to Moby upstream, we'll move NetData installation into the main swarmstack docker-compose.yml.

It's simple enough to install the NetData container on each host:
```
  yum install docker-compose
  cd /usr/local/src
  git clone https://github.com/swarmstack/swarmstack
  # use "git pull" instead if you are updating swarmstack
  cd swarmstack/netdata
  vi docker-compose.yml
```
Replace the PGID with your local installation's docker group, and change swarmhostX to something descriptive of the host, this can even be the host's FQDN. Finally:
```
  docker-compose up -d
```
---
You can edit swarmstack/caddy/index.html to add links to each host you are adding (uncomment and edit the examples). 

On your manager node that you deploy swarmstack from, you'll also need to edit caddy/Caddyfile and uncomment the port :19999 example at the bottom, editing the section for the number of hosts you are adding. Finally, edit swarmstack/docker-compose.yml and uncomment port :19999 in the caddy service, and reploy swarmstack.
