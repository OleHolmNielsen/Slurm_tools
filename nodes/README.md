Slurm node scripts
------------------

Some convenient scripts for working with nodes (or lists of nodes):

* Drain a node-list: ```sdrain node-list "Reason"```.
* Resume a node-list: ```sresume node-list```.
* Reboot and resume a node-list: ```sreboot node-list```.
* Show node status: ```shownode <node-list>```.
* Show node power values: ```showpower < -w node-list | -p partition(s) | -a | -h > [ -S sorting-variable ]```.
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

This procedure requires [ClusterShell](https://wiki.fysik.dtu.dk/niflheim/SLURM#clustershell).

Assume that you want to update OS and firmware on a specific set of nodes defined as ```<node-list>```.
It is recommended to update entire partitions, or the entire cluster, at a time in order to avoid having inconsistent node states in the partitions.

First configure the ```update.sh``` script so that it will perform the required OS and firmware updates for your specific partitions.

Then copy the ```update.sh``` file to the compute nodes:
```
clush -bw <node-list> --copy update.sh --dest /root/
```

On the compute nodes append this crontab entry:
```
clush -bw <node-list> 'echo "@reboot root /bin/bash /root/update.sh" >> /etc/crontab'
```

Then set the nodes to make an automatic reboot (via Slurm)
as soon as they become idle (ASAP, see the ```scontrol``` manual page) 
and change the node state to ```DOWN``` with:
```
scontrol reboot ASAP nextstate=DOWN reason=UPDATE <node-list>
```

You can now check nodes regularly (a few times per day) as the rolling updates proceed.
List the DOWN nodes with ```sinfo -lR```.

Check the status of the DOWN nodes.
For example, you may check the running kernel and the BMC version,
and use [NHC](https://wiki.fysik.dtu.dk/niflheim/Slurm_configuration#node-health-check):
```
clush -bw@slurmstate:down 'uname -r; nhc; dmidecode -s bios-version'
```

When some nodes have been updated and tested successfully, you could resume these nodes by:
```
scontrol update nodename=<nodes that have completed updating> state=resume
```
Resuming the node is actually accomplished at the end of the ```update.sh``` script by these lines:
```
scontrol reboot nextstate=resume `hostname -s`
```

