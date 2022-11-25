Slurm power saving scripts
--------------------------

Slurm configurations related to cloud nodes are described in these pages:

* https://slurm.schedmd.com/elastic_computing.html
* https://slurm.schedmd.com/power_save.html

We have a Wiki page including some Azure documentation:

* https://wiki.fysik.dtu.dk/niflheim/Slurm_cloud_bursting

Usage
-----

Copy these scripts to ```/usr/local/bin/```:
```
cp noderesume nodefailresume nodesuspend power_ipmi power_azure /usr/local/bin/
```

Configure ```slurm.conf``` with:
```
ResumeProgram=/usr/local/bin/noderesume
ResumeFailProgram=/usr/local/bin/nodefailresume
SuspendProgram=/usr/local/bin/nodesuspend
```

Then reconfigure Slurm:
```
scontrol reconfig
```

The poer saving script logs actions in files in the Slurm log directory:
```
/var/log/slurm/power_ipmi.log
/var/log/slurm/power_azure.log
```

slurm.conf configuration
------------------------

There are some additional configurations which may be used when the cluster contains cloud node partitions:

```
# Exceptions to the node suspend/resume logic (partitions):
SuspendExcParts=xeon8,xeon16,xeon24	# Example
SuspendExcNodes=onprem[001-002]		# Example
SlurmctldParameters=idle_on_node_suspend,cloud_dns
ResumeTimeout=600
SuspendTimeout=120
DebugFlags=Power
TreeWidth=65536		# Only when cloud nodes are used
```

In https://bugs.schedmd.com/show_bug.cgi?id=14270 there is a workaround for ```slurm.conf``` to make cloud nodes visible to sinfo:
```
PrivateData=cloud
```
