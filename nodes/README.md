Slurm node scripts
------------------

Some convenient scripts for working with nodes (or lists of nodes):

* Show status, jobs, events, reservations for a list of nodes: ```shownode <node-list>```.
  **Recommended** as an easy way to print all relevant information about a node-list.
* Drain a node-list: ```sdrain node-list "Reason"```.
* Resume a node-list: ```sresume node-list```.
* Reboot and resume a node-list: ```sreboot node-list```.
* Reserve nodes when they become idle: ```reserve_on_idle [-s|--single-reservation] [-k|--keep-reservation] [-d|--duration DURATION] "<node-list>"```.
* Show node status: ```shownode <node-list>```.
* Power up/down a node-list: ```spowerup node-list``` and ```spowerdown node-list```.
  Note: This only works with nodes in Slurm power saving, NOT nodes in state DOWN, DRAIN etc.
* Show node events in Slurm database: ```showevents < -w <node-list> | -p partition | -a | -h > [ -t time_period ]```.
* Show node power values: ```showpower < -w node-list | -p partition(s) | -a | -h > [ -S sorting-variable ] -s```.
* Check dead nodes with a ping: ```alive``` (may be run from crontab every 10 minutes)
* Check node BMCs with a ping: ```alive_bmc``` (may be run from crontab regularly)
* Show Nvidia GPU power values: ```showpower_nvidia < -w node-list | -p partition(s) | -a | -h > -s```
* Do a ```ps``` process status on a node-list, but exclude system processes: ```psnode [-c columns | -h] node-list```.
* Print Slurm version on a node-list: ```sversion node-list```. Requires [ClusterShell](https://wiki.fysik.dtu.dk/niflheim/SLURM#clustershell).
* Check consistency of /etc/slurm/topology.conf with node-list in /etc/slurm/slurm.conf: ```checktopology```
* Compute node OS and firmware updates using the ```update.sh``` script.

Usage
-----

Copy these scripts to /usr/local/bin/.
If necessary configure the variables in the script.

Example output from ```psnode```:

```
Node d064 information:
NODELIST   PARTITION  CPUS  CPU_LOAD    S:C:T  MEMORY       STATE REASON              
d064       xeon8*        8      2.01    2:4:1   47000       mixed none                
d064       xeon8_48      8      2.01    2:4:1   47000       mixed none                
Jobid list: 3381322 3380373
Node d064 user processes:
  PID NLWP S USER      STARTED     TIME %CPU   RSS COMMAND
19984    1 S user1      Jan 19 00:00:00  0.0  2224 /bin/bash -l /var/spool/slurmd/job3380373/slurm_s
20092    1 S user1      Jan 19 00:00:00  0.0  1368 /bin/bash -l /var/spool/slurmd/job3380373/slurm_s
20094    3 R user1      Jan 19 1-06:25:18 99.9 256676 python3 /home/user1/wlda/atomic_bench
20096    5 S user1      Jan 19 00:00:01  0.0 15136 orted --hnp --set-sid --report-uri 8 --singleton-
27564    1 S user1    22:42:23 00:00:00  0.0  2228 /bin/bash -l /var/spool/slurmd/job3381322/slurm_s
27673    1 S user1    22:42:27 00:00:00  0.0  1372 /bin/bash -l /var/spool/slurmd/job3381322/slurm_s
27675    3 R user1    22:42:27 10:11:58 99.9 242464 python3 /home/user1/wlda/atomic_benchma
27676    5 S user1    22:42:27 00:00:00  0.0 15132 orted --hnp --set-sid --report-uri 8 --singleton-
Total: 8 processes and 20 threads
```

Compute node OS and firmware updates
------------------------------------

Assume that you want to update OS and firmware on a specific set of nodes defined as ```<node-list>```.
It is recommended to update entire partitions, or the entire cluster, at a time in order to avoid having inconsistent node states in the partitions.

The approach used in the present procedure is:

1. Execute a crontab job on compute nodes at reboot time.
   The script will do nothing, unless the node has Slurm ```State=down```.

2. Reboot the compute nodes using ```scontrol reboot asap nextstate=down <nodelist>```.
   Here we use ```State=down``` as a trigger telling the update script to perform updates.

This procedure requires [ClusterShell](https://wiki.fysik.dtu.dk/niflheim/SLURM#clustershell)
and the 3 scripts [update_down_node.sh](update_down_node.sh), [update_software.sh](update_software.sh)
and [update_firmware.sh](update_firmware.sh) from this project.

You first have to:

1. Review the CONFIGURE section of the [update_down_node.sh](update_down_node.sh) script and configure for your environment.

2. Review the [update_software.sh](update_software.sh) and [update_firmware.sh](update_firmware.sh) scripts and configure for your environment
   as regards what packages to update and which firmwares to install.
   You could omit the firmware update file if you do not want to use this method.

3. Copy the files [update_software.sh](update_software.sh) and [update_firmware.sh](update_firmware.sh)
   to the shared network location specified in [update_down_node.sh](update_down_node.sh).
   They will be copied to the compute node and sourced by the [update_down_node.sh](update_down_node.sh) script.
   In this way we will be sure to use the up-to-date scripts. 

Now copy (only) the [update_down_node.sh](update_down_node.sh) file to the compute nodes:
```
clush -bw <node-list> --copy update_down_node.sh --dest /root/
```
On the compute nodes append this entry to root's crontab:
```
@reboot /root/update_down_node.sh
```

If nodes in the node-list are in non-exclusive partitions, run ```reserve_on_idle``` to create a reservation for each node starting when its last currently running job is expected to finish. This allows Slurm backfill to schedule new jobs only if they can finish before the reservation begins:
```
reserve_on_idle <node-list>
```
Use ```-s``` or ```--single-reservation``` to create one reservation for the full node-list instead. The single reservation starts when the last job across all requested nodes is expected to finish, and implies ```--keep-reservation```.

Then schedule the nodes for reboot through Slurm as soon as they become idle, and set their next state to DOWN
using the ```-d``` option:
```
sreboot -d -r UPDATE <node-list>
```
You can now check nodes regularly (a few times per day) as the rolling updates proceed.

NOTE: The previously documented script ```update.sh``` has been superceded by the current method for updating.

GPU monitoring
--------------

The ```psnode``` script can also monitor the job's GPU usage using the ```gpustat``` tool from https://github.com/wookayin/gpustat.
If the the job uses ```gres/gpu``` on nodes with GPUs, the ```gpustat``` tool is used to display GPU usage.
If ```gpustat``` isn't installed, set the variable ```enable_gpustat=0``` in the ```psnode``` script.

All GPU nodes should have this tool installed.
On EL8 systems:
```
dnf install gcc python3 python3-pip python3-devel
python3 -m pip install setuptools-scm
python3 -m pip install gpustat
```
