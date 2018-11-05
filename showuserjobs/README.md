Slurm node and batch job status
-------------------------------

Print the current node status and batch jobs status broken down into userids.

Can also display per-user or per-group status.  A partition may be selected.

The maximum username length may be changed in the script:
* export maxlength=11

Usage
-----

```
Usage: ./showuserjobs [-u username | -g groupname] [-p partition] [-G] [-h]
where:
        -u username: Print only user <username> (do not use with the -g flag)
        -g groupname: Print only users in group <groupname>
	-G: Print only GROUP_TOTAL lines
        -C: Print comma separated lines for Excel
        -p partition: Print only jobs in partition <partition-list>
        -h: Print this help information
```

Example output
--------------

```
$ showuserjobs 
Batch job status at Fri Dec 8 12:02:36 CET 2017
 
Node states summary:
alloc     799 nodes (10744 CPUs)
drain       2 nodes (16 CPUs)
idle        2 nodes (40 CPUs)
Total     803 nodes (10800 CPUs)

Job summary: 10616 jobs total in all partitions. Slurm MaxJobCount=20000.
 
            Runnin            Idle                   
Username      Jobs   CPUs     Jobs   CPUs  Group     Further info
=========== ====== ======   ====== ======  ========  =============================
GRAND_TOTAL    917  10744     9699 271324  ALL       Running+Idle=282068 CPUs 42 users
GROUP_TOTAL    110   3136      182   4352  ecsvip    Running+Idle=7488 CPUs 10 users
GROUP_TOTAL    624   3064     7517 214468  camdvip   Running+Idle=217532 CPUs 13 users
GROUP_TOTAL     88   1408      115   1840  ecsstud   Running+Idle=3248 CPUs 3 users
user01          15   1392     1442 176592  camdvip   FullName01
user02          68   1200       71   1216  ecsvip    FullName02
...
```
