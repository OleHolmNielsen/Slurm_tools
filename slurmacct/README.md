Slurm accounting report tools
-----------------------------

Generate top user and group accounting statistics from Slurm as a supplement to the
[sreport](https://slurm.schedmd.com/sreport.html) command,
allowing much more flexibility in the reports.

The tools are:

```
slurmacct
topreports
jobstats
```

slurmacct tool
--------------

Specific start and end Time/Date for the report may be selected.
The default period is the last full month.

The ```-c``` option selects the current month until today, and ```-w``` selects the last week.

A specific user, group or node partition may be selected.

Output lines are sorted in order of decreasing usage, so it's easy to identify top users and groups.

The [sreport](https://slurm.schedmd.com/sreport.html) command can show a top user report:
```
sreport user top start=0101 end=0110 TopCount=50 -t hourper --tres=cpu,gpu
```
but there are some advantages of ```slurmacct```  over the [sreport](https://slurm.schedmd.com/sreport.html) command:

* Partition specific accounting is possible.
* Average CPU count (job parallelism) is printed.
* Average waiting time in the queue is printed (answer to "My jobs wait for too long").
* User full name is printed (useful to managers).

The list of command options are:
```
Usage: slurmacct [-C|-T|-N] [-s Start_time -e End_time | -c | -y | | -w | -m monthyear | -Y yyyy ] [-p partition(s)] [-u username] [-g groupname] [-G | -P ] [-W workdir] [-r report-prefix] [-n] [-h]
where:
        -C: Print CPU usage (Default option)
        -T: Print Trackable resource (TRES) GPU usage in stead of CPU usage
        -N: Print NODE usage in stead of CPU usage
        -s Start_time [last month]: Starting time of accounting period.
        -e End_time [last month]: End time of accounting period.
        -c: Current month
        -y: Current year
        -w: Last week
        -m monthyear: Select month and year (like "november2019")
        -Y yyyy: Select the entire year yyyy (like "2025")
        -p partition(s): Select only Slurm partion <partition>[,partition2,...]
        -u username: Print only user <username> 
        -g groupname: Print only users in UNIX group <groupname>
        -G: Print only groupwise summed accounting data
        -P: Print only Parent group summed accounting data
        -W directory: Print only jobs with this string in the job WorkDir
        -r: Report name prefix
        -n: No header information is printed (append to existing report)
        -h: Print this help information
```

The ```Start_time``` and ```End_time``` values select the date/time interval of
job completion/termination (see ```man sacct```).
Hint: Specify ```Start_time``` and ```End_time``` as ```MMDD``` (Month and Date).

Example
-------

```
$ slurmacct -s 1201 -e 1231 -p xeon40el8
 - Start date 1201
 - End date 1231
 - Print only accounting in Slurm partition xeon40el8
 - Print CPU usage (default option)
Report generated to file /tmp/Slurm_report_acct_1201_1231
```
The generated report file contains:
```
CPU usage report by USERS

 - Partition(s) selected: xeon40el8

Usage sorted by top users:
                                         Wallclock           Energy Average Average
Username        Group(parent)    #jobs   cpus-hrs   Percent    kWh   #cpus  q-hours    Full name
--------        -------------  ------- -----------  ------- ------- ------- -------  ---------
   TOTAL                (All)    22812   7597623.0   100.00   89757   52.82   17.39  Number of users: 81
   user1        camdvip(camd)      402    792609.3    10.43   10181  120.00  347.77  Fullname 1
   user2    ecsvip(batteries)     1689    774121.1    10.19    8713   40.00   17.57  Fullname 2
   user3    ecsvip(batteries)      388    618520.5     8.14    6742   40.00  100.74  Fullname 3
  ...
```

topreports tool
---------------

The ```topreports``` tool uses ```slurmacct``` to generate specific reports for specified periods,
and for all the partitions configured in the script.

The ```topreports``` tool may be executed daily via ```crontab``` to provide updated weekly and monthly reports,
and it can also be run with ```-Y``` for annual reports.

```
Usage: topreports [-m monthyear] | -Y yyyy ] [-r report-prefix] [-h]
where:
        -m: Select periods: month and year (like "november2024"), see slurmacct
            Default periods: last-month, current-month, current-week, and current-year 
        -Y: Select an entire year yyyy (like 2025)
        -r: Report name prefix (Default PREFIX=/tmp/Top)
        -h: Print this help information
```

You should configure some items in the script:

* Partition list: overlapping partitions are comma-separated so they will be reported together.
* Directory and report file name prefix: ```PREFIX``` or use the option ```[-r report-prefix]```.

Note: Since the ```topreports``` tool prints **Slurm parent accounts** when using  the option ```slurmacct -P```,
use of this option requires the Slurm accounts **PARENTFILE** ```/etc/slurm/accounts.conf```.
The **PARENTFILE** can be conveniently generated by the ```slurmaccounts2conf``` tool
from [Slurm accounts and users](../slurmaccounts/) which dumps all Slurm associations in the required format.

jobstats tool
-------------

The ```jobstats``` tool prints information for all jobs using Slurm sacct accounting records.
One line per jobs is printed,
and this may be used as input to other tools which produce Slurm statistics.
The output is a Tab-separated .csv file.

```
Usage: jobstats [-s Start_time -e End_time | -c | -w | -m monthyear] [-p partition(s)] [-r report-prefix] [-n] [-h]
where:
	-s Start_time [last month]: Starting time of accounting period.
	-e End_time [last month]: End time of accounting period.
	-c: Current month
	-w: Last week
	-m monthyear: Select month and year (like "november2019")
	-p partition(s): Select only Slurm partion <partition>[,partition2,...]
	-r: Report name prefix
	-h: Print this help information

The Start_time and End_time values specify the date/time interval of
job completion/termination (see "man sacct").

Hint: Specify Start/End time as MMDD (Month and Date)
```
The output contains 1 line per job like in this example:

```
JobID   user    ncpus   wall    nodes   ngpus
4110745 user001 8       123.993 1       1
4111047 user001 8       95.720  1       1
...
```
