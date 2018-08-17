# swarmstack Maintenance

    # /opt/pwx/bin/pxctl status
    # /opt/pwx/bin/pxctl volume list

    # systemctl stop docker
    # systemctl stop portworx
    # systemctl stop etcd3

    # docker config ls
    # docker stack ls
    # docker stack rm mon
    # ADMIN_USER=admin ADMIN_PASSWORD=somepassword PUSH_USER=pushuser PUSH_PASSWORD=pushpass sudo docker stack deploy -c docker-compose.yml mon

