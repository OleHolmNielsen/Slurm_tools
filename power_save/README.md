Slurm power saving scripts
==========================

The present Slurm power saving scripts have been designed to be called from the Slurm controller ```slurmctld```
using the ```slurm.conf``` resume and suspend programs discussed below.
These programs will call different helper scripts according to the type of power management relevant for different types of nodes.

The power management type for each node set is configured as *node features* in ```slurm.conf```.

General Slurm configurations related to power saving are described in the page https://slurm.schedmd.com/power_save.html.

We also have a Wiki page including some Azure cloud documentation describing power saving:

* https://wiki.fysik.dtu.dk/niflheim/Slurm_cloud_bursting

Usage
-----

Copy these scripts to ```/usr/local/bin/```:
```
cp noderesume nodefailresume nodesuspend power_ipmi power_azure /usr/local/bin/
```

Adding node features
--------------------

The ```nodesuspend``` and ```noderesume``` scripts require the addition of *node features*
in [slurm.conf](https://slurm.schedmd.com/slurm.conf.html#SECTION_NODE-CONFIGURATION).

We define some node features ``power_xxx``, for example:

```
NodeName=x[001-100] Feature=xeon2650v4,opa,xeon24,power_ipmi
```

The features are used by the ```nodesuspend``` and ```noderesume``` scripts
to identify the power management features associated with each node.
The scripts currently handle ``power_ipmi`` and ``power_azure`` features,
but other features may be added.

Logging of power savings
------------------------

The power saving script logs actions in files in the Slurm log directory:
```
/var/log/slurm/power_ipmi.log
/var/log/slurm/power_azure.log
/var/log/slurm/nodefailresume.log
```
The log files must be writable by the slurm user, verify by:

```
scontrol show config | grep SlurmUser
ls -la /var/log/slurm
```

slurm.conf configuration
------------------------

Configure ```slurm.conf``` with:
```
ResumeProgram=/usr/local/bin/noderesume
ResumeFailProgram=/usr/local/bin/nodefailresume
SuspendProgram=/usr/local/bin/nodesuspend
```

There are some additional configurations which may be used when the cluster contains cloud node partitions:

```
# Exceptions to the node suspend/resume logic (partitions):
SuspendExcParts=xeon8,xeon16,xeon24	# Example
SuspendExcNodes=onprem[001-002]		# Example
SlurmctldParameters=idle_on_node_suspend,cloud_dns
ResumeTimeout=600
SuspendTimeout=120
DebugFlags=Power
TreeWidth=65536		# Necessary only when cloud nodes are used
```

In https://bugs.schedmd.com/show_bug.cgi?id=14270 there is a workaround for ```slurm.conf``` to make cloud nodes visible to sinfo:
```
PrivateData=cloud
```

A very important point:

* If you set ```SuspendTime``` to anything but INFINITE (or -1), power saving shutdown of nodes will commence as soon as you reconfigure Slurm!

* It may be preferable to omit the global parameter and leave it with the default value ```SuspendTime=INFINITE```.   
  In stead define it only on any relevant partitions, for example:

```
    PartitionName=my_partition SuspendTime=300
```

Then reconfigure the Slurm controller:
```
scontrol reconfig
```
