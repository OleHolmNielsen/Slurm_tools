The Slurm tool "showpartitions"
-------------------------------

Print a Slurm cluster partition status overview with 1 line per partition.

Author: Ole Holm Nielsen <Ole.H.Nielsen \at/ fysik.dtu.dk>

Usage
-----

```
Usage: ./showpartitions [-p partition] [-g] [-m] [-a] [-h]
where:
	-p partition: Print only jobs in partition <partition-list>
	-g: Print also GRES information
	-m: Print minimum and maximum values for memory and cores/node.
	-a: Display information about all partitions including hidden ones.
	-h: Print this help information

```

Example output:

```
$ showpartitions 
Partition statistics for cluster niflheim at Thu Jul 11 11:45:29 CEST 2019
      PARTITION      #CORES      #NODES  #CORES_PEND   JOB_NODES MAXJOBTIME CORES     NODE
      NAME STATE  FREE TOTAL  FREE TOTAL RESRC OTHER   MIN   MAX  DAY-HR:MN /NODE   MEM/GB
    xeon8*    up    66  1664     7   208  2690  1217     1 infin    7-00:00     8      23+
  xeon8_48    up    16   176     2    22     0     0     1 infin    7-00:00     8      47 
    xeon16    up    16  2528     1   158  5024   224     1 infin    7-00:00    16      64+
xeon16_128    up    16  1312     1    82     0     0     1 infin    7-00:00    16     128+
xeon16_256    up    16   416     1    26     0     0     1 infin    7-00:00    16     256 
    xeon24    up     0  4608     0   192 18072 15936     1 infin    2-02:00    24     256+
xeon24_512    up     0   288     0    12   144  1344     1 infin    2-02:00    24     512 
    xeon40   up@     0  7680     0   192 16360   560     1 infin    2-02:00    40     384+
xeon40_768   up@     0   480     0    12   200 13440     1 infin    2-02:00    40     768 

```

Some Slurm flags shown are:

1. A \* after the partition ```name``` identifies the default Slurm partition.
2. A @ after the partition ```state``` means that some nodes are pending a reboot.

History
-------

The showpartitions tool was inspired by the excellent tool ```spart```, see https://github.com/mercanca/spart
