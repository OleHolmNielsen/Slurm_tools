# InfiniBand tools for Slurm

The tools in this folder may be useful with Slurm on systems with InfiniBand or Omni-Path networks.

The reason why we need this tool is that InfiniBand ports may take a number of seconds to become activated at system boot time,
and `NetworkManager` cannot be configured to wait for InfiniBand,
but will claim that the network is online as soon as one interface is ready (typically Ethernet).

If you have configured `Node Health Check` (NHC) to check the InfiniBand ports,
the NHC check is going to fail until the InfiniBand ports are up.
Please note that `slurmd` will call NHC at startup, if `HealthCheckProgram` has been configured in `slurm.conf`.
Jobs started by `slurmd` may fail if the InfiniBand port is not yet up.

This work is based on scripts by Ward Poelmans <ward.poelmans@vub.be> and Max Rutkowski <max.rutkowski@gfz-potsdam.de>.

Usage
-----

The `waitforib.sh` tool waits until at least 1 InfiniBand *link_layer* port is in the `ACTIVE` state.
At that point it will be OK to start jobs run by `slurmd` or mount `NFS network mounts` over InfiniBand.

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

When the system is rebooted, the `network-online.target` is delayed until InfiniBand/Omni-Path is active.

Disabling the Ethernet iRDMA driver
----------------------------------------

It may happen that a "fake" InfiniBand device exists on a system with certain Ethernet NICs.
The `irdma` Linux driver enables RDMA functionality on RDMA-capable Intel network devices,
see https://downloadmirror.intel.com/738730/README_irdma.txt
Devices supported by this driver:

- Intel(R) Ethernet Controller E800 Series
- Intel(R) Ethernet Network Connection X722

You can verify the type of Ethernet NIC in the system with:
```
lspci | grep Ethernet
```
Check for the presence of any RDMA devices by the commands:
```
rdma link show
ibstatus
```

It is possible to disable the `irdma` Linux kernel module by creating a file `/etc/modprobe.d/disable-irdma.conf`:
```
echo "blacklist irdma" > /etc/modprobe.d/disable-irdma.conf
```
and reboot the system.
