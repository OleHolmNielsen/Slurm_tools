Slurm node and batch job status
-------------------------------

Print the current node status and batch jobs status broken down into userids.

Can also display per-user or per-account status.  A partition may be selected.

Usage
-----

```
Usage: showuserjobs [-u username] [-a account] [-p partition] [-P] [-q QOS] [-A] [-C] [-h]
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
Batch job status at Wed Nov 21 09:10:34 CET 2018
 
Node states summary:
mix        19 nodes (288 CPUs)
alloc     759 nodes (10280 CPUs)
drng        1 nodes (16 CPUs)
idle       23 nodes (200 CPUs)
Total     802 nodes (10784 CPUs)

Job summary: 3092 jobs total (max=20000) in all partitions.
 
Username/            Runnin            Idle         
Totals      Account    Jobs   CPUs     Jobs   CPUs  Further info
=========== ======== ====== ======   ====== ======  =============================
GRAND_TOTAL ALL         379  10498     2713  95305  Running+Idle=105803 CPUs, 46 users
ACCT_TOTAL  camdvip     214   4406     2301  81335  Running+Idle=85741 CPUs, 11 users
ACCT_TOTAL  ecsvip       51   1516       91   2264  Running+Idle=3780 CPUs, 8 users
user01      camdvip       8   1200       47   6384  Full name 1
user02      camdvip       6   1166      101  28824  Full name 2
...
```
