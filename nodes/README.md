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

Keeping your Slurm compute nodes up-to-date with security updates is an important task,
and since updates are now released with a high frequency,
it is desirable to make the updating process as simple and automatic as possible.
The tools documented here offer one possible solution.

Assume that you want to update OS and firmware on a specific set of nodes defined as ```<node-list>```.
It is recommended to update entire partitions (or the entire cluster) at a time
in order to avoid having inconsistent node states in the partitions when new jobs are started.
For an overview of your partitions and their node-lists you may use the command ```sinfo -s```.

The design used in the present approach is:

1. Configure all compute nodes to execute a crontab job script at *every* reboot.
   This script will usually do nothing, except in case the node has a Slurm ```State=down```
   where it will perform the configured updates.

2. Making updates simply consists of rebooting compute node lists with the command ```scontrol reboot asap nextstate=down <node-list>```.
   Here we have employed the Slurm ```State=down``` as a **trigger** telling the update script to perform some actions.

### Configuration

The procedure consists of 3 scripts [update_down_node.sh](update_down_node.sh), [update_software.sh](update_software.sh)
and [update_firmware.sh](update_firmware.sh).

First make some configurations specifically for your environment:

1. Configure variables in the ``CONFIGURE`` section of the [update_down_node.sh](update_down_node.sh) script.

2. Review the [update_software.sh](update_software.sh) script and configure it
   regarding what OS packages to update.

   Optional:
   The firmware update script [update_firmware.sh](update_firmware.sh)
   contains specific functions for updating Dell and Lenovo servers using vendor tools.
   To disable it just comment out this line in the script: ```source /root/$update_firmware```.
   You may need to configure this script where additional functions could be added for your products.

3. Copy the files [update_software.sh](update_software.sh) and [update_firmware.sh](update_firmware.sh)
   to the shared network location ```$SCRIPTDIR```specified in [update_down_node.sh](update_down_node.sh).
   The files will be copied to each compute node and sourced by the [update_down_node.sh](update_down_node.sh) script,
   ensuring the use of only up-to-date scripts distributed from the central server. 

Then add two configurations to all compute nodes:

4. Copy the [update_down_node.sh](update_down_node.sh) file (only) to some or all of the compute nodes
using [ClusterShell](https://wiki.fysik.dtu.dk/niflheim/SLURM#clustershell) (or any other method):
```
clush -bw <node-list> --copy update_down_node.sh --dest /root/
```
5. On the compute nodes append a new entry to root's crontab file
(``/var/spool/cron/root``, how you update this depends on your local management procedures):
```
@reboot /root/update_down_node.sh
```

### Making semi-automatic updates

It is now very easy and simple to **reboot and update** a node-list with this command:
```
scontrol reboot asap nextstate=down <node-list>
```
The nodes will be rebooted as soon as they become idle,
and will be resumed in Slurm following the updates, requiring no further user actions.

Log files of the updates are kept in each node's ```/root``` folder,
namely ```update_down_node.log``` from the crontab job,
and ```update.log``` from the software and firmware updates.

Note: Nodes that have ```State=down``` with a ```Reason=Node unexpectedly rebooted``` are assumed 
to be unrelated to the present update system and will therefore be skipped.

### Optional for mixed state nodes

If nodes in the node-list are in non-exclusive (*mixed* state) partitions,
run [reserve_on_idle](reserve_on_idle) to create a reservation for each node
with a *StartTime* when its last currently running job is expected to finish.
This allows Slurm backfill to schedule new jobs only if they can finish before the reservation begins:
```
reserve_on_idle <node-list>
```

NOTE:
The [reserve_on_idle](reserve_on_idle) script creates a
"magic" Slurm ```ReservationName=update-<nodename>``` for the nodes,
but these will be deleted at the end of the [update_down_node.sh](update_down_node.sh) script.

Use ```-s``` or ```--single-reservation``` to create one reservation for the full node-list instead.
The single reservation starts when the last job across all requested nodes is expected to finish,
and implies ```--keep-reservation```.

Then schedule the nodes for reboot through Slurm as soon as they become idle, and set their next state to DOWN
using the ```-d``` option:
```
sreboot -d -r UPDATE <node-list>
```
You can now check nodes regularly (a few times per day) as the rolling updates proceed.

NOTE: The previously published script [update.sh](update.sh) has been superceded by the current method for updating.

GPU monitoring
--------------

The [psnode](psnode) script can also monitor the job's GPU usage using the [gpustat](https://github.com/wookayin/gpustat) tool.
If the the job uses ```gres/gpu``` on nodes with GPUs, the ```gpustat``` tool is used to display GPU usage.
If ```gpustat``` isn't installed, set the variable ```enable_gpustat=0``` in the [psnode](psnode) script.

All GPU nodes should have this tool installed.
On EL8 and EL9 systems:
```
dnf install gcc python3 python3-pip python3-devel
python3 -m pip install setuptools-scm
python3 -m pip install gpustat
```
