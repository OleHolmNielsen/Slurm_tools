Slurm node and batch job status
-------------------------------

Print the current node status and batch jobs status broken down into userids.

Can also display per-user or per-group status.  A partition may be selected.

The maximum username length may be changed in the script:
* export maxlength=11

Usage
-----

```
Usage: ./showuserjobs [-u username] [-a account] [-p partition] [-A] [-h]
where:
        -u username: Print only user <username>
        -a account: Print only jobs in Slurm account <account>
	-A: Print only ACCT_TOTAL lines
	-C: Print comma separated lines for Excel
        -p partition: Print only jobs in partition <partition-list>
        -r: Print additional job Reason columns
        -h: Print this help information
```

Example output
--------------

```
$ showuserjobs 
Batch job status at Tue Nov 20 15:26:49 CET 2018
 
Node states summary:
alloc     783 nodes (10472 CPUs)
idle        2 nodes (40 CPUs)
mix        17 nodes (272 CPUs)
Total     802 nodes (10784 CPUs)

Job summary: 4132 jobs total (max=20000) in all partitions.
 
            Runnin            Idle                   
Username      Jobs   CPUs     Jobs   CPUs  Account   Further info
=========== ====== ======   ====== ======  ========  =============================
GRAND_TOTAL    470  10599     3662 106834  ALL       Running+Idle=117433 CPUs, 53 users
ACCT_TOTAL     304   4824     2753  88217  camdvip   Running+Idle=93041 CPUs, 12 users
ACCT_TOTAL      55   1576      121   2932  ecsvip    Running+Idle=4508 CPUs, 11 users
user01         150   1200       51    442  camdvip   User name 1
user02           4   1152      112  31712  camdvip   User name 2
...
```
