[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
Type=simple
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd --name etcd-{{ hostvars[inventory_hostname]['inventory_hostname'] }} \
		--data-dir /var/lib/etcd \
		--quota-backend-bytes 8589934592 \
                --auto-compaction-retention 3 \
		--listen-client-urls http://0.0.0.0:2379 \
		--advertise-client-urls http://{{ hostvars[inventory_hostname]['IP'] }}:2379 \
		--listen-peer-urls http://{{ hostvars[inventory_hostname]['IP'] }}:2380 \
		--initial-advertise-peer-urls http://{{ hostvars[inventory_hostname]['IP'] }}:2380 \
                --initial-cluster \
{% for host in members %}etcd-{{ hostvars[host].inventory_hostname}}=http://{{ hostvars[host].IP}}:2380{{ '' if loop.last else ','}}{% endfor %}
		--initial-cluster-token my-etcd-token \
		--initial-cluster-state new

[Install]
WantedBy=multi-user.target
