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
Partition statistics for cluster niflheim at Wed Jul 10 20:31:50 CEST 2019
        PARTITION       #CORES          #NODES      #CORES_PENDING   JOB_NODES  MAXJOBTIME   CORES     NODE
        NAME STATE    FREE   TOTAL    FREE   TOTAL  RESOUR   OTHER   MIN   MAX   DAY-HR:MN   /NODE   MEM/GB
      xeon8*    up      30    1664       2     208    3026    1415     1 infin     7-00:00       8       23
    xeon8_48    up       0     176       0      22       0       0     1 infin     7-00:00       8       47
      xeon16    up       0    2528       0     158    5568      16     1 infin     7-00:00      16      256
  xeon16_128    up       0    1312       0      82       0       0     1 infin     7-00:00      16      256
  xeon16_256    up       0     416       0      26       0       0     1 infin     7-00:00      16      256
      xeon24    up      24    4608       1     192   21360   17448     1 infin     2-02:00      24      512
  xeon24_512    up      24     288       1      12      48    1344     1 infin     2-02:00      24      512
      xeon40    up     200    7680       5     192   16680     560     1 infin     2-02:00      40      384
  xeon40_768    up       0     480       0      12   17280       0     1 infin     2-02:00      40      768
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
