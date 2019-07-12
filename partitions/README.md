The Slurm tool "showpartitions"
-------------------------------

Print a Slurm cluster partition status overview with 1 line per partition.

Author: Ole Holm Nielsen <Ole.H.Nielsen \at/ fysik.dtu.dk>

Usage
-----

```
Usage: ./showpartitions [-p partition] [-g] [-m] [-a] [-f] [-h]
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
Partition statistics for cluster niflheim at Fri Jul 12 08:39:22 CEST 2019
      Partition      #Cores       #Nodes    #Cores_pend    Job_Nodes MaxJobTime Cores Mem/Node
      Name State   Idle  Total  Idle Total Resorc  Other   Min   Max  Day-hr:mn /node     (GB)
    xeon8*    up     34   1664     3   208   2626   3950     1 infin    7-00:00     8      23+
  xeon8_48    up      0    176     0    22      0      0     1 infin    7-00:00     8      47 
    xeon16    up     96   2528     6   158   4896   1376     1 infin    7-00:00    16      64+
xeon16_128    up     64   1312     4    82      0      0     1 infin    7-00:00    16     128+
xeon16_256    up      0    416     0    26      0      0     1 infin    7-00:00    16     256 
    xeon24    up     48   4608     2   192  17208  15576     1 infin    2-02:00    24     256+
xeon24_512    up     48    288     2    12    192   1344     1 infin    2-02:00    24     512 
    xeon40   up@    120   7680     3   192  12960   1560     1 infin    2-02:00    40     384+
xeon40_768    up      0    480     0    12   7280      0     1 infin    2-02:00    40     768 

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

The showpartitions tool was inspired by the excellent tool ```spart```, see https://github.com/mercanca/spart,
and has more or less the same functionality.
