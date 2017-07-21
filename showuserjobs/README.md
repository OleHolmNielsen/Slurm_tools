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
        -p partition: Print only jobs in partition <partition-list>
        -h: Print this help information
```

Example output
--------------

```
$ showuserjobs 
Slurm node and job status at Tue Jul 4 15:10:14 CEST 2017
 
Node states summary:
drng        1 nodes (8 CPUs)
alloc     629 nodes (9328 CPUs)
Total     630 nodes (9336 CPUs)

             Running       Pending    
Username    Jobs  CPUs   Jobs  CPUs  Group     Further info
========    ==== =====   ==== =====  ========  =============================
GRAND_TOTAL  404  9336    371 13632  ALL       running+pending=22968 CPUs 34 users
GROUP_TOTAL  285  4848    217  3056  ecsvip    running+pending=7904 CPUs 9 users
GROUP_TOTAL   31  1872    103  8176  camdvip   running+pending=10048 CPUs 7 users
user01       141  1872     11   480  ecsvip    FullName01
user02       111  1488    205  2544  ecsvip    FullName02
...
```
