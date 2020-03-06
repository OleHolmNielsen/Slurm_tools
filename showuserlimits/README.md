Print Slurm resource user limits and usage
==========================================

It is very useful to view a Slurm user's resource limits and current usage.
For example, jobs may be blocked because some resource limit gets exceeded,
and it is important to analyze why this occurs.

Several Slurm commands such as ```sshare``` and ```sacctmgr``` can print a number of user limits,
and to a lesser extent the user's current usage, however, their capabilities are very limited.

The ```showuserlimits``` tool fills this need by inquiring the Slurm database 
about all available user and association limits and current usages.
The amount of information in the database is quite extensive,
so the ```showuserlimits``` tool allows filtering the data 
and print only the desired information.

The ```showuserlimits``` tool is used by the ```showjob``` command available
from the scripts for managing [jobs](../jobs/).

The complete list of group limits (```GrpTRESMins```, ```GrpTRESRunMins```, etc.)
are documented in the ```sacctmgr``` manual page https://slurm.schedmd.com/sacctmgr.html#lbAI.
The ```TRES``` (*Trackable RESources*) are resources that can be tracked for usage or used to enforce limits against,
and are documented in the page https://slurm.schedmd.com/tres.html.

showuserlimits tool
-------------------

This tool prints out the Slurm associations limits and current usage values for a user.
Data is extracted from the Slurm database using the ```scontrol show assoc_mgr``` command,
for which there exists almost no documentation or examples.

By default the current user in its default account is printed including
every available limit and current value from the Slurm database.
Specific limits (such as ```GrpTRESRunMins```) and even sub-limits (such as ```cpu```) may be selected if desired.

Usage:

```
Usage: showuserlimits [-u username [-A account] [-p partition] [-M cluster] [-l limit] [-s sub-limit] [-n] | -h ]
where:
        -u username: Print user <username> (Default is current user)
        -A accountname: Print only account <accountname>
        -p partition: Print only Slurm partition <partition>
        -M cluster: Print only cluster <cluster>
        -l Print selected limits only
        -s Print selected sub-limits only
	-n Print also limits with value None
        -h Print help information
```

A typical use case is to inquire about a certain limit, for example,
```GrpTRESRunMins``` and possibly sub-limits such as the ```cpu``` field:

```
showuserlimits -u username -l GrpTRESRunMins
showuserlimits -u username -l GrpTRESRunMins -s cpu
```

The output may look like this example:

```
$ showuserlimits -u xxx -l AssocGrpCPURunMinutesLimit -s cpu
Association (Parent account):
	   ClusterName = 	niflheim
	       Account = 	camdvip
	      UserName = 	None, current value = Parent account
	     Partition = 	None, current value = Any partition
	GrpTRESRunMins = 
		     cpu:	Limit = None, current value = 11384718

Association (User):
	   ClusterName = 	niflheim
	       Account = 	camdvip
	      UserName = 	xxx, UID=222176
	     Partition = 	None, current value = Any partition
	GrpTRESRunMins = 
		     cpu:	Limit = 4000000, current value = 3987608
```

If the user has multiple associations with different partitions or clusters, 
it is useful to narrow down the listings to a particular partition or cluster,
for example:

```
showuserlimits -u username -l GrpTRESRunMins -p xeon24
showuserlimits -u username -l GrpTRESRunMins -s cpu -p xeon24
```

