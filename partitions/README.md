The Slurm tool "showpartitions"
-------------------------------

Print a Slurm cluster partition status overview with 1 line per partition.

Author: Ole Holm Nielsen <Ole.H.Nielsen \at/ fysik.dtu.dk>

Usage
-----

```
Usage: showpartitions [-p partition(s)] [-g]
where:
        -p partition: Select only partition <partition>
	-g: Print also GRES (Generic Resources)
```

Example output:

```
$ showpartitions 
Partition statistics for cluster niflheim at Wed Jul 10 10:45:23 CEST 2019
        PARTITION      FREE    TOTAL     FREE    TOTAL    #CPUS   #OTHER   MIN   MAX  MAXJOBTIME   CORES     NODE
        NAME STATE    CORES    CORES    NODES    NODES   PENDNG   PENDNG     NODES     DAY-HR:MN   /NODE   MEM(GB)
      xeon8*   up@       80     1664        9      208        0        0     1 infin     7-00:00       8       23+
    xeon8_48   up@       24      176        3       22        0        0     1 infin     7-00:00       8       47 
      xeon16    up        0     2528        0      158     4560        0     1 infin     7-00:00      16      256 
  xeon16_128    up        0     1312        0       82        0       32     1 infin     7-00:00      16      256 
  xeon16_256    up        0      416        0       26        0        0     1 infin     7-00:00      16      256 
      xeon24    up       24     4608        1      192    24360    16968     1 infin     2-02:00      24      256 
  xeon24_512    up        0      288        0       12        0     1344     1 infin     2-02:00      24      512 
      xeon40    up      280     7680        7      192    15800     1000     1 infin     2-02:00      40      768 
  xeon40_768    up      280      480        7       12    19680        0     1 infin     2-02:00      40      768 
```

Some Slurm flags shown are:

1. A \* after the partition ```name``` identifies the default Slurm partition.
2. Long partition names will be truncated, and the last character is changed to a ```+```. See also ```maxlength``` below.
3. A @ after the partition ```state``` means that some nodes are pending a reboot.

Note: You may change the maximum length of partition names in this script line:

```
export maxlength=12
```

History
-------

The showpartitions tool was inspired by the excellent tool ```spart```, see https://github.com/mercanca/spart
