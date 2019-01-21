Slurm node scripts
------------------

Some convenient scripts for working with nodes (or lists of nodes):

* Drain a node-list: ```sdrain node-list "Reason"```.
* Resume a node-list: ```sresume node-list```.
* Do a ```ps``` process status on a node-list, but exclude system processes: ```psnode node-list```.
* Print Slurm version on a node-list: ```sversion node-list```. Requires [ClusterShell](https://clustershell.readthedocs.io/en/latest/intro.html).
* Check consistency of /etc/slurm/topology.conf with nodelist in /etc/slurm/slurm.conf: ```checktopology```


Usage
-----

Copy these scripts to /usr/local/bin/.
If necessary configure the variables in the script.

Example output from ```psnode```:

```
# psnode a058
Node a058:
Thu Jul 20 12:40:36 2017
NODELIST   NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON              
a058           1    xeon8*       mixed    8    2:4:1  23900    32752      1 xeon5570 none                
  PID S USER      STARTED     TIME %CPU   RSS COMMAND
 1213 S user01   20:27:07 00:00:00  0.0  1684 /bin/bash /var/spool/slurmd/job127132/slurm_script
 1490 S user01   20:27:13 00:00:00  0.0  4956 srun --mpi=pmi2 -n 1 fasttube
 1492 S user01   20:27:15 00:00:00  0.0   672 srun --mpi=pmi2 -n 1 fasttube

```
