Slurm accounting report tool
----------------------------

Generate accounting statistics from Slurm as an alternative to the ```sreport``` command.

Specific start and end Time/Date must be specified.

A specific user, group or node partition may be specified.

There are some advantages of ```slurmacct```  over the ```sreport``` command:

* Partition specific accounting is possible.

* Average CPU count (job parallelism) is printed.

* Average waiting time in the queue is printed (answer to "My jobs wait for too long").

* User full name is printed (useful to managers).

Usage
-----

```
Usage: slurmacct -s Start_time -e End_time [-p partition(s)] [-u username] [-g groupname] [-G]
where:
        -s Start_time: Starting time of accounting period.
        -e End_time: End time of accounting period.
        -p partition: Select only Slurm partion <partition>
        -u username: Print only user <username> 
        -g groupname: Print only users in UNIX group <groupname>
        -G: Print only groupwise summed accounting data
        -h: Print this help information

The Start_time and End_time values specify the date/time interval of
job completion/termination (see "man sacct").

Hint: Specify Start/End time as MMDD (Month and Date)
```

Time/Date format: MMDD (Month-Day)


Example
-------

```
$ slurmacct -s 1201 -e 1231 -p xeon8

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