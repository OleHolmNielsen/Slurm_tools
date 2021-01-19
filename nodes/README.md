Slurm node scripts
------------------

Some convenient scripts for working with nodes (or lists of nodes):

* Drain a node-list: ```sdrain node-list "Reason"```.
* Resume a node-list: ```sresume node-list```.
* Do a ```ps``` process status on a node-list, but exclude system processes: ```psnode [-c columns | -h] node-list```.
* Print Slurm version on a node-list: ```sversion node-list```. Requires [ClusterShell](https://wiki.fysik.dtu.dk/niflheim/SLURM#clustershell).
* Check consistency of /etc/slurm/topology.conf with nodelist in /etc/slurm/slurm.conf: ```checktopology```
* Compute node OS and firmware updates using the ```update.sh``` script.


Usage
-----

Copy these scripts to /usr/local/bin/.
If necessary configure the variables in the script.

Example output from ```psnode```:

```
Node g012:
----------
Mon Jan 18 14:56:42 2021
NODELIST   NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON               
g012           1    xeon16   allocated 16      2:8:1  64000   198000  10212 xeon2670 none                 
Jobs on node g012:
JOBID
3378599
  PID NLWP S USER      STARTED     TIME %CPU   RSS COMMAND
57532    1 S user01   11:48:10 00:00:00  0.0  2432 /bin/bash /var/spool/slurmd/job3378599/slurm_scri
57550    1 S user01   11:48:12 00:00:00  0.0 42532 python run_vasp.py
57556    1 S user01   11:48:13 00:00:00  0.0  1672 sh -c srun /home/user01/bin/vasp/5.4.4-intel20
57557    5 S user01   11:48:13 00:00:00  0.0  5872 srun /home/user01/bin/vasp/5.4.4-intel2019/bin
57558    1 S user01   11:48:13 00:00:00  0.0   836 srun /home/user01/bin/vasp/5.4.4-intel2019/bin
57573    1 R user01   11:48:13 03:08:11 99.8 579644 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57574    1 R user01   11:48:13 03:08:06 99.8 562188 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57575    1 R user01   11:48:13 03:08:15 99.8 551612 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57576    1 R user01   11:48:13 03:08:17 99.8 551256 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57577    1 R user01   11:48:13 03:08:13 99.8 563964 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57578    1 R user01   11:48:13 03:08:17 99.8 554440 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57579    1 R user01   11:48:13 03:08:12 99.8 567204 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57580    1 R user01   11:48:13 03:08:16 99.8 548012 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57581    1 R user01   11:48:13 03:08:16 99.8 553972 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57582    1 R user01   11:48:13 03:08:17 99.8 570340 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57583    1 R user01   11:48:13 03:08:10 99.8 556320 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57584    1 R user01   11:48:13 03:08:16 99.8 543640 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57585    1 R user01   11:48:13 03:08:12 99.8 552384 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57586    1 R user01   11:48:13 03:08:16 99.8 552244 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57587    1 R user01   11:48:13 03:08:15 99.8 555908 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57588    1 R user01   11:48:13 03:08:17 99.8 556708 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
Total: 21 processes and 25 threads
```

Compute node OS and firmware updates
------------------------------------

This procedure requires [ClusterShell](https://wiki.fysik.dtu.dk/niflheim/SLURM#clustershell).

Assume that you want to update OS and firmware on a specific set of nodes defined as ```<nodelist>```.
It is recommended to update entire partitions, or the entire cluster, at a time in order to avoid having inconsistent node states in the partitions.

First configure the ```update.sh``` script so that it will perform the required OS and firmware updates for your specific partitions.

Then copy the ```update.sh``` file to the compute nodes:
```
clush -bw <nodelist> --copy update.sh --dest /root/
```

On the compute nodes append this crontab entry:
```
clush -bw <nodelist> 'echo "@reboot root /bin/bash /root/update.sh" >> /etc/crontab'
```

Then set the nodes to make an automatic reboot (via Slurm)
as soon as they become idle (ASAP, see the ```scontrol``` manual page) 
and change the node state to ```DOWN``` with:
```
scontrol reboot ASAP nextstate=DOWN reason=UPDATE <nodelist>
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

