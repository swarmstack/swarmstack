Dynamcally detect Portworx volumes and automatically create daily and weekly snapshots of them.

While you could use the Portworx "pxctl sched-policy" commands to have Portworx automatically take snapshots of your volumes (including directives such as keep 3 daily, and 4 weekly backups), this script can instead just be run daily from crontab and it will maintain a single daily snapshot and a single weekly snapshot for each volume not present on the skip list.


## INSTALLATION

For PX-Dev users, on a single Portworx node per 3-node storage cluster (node 1, 4, 7, etc), or perhaps on just on a single node if running PX-Enterprise with a single large storage cluster:


```
cp bin/portworx_snapshots.sh /usr/local/bin/
```

Edit the script's "donotsnap" list to inhibit snapshots for specific volumes, also set the day for weekly snapshots to be rotated (Fri by default).

Add the script to run from root crontab at 10 minutes past midnight each day:

```
crontab -e

10 0 * * *  /usr/local/bin/portworx_snapshots.sh >/dev/null 2>&1
```
