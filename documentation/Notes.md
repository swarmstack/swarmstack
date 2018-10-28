# swarmstack swarm host notes CLI notes

## SYSTEMD

    # systemctl status docker
    # systemctl status portworx
    # systemctl status etcd3

## PORTWORX

    # /opt/pwx/bin/pxctl status
    # /opt/pwx/bin/pxctl volume list

## DOCKER

    # docker config ls
    # docker stack ls
    # docker volume ls

## MANUAL SWARMSTACK RE-DEPLOYMENT

    # docker stack rm swarmstack

    # cd /usr/local/src/localswarmstack

    # ADMIN_USER=admin ADMIN_PASSWORD=somepassword PUSH_USER=pushuser PUSH_PASSWORD=pushpass docker stack deploy -c docker-compose.yml mon

## FILE TREE

```
.
├── LICENSE
├── PRIVACY.md
├── README.md
├── alertmanager
│   └── conf
│       └── alertmanager.yml
├── ansible
│   ├── README.md
│   ├── clusters
│   │   └── swarmstack
│   ├── playbooks
│   │   ├── docker.yml
│   │   ├── etcd.yml
│   │   ├── firewall.yml
│   │   ├── includes
│   │   │   └── tasks
│   │   │       ├── prompt_colors
│   │   │       │   ├── set_prompt.yml
│   │   │       │   ├── set_prompts_blue.yml
│   │   │       │   ├── set_prompts_green.yml
│   │   │       │   └── set_prompts_red.yml
│   │   │       └── sysctl_el7.yml
│   │   ├── portworx.yml
│   │   ├── swarmstack.yml
│   │   └── util.yml
│   └── roles
│       ├── common
│       │   └── files
│       │       └── etc
│       │           ├── cron.daily
│       │           │   └── clean-docker
│       │           ├── docker
│       │           │   └── daemon.json
│       │           ├── swarmstack_fw
│       │           │   └── rules
│       │           │       └── common.rules
│       │           ├── systemd
│       │           │   └── system
│       │           │       └── docker.service.d
│       │           │           └── docker.conf
│       │           ├── udev
│       │           │   └── rules.d
│       │           │       └── 59-custom-txqueuelen.rules
│       │           └── yum.repos.d
│       │               ├── docker-edge.repo
│       │               ├── docker-stable.repo
│       │               └── docker-test.repo
│       └── swarmstack
│           └── files
│               └── etc
│                   ├── swarmstack_fw
│                   │   └── rules
│                   │       ├── cluster.rules
│                   │       └── docker.rules
│                   └── systemd
│                       └── system
│                           └── docker.service.d
│                               ├── docker.conf
│                               └── proxy.conf
├── caddy
│   ├── Caddyfile
│   ├── Caddyfile.ldap
│   └── index.html
├── docker-compose.yml
├── documentation
│   ├── Adding\ your\ own\ applications\ to\ monitoring.md
│   ├── Manual\ swarmstack\ installation.md
│   ├── Notes.md
│   ├── Updating\ swarmstack.md
│   ├── Using\ LDAP.md
│   ├── Using\ Pushgateway.md
│   ├── Working\ with\ swarmstack\ behind\ a\ web\ proxy.md
│   ├── logos
│   │   ├── swarmstack150x150.png
│   │   ├── swarmstack300x300.png
│   │   └── swarmstack500x500.png
│   └── screens
│       ├── docker_swarm_nodes.png
│       ├── docker_swarm_services.png
│       ├── etcd.png
│       ├── portainer-dashboard.png
│       ├── portainer-stacks.png
│       ├── portainer_cluster.png
│       ├── portworx_cluster_status.png
│       ├── portworx_volumes.png
│       ├── prometheus.png
│       ├── prometheus_alerts.png
│       ├── prometheus_targets.png
│       ├── screen1.png
│       ├── screen10.png
│       ├── screen2.png
│       ├── screen9.png
│       └── swarmstack-diagram.png
├── grafana
│   ├── dashboards
│   │   ├── cluster-nodes.json
│   │   ├── docker-containers.json
│   │   ├── etcd-dash.json
│   │   ├── portworx-cluster-dash.json
│   │   ├── portworx-volumes-dash.json
│   │   └── prometheus-2-stats.json
│   ├── dashboards.yml
│   ├── datasources
│   │   └── prometheus.yaml
│   ├── grafana.ini
│   └── ldap.toml
├── prometheus
│   ├── Dockerfile
│   ├── conf
│   │   └── prometheus.yml
│   └── rules
│       ├── container_nodes.yml
│       ├── docker_containers.yml
│       └── portworx.yml
├── unsee
│   └── unsee.yaml
└── utils
    ├── itdock
    ├── lgdock
    ├── lsdock
    └── psdock
```
