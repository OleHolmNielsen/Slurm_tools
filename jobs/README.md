Slurm job scripts
-----------------

Some convenient scripts for managing Slurm jobs:

* ```psjob```: Do a ```ps``` process status on a job's node-list, but exclude system processes: ```psjob [-c columns | -h] <jobid>```.
  Requires [ClusterShell](https://clustershell.readthedocs.io/en/latest/intro.html).

* ```showjob```: Show status of Slurm job(s). Both queue information and accounting information is printed.

* ```jobqos```: Set Quality of Service (QOS) of jobs, or list jobs with the given QOS.

* ```jobnice```: Add nice level to jobs, or list jobs with non-zero nice level.

* ```jobtimelimit```: Update timelimit of job(s).

* ```sbadjob```: Print a warning about bad jobs hanging indefinitely in the queue.

* ```notifybadjob```: Notify about or Kill a badly behaving job and send information mail to the user.

* ```joblist```: Handy utility for converting jobids to a comma-separated list when the input may be separated by spaces or in a multi-line file.

* ```warn_maxjobs```: Issue warnings about the number of Slurm jobs approaching MaxJobCount

* ```schedjobs```: Stop or start job scheduling in ALL Slurm partitions

Usage
-----

Copy these scripts to /usr/local/bin/.
If necessary configure the variables in the script.

The ```warn_maxjobs``` and ```sbadjob``` may be run regularly from crontab, for example:

```
5 * * * * /usr/local/bin/warn_maxjobs; /usr/local/bin/sbadjobs
```

Examples
--------

Example output from ```psjob```:

```
JOBID     TASKS USER      START_TIME          TIME          TIME_LIMIT    
3381322   1     user1     2021-01-19T22:42:23 10:16:01      2-00:00:00    
NODELIST: d064
---------------
d064
---------------
  PID NLWP S USER      STARTED     TIME %CPU   RSS COMMAND
27673    1 S user1    22:42:27 00:00:00  0.0  1372 /bin/bash -l /var/spool/slurmd/job3381322/slurm_s
27675    3 R user1    22:42:27 10:15:35 99.9 242464 python3 /home/user1/wlda/atomic_benchma
27676    5 S user1    22:42:27 00:00:00  0.0 15132 orted --hnp --set-sid --report-uri 8 --singleton-
Total: 3 processes and 9 threads
Uptime: 08:58:25 up 8 days, 12:01,  0 users,  load average: 2.01, 2.02, 2.04
```
