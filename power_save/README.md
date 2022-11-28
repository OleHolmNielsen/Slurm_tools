Slurm power saving scripts
==========================

The present Slurm power saving scripts have been designed to be called from the Slurm controller ```slurmctld```
using the ```slurm.conf``` resume and suspend programs discussed below.
The programs can also be called directly from the command line.
They will call different helper scripts according to the type of power management relevant for different types of nodes.

The power management type for each node set is configured as *node features* in ```slurm.conf```.

General Slurm configurations related to power saving are described in the page https://slurm.schedmd.com/power_save.html.

Prerequisites
-------------

1. Slurm's power saving (prior to version 22.05.6) requires Slurm to be built with JSON support as described in the Wiki page
   [Slurm configuration for cloud nodes](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_cloud_bursting/#slurm-configuration-for-cloud-nodes).
   This is described in [bug 14925](https://bugs.schedmd.com/show_bug.cgi?id=14925).

2. The scripts require the [nodeset](https://clustershell.readthedocs.io/en/latest/tools/nodeset.html) command from the
   [ClusterShell](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_operations/#clustershell) package,
   install it as RPM packages by:
   ```
   yum install epel-release
   yum install clustershell
   ```

Usage
-----

Copy these scripts to ```/usr/local/bin/```:
```
cp noderesume nodefailresume nodesuspend power_ipmi power_azure /usr/local/bin/
```

Configure script variables
--------------------------

We need to configure the BMC's DNS hostname as well as the IPMI administrator username and password for the ```ipmitool``` command.
For security reasons the username/password should be kept in a separate file which cannot be read by normal users.
The helper script ```ipmi_setup``` may be useful for setting up IPMI on every compute node.

Add these lines (uncommented) to the slurm user's ```.bashrc``` file (and for other users who need to execute the script)
which should export variables for ```power_ipmi```, for example:
```
export IPMI_USER=root
export IPMI_PASSWORD=verysecretpassword
# Define the node BMC DNS name: BMC DNS-name is the node name plus this suffix:
export BMC_SUFFIX="b"
```
This file will be sourced by the scripts.

In the ```nodefailresume``` script configure the sysadmin E-mail address in this line:
```
slurm_notify=<sysadmin-email>
```

Adding node features
--------------------

The ```nodesuspend``` and ```noderesume``` scripts require the addition of *node features*
in [slurm.conf](https://slurm.schedmd.com/slurm.conf.html#SECTION_NODE-CONFIGURATION).

We must define some node features ```power_xxx```, for example:

```
NodeName=node[001-100] Feature=xeon2650v4,opa,xeon24,power_ipmi
NodeName=cloud[001-100] Feature=xeon8272cl,power_azure
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

There are some additional configurations which are used when the cluster contains nodes using power saving (including cloud nodes):

```
# Exceptions to the node suspend/resume logic (partitions):
SuspendExcParts=xeon8,xeon16,xeon24	# Example
SuspendExcNodes=onprem[001-002]		# Example
SlurmctldParameters=idle_on_node_suspend,cloud_dns
ResumeTimeout=600
SuspendTimeout=120
DebugFlags=Power
TreeWidth=65536		# Configure TreeWidth only when cloud nodes are used
```

In https://bugs.schedmd.com/show_bug.cgi?id=14270 there is a workaround for ```slurm.conf``` to make cloud nodes visible to sinfo:
```
PrivateData=cloud
```

A very important point:

* If you set ```SuspendTime``` to anything but INFINITE (or -1), power saving shutdown of **all** nodes will commence as soon as you reconfigure Slurm!

* It may perhaps be preferable to omit the global parameter and leave it with the default value ```SuspendTime=INFINITE```.   
  In stead define it only on any relevant partitions, for example:

```
    PartitionName=my_partition SuspendTime=300
```

Finally reconfigure the Slurm controller:
```
scontrol reconfig
```
