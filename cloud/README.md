Slurm cloud node scripts
------------------------

Slurm configurations related to cloud nodes are described in these pages:

* https://slurm.schedmd.com/elastic_computing.html
* https://slurm.schedmd.com/power_save.html

Some convenient scripts for working with cloud nodes:

* ```cloudresume```: ResumeProgram configured in ```slurm.conf```.
* ```cloudsuspend```: SuspendProgram configured in ```slurm.conf```.
* ```azure_nodes```: Handle Azure cloud nodes.

The ```cloud*``` scripts simply execute the ```azure_nodes``` script for nodes in the Azure cloud.

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

The ```azure_nodes``` script logs actions in this file:
```
LOGFILE=/var/log/slurm/power_save.log
```

slurm.conf configuration
------------------------

* In ```slurm.conf``` all cloud nodes should be configured with ```State=CLOUD``` and a cloud-specific ```Feature```:

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
TreeWidth=1000
# Workaround: Make cloud nodes visible to sinfo:
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
