Slurm accounting report tool
----------------------------

Generate accounting statistics from Slurm as an alternative to the ```sreport``` command.

Specific start and end Time/Date must be specified.

A specific user, group or node partition may be specified.

Usage
-----

```
Usage: slurmacct [-p partition(s)] [-u username] [-g groupname] [-G] Start_time End_time
where:
        -p partition: Select only Slurm partion <partition>
        -u username: Print only user <username> 
        -g groupname: Print only users in UNIX group <groupname>
        -G: Print only groupwise summed accounting data
        -h: Print this help information
The Start_time and End_time values specify the date/time interval of
job completion/termination (see "man sacct").
```

Time/Date format: MMDD (Month-Day)


Example
-------

```
$ slurmacct -p xeon8 1201 1231

Jobs completed/terminated between date/time 1201 and 1231
Partition selected: xeon8
                             Wallclock          Average Average
Username    Group    #jobs       hours  Percent  #cpus  q-hours  Full name
--------    -----  ------- -----------  ------- ------- -------  ---------
   TOTAL    (All)    38189   2511099.3   100.00    0.00   21.60  
  user01   group1      621    492932.0    19.63   16.00   26.16  Name 1
  user02   group2      547    431252.9    17.17   16.00   29.55  Name 2
  user03   group3      423    349400.0    13.91   16.00   74.40  Name 3
  ...
```
