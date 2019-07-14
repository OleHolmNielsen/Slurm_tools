The Slurm partition tools
-------------------------

Tools for displaying Slurm partition information.

Author: Ole Holm Nielsen <Ole.H.Nielsen \at/ fysik.dtu.dk>

The "showpartitions" tool
-------------------------

Print a Slurm cluster partition status overview with 1 line per partition.

This is really useful for users who want to find out which partitions are lightly or heavily loaded,
so that they can select a partition which will run their jobs sooner.

Usage
-----

```
Usage: showpartitions [-p partition-list] [-g] [-m] [-a] [-f] [-h]
where:
	-p partition: Print only jobs in partition(s) <partition-list>
	-g: Print also GRES information
	-m: Print minimum and maximum values for memory and cores/node.
	-a: Display information about all partitions including hidden ones.
	-f: Show all partitions from the federation if a member of one. Only Slurm 18.08 and newer.
	-h: Print this help information

```

Example output:

```
$ showpartitions 
Partition statistics for cluster niflheim at Sat Jul 13 11:51:44 CEST 2019
      Partition     #Nodes     #CPU_cores  Cores_pending   Job_Nodes MaxJobTime Cores Mem/Node
      Name State Total  Idle  Total   Idle Resorc  Other   Min   Max  Day-hr:mn /node     (GB)
   xeon8:*    up   208     0   1664      2   3290   1399     1 infin    7-00:00     8      23+
  xeon8_48    up    22     0    176      0      0      0     1 infin    7-00:00     8      47
    xeon16    up   158     4   2528     64      0   2240     1 infin    7-00:00    16      64+
xeon16_128    up    82     1   1312     16      0      0     1 infin    7-00:00    16     128+
xeon16_256    up    26     1    416     16      0      0     1 infin    7-00:00    16     256
    xeon24    up   192     7   4608    168  15144  14112     1 infin    2-02:00    24     256+
xeon24_512    up    12     2    288     48     96   1344     1 infin    2-02:00    24     512
    xeon40   up@   192     1   7680     40   7800    960     1 infin    2-02:00    40     384+
xeon40_768    up    12     0    480      0   1440      0     1 infin    2-02:00    40     768
```

The ```Idle``` cores and nodes are those with a Slurm status of *Idle*.

The ```#Cores_pend``` (cores pending) in the ```Resorc``` column correspond to
*Pending* jobs with a Slurm job *Reason* flag of *Resources* or *Priority*,
whereas ```Other``` are pending for other reasons.

Some Slurm flags shown in the ```Partition``` columns are:

1. A \* after the partition ```name``` identifies the default Slurm partition.
2. A @ after the partition ```state``` means that some nodes are pending a reboot.
3. An R after the partition ```name``` identifies a root-only Slurm partition.
4. An H after the partition ```name``` identifies a hidden Slurm partition.

History
-------

The ```showpartitions``` tool was inspired by the excellent tool ```spart```, see https://github.com/mercanca/spart,
and has more or less the same functionality.

The "showhidden" tool
---------------------

Print a Slurm cluster partition status for hidden and root-only partitions.
This information is not easily accessible using the ```sinfo``` command.

Usage
-----

```
Usage: showhidden [sinfo-options]
```
The [sinfo-options] are passed to the sinfo command.
