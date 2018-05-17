Slurm job scripts
-----------------

Some convenient scripts for managing Slurm jobs:

* ```psjob```: Do a ```ps``` process status on a job's node-list, but exclude system processes: ```psjob <jobid>```.
  Requires [ClusterShell](https://clustershell.readthedocs.io/en/latest/intro.html).

* ```showjob```: Show status of Slurm job(s). Both queue information and accounting information is printed.

* ```sbadjob```: Print a warning about bad jobs hanging indefinitely in the queue.

* ```notifybadjob```: Notify about or Kill a badly behaving job and send information mail to the user.

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
# psjob  126528
Nodelist for job-id 126528: a[003,018,022-026,047]
Node usage: NumNodes=8 NumCPUs=64 NumTasks=64 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   RunTime=1-03:27:18 TimeLimit=2-00:00:00 TimeMin=N/A
   SubmitTime=2017-07-19T10:46:42 EligibleTime=2017-07-19T10:46:42
   StartTime=2017-07-19T11:28:12 EndTime=2017-07-21T11:28:12 Deadline=N/A
---------------
a003
---------------
  PID S USER      STARTED NLWP     TIME %CPU   RSS COMMAND
17113 S user01     Jul 19    1 00:00:00  0.0  1860 /bin/bash -l /var/spool/slurmd/job126528/slurm_sc
17219 S user01     Jul 19    2 00:00:00  0.0  3872 mpiexec gpaw-python res.py
17221 S user01     Jul 19    5 00:00:00  0.0  5276 srun --ntasks-per-node=1 --kill-on-bad-exit --cpu
17222 S user01     Jul 19    1 00:00:00  0.0   672 srun --ntasks-per-node=1 --kill-on-bad-exit --cpu
17241 R user01     Jul 19    2 1-03:25:45 99.9 605044 gpaw-python res.py
17242 R user01     Jul 19    2 1-03:25:52 99.9 827892 gpaw-python res.py
17243 R user01     Jul 19    2 1-03:25:43 99.9 747220 gpaw-python res.py
17244 R user01     Jul 19    2 1-03:25:54 99.9 609900 gpaw-python res.py
17245 R user01     Jul 19    2 1-03:25:47 99.9 599428 gpaw-python res.py
17246 R user01     Jul 19    2 1-03:25:55 99.9 826440 gpaw-python res.py
17247 R user01     Jul 19    2 1-03:25:49 99.9 751420 gpaw-python res.py
17248 R user01     Jul 19    2 1-03:25:48 99.9 609428 gpaw-python res.py
...

```
