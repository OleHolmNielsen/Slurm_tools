Slurm cloud node scripts
------------------------

Some convenient scripts for working with cloud nodes:

* ```cloudresume```: ResumeProgram configured in ```slurm.conf```.
* ```cloudsuspend```: SuspendProgram configured in ```slurm.conf```.
* ```azure_nodes```: Handle Azure cloud nodes.

The ```cloud*``` scripts simply execute the ```azure_nodes``` script for nodes in the Azure cloud.

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

ToDo
----

* In ```slurm.conf``` all cloud nodes should be configured with ```State=CLOUD``` and a cloud-specific ```Feature```:

```
NodeName=cloud[001-002] ... State=CLOUD Feature=xxx,Azure
```

* ```cloudresume``` and ```cloudsuspend``` should use ```sinfo``` to detect 
  various cloud providers and call a special script for each type of cloud.
