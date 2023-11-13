InfiniBand tools for Slurm
--------------------------------

The tools in this folder may be useful with Slurm on systems with InfiniBand and Omni-Path networks.

Usage
-----

The `waitforib.sh` tool waits until at least 1 InfiniBand *link_layer* port is in the `ACTIVE` state.
At that point jobs run by `slurmd` or `NFS network mounts` may be started.

The `waitforib.service` Systemd service delays the `network-online.target` until InfiniBand is active.

Installation
--------------

Copy the script:
```
cp waitforib.sh /usr/local/bin/
chmod +x /usr/local/bin/waitforib.sh
```

Enable the Systemd service:
```
cp waitforib.service /etc/systemd/system/
systemctl enable waitforib.service
```
