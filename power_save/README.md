Slurm power saving scripts
==========================

Slurm configurations related to power saving are described in the page https://slurm.schedmd.com/power_save.html

We have a Wiki page including some Azure cloud documentation describing also power saving:

* https://wiki.fysik.dtu.dk/niflheim/Slurm_cloud_bursting

Usage
-----

Copy these scripts to ```/usr/local/bin/```:
```
cp noderesume nodefailresume nodesuspend power_ipmi power_azure /usr/local/bin/
```

The power saving script logs actions in files in the Slurm log directory:
```
/var/log/slurm/power_ipmi.log
/var/log/slurm/power_azure.log
```
The log files must be writable by the slurm user, see::

  scontrol show config | grep SlurmUser

Adding node features
--------------------

The ``nodesuspend`` and ``noderesume`` scripts require the addition of *node features*
in [slurm.conf](https://slurm.schedmd.com/slurm.conf.html#SECTION_NODE-CONFIGURATION).

We defines some node features ``power_xxx``, for example::

  NodeName=x[001-100] Feature=xeon2650v4,opa,xeon24,power_ipmi

The scripts currently handle ``power_ipmi`` and ``power_azure`` features,
but other features may be added.

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

* If you set ```SuspendTime``` to anything but INFINITE (or -1), power saving shutdown of nodes will commence!

* It may be preferable to omit the global parameter and leave it with the default value ```SuspendTime=INFINITE```.
  In stead define it only on any relevant partitions, for example:

```
    PartitionName=my_partition SuspendTime=300
```

Then reconfigure Slurm:
```
scontrol reconfig
```
