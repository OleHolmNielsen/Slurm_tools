Slurm node and batch job status
-------------------------------


The ```showuserjobs``` tool prints the current node status and batch jobs status broken down into userids. 
The tool can also display per-user or per-account status, as well as the reasons why jobs are in a Pending state. 
A partition may be selected as well.

The ```Limit CPUs``` column displays the users' CPU limits from the Slurm database. 
In this way you can quickly judge whether users and accounts are above or below their CPU limits.

Prerequisite: GNU gawk version 4.0 or later is required for handling arrays of arrays.

Usage
-----

```
Usage: showuserjobs [-u username] [-a account] [-p partition] [-P] [-q QOS] [-r] [-A] [-C] [-h]
where:
        -u username: Print only user <username>
        -a account: Print only jobs in Slurm account <account>
	-A: Print only ACCT_TOTAL lines
	-C: Print comma separated lines for Excel
        -p partition: Print only jobs in partition <partition-list>
        -P: Include all partitions, including hidden and unavailable ones
        -q qos-list: Print only jobs in QOS <qos-list>
        -r: Print additional job Reason columns
        -h: Print this help information
```

Example output
--------------

```
$ showuserjobs
Batch job status for cluster niflheim at Mon Jun 28 13:10:22 CEST 2021
 
Node states summary:
allocated    165 nodes ( 21.97%)   5104 CPUs ( 23.89%)
down           5 nodes (  0.67%)    152 CPUs (  0.71%)
drained        2 nodes (  0.27%)     96 CPUs (  0.45%)
draining@    561 nodes ( 74.70%)  15680 CPUs ( 73.38%)
idle          14 nodes (  1.86%)    184 CPUs (  0.86%)
mixed          1 nodes (  0.13%)     80 CPUs (  0.37%)
reboot         3 nodes (  0.40%)     72 CPUs (  0.34%)
Total        751 nodes (100.00%)  21368 CPUs (100.00%)

Job summary: 1393 jobs total (max=20000) in all partitions.
 
Username/            Runnin         Limit Pendin         
Totals      Account    Jobs   CPUs   CPUs   Jobs   CPUs Further info
=========== ======== ====== ====== ====== ====== ====== =============================
GRAND_TOTAL ALL         361  20761    Inf   1032  47809 Running+Pending=68570 CPUs, 46 users
ACCT_TOTAL  ecsvip      123   6600    Inf    238   7064 Running+Pending=13664 CPUs, 12 users
ACCT_TOTAL  camdvip      86   6240    Inf    504  24497 Running+Pending=30737 CPUs, 9 users
ACCT_TOTAL  catvip       52   3472    Inf    111   8736 Running+Pending=12208 CPUs, 7 users
user01      camdvip      30   2352   2000     75   5632 Full name 1
user02      ecsvip       16   1816   2000      1     80 Full name 2
...
```

The *Limit CPUs* column is the GrpTRES cpu limit,
where *Inf* (infinite) indicates that no limit has been set.
