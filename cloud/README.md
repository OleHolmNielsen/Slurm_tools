Slurm cloud node scripts
------------------------

Slurm configurations related to cloud nodes are described in these pages:

* https://slurm.schedmd.com/elastic_computing.html
* https://slurm.schedmd.com/power_save.html

Some convenient scripts for working with cloud nodes:

* ```cloudresume```: The ```ResumeProgram``` configured in ```slurm.conf```.
* ```cloudsuspend```: The ```SuspendProgram``` configured in ```slurm.conf```.
* ```azure_nodes```: Handles Azure cloud nodes.

For nodes in the Azure cloud,
the ```cloud*``` scripts simply execute the ```azure_nodes``` script for nodes in the Azure cloud.
It is recommended that the Azure CLI command ```az``` should be used to login the ```slurm``` user to an Azure subscription.
Otherwise you must insert suitable  ```sudo``` commands for running Azure CLI commands.

We have a Wiki page including some Azure documentation:

* https://wiki.fysik.dtu.dk/niflheim/Slurm_cloud_bursting

Usage
-----

Copy these scripts to ```/usr/local/bin/```:
```
cp cloudresume cloudsuspend azure_nodes /usr/local/bin/
```

Configure ```slurm.conf``` with:
```
ResumeProgram=/usr/local/bin/cloudresume
SuspendProgram=/usr/local/bin/cloudsuspend
```

Then reconfigure Slurm:
```
scontrol reconfig
```

The ```azure_nodes``` script logs actions in this file in the Slurm log directory:
```
LOGFILE=/var/log/slurm/power_save.log
```

slurm.conf configuration
------------------------

* In ```slurm.conf``` all cloud nodes should be configured with ```State=CLOUD``` and a cloud-specific ```Feature```, for example:

```
NodeName=cloud[001-002] ... State=CLOUD Feature=xxx,Azure
```

There are some additional configurations which may be used when the cluster contains cloud node partitions:

```
# Exceptions to the node suspend/resume logic (partitions):
SuspendExcParts=xeon8,xeon16,xeon24
SuspendExcNodes=onprem[001-002]
SlurmctldParameters=idle_on_node_suspend,cloud_dns
ResumeTimeout=600
SuspendTimeout=120
ResumeProgram=/usr/local/bin/cloudresume
SuspendProgram=/usr/local/bin/cloudsuspend
DebugFlags=Power
TreeWidth=65536
```

In https://bugs.schedmd.com/show_bug.cgi?id=14270 there is a workaround for ```slurm.conf``` to make cloud nodes visible to sinfo:
```
PrivateData=cloud
```


IPsec VPN tunnel
----------------

The files ```azure.conf``` and ```azure.secrets``` are examples for use with an IPsec VPN tunnel.
A detailed description is in the Wiki page 
https://wiki.fysik.dtu.dk/it/Libreswan_IPsec_VPN

ToDo
----

* ```cloudresume``` and ```cloudsuspend``` should use ```sinfo``` to detect 
  various cloud providers and call a special script for each type of cloud.
