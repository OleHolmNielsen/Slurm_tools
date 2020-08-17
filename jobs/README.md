Slurm job scripts
-----------------

Some convenient scripts for managing Slurm jobs:

* ```psjob```: Do a ```ps``` process status on a job's node-list, but exclude system processes: ```psjob <jobid>```.
  Requires [ClusterShell](https://clustershell.readthedocs.io/en/latest/intro.html).

* ```showjob```: Show status of Slurm job(s). Both queue information and accounting information is printed.

* ```jobqos```: Set Quality of Service (QOS) of jobs, or list jobs with the given QOS.

* ```jobnice```: Add nice level to jobs, or list jobs with non-zero nice level.

* ```jobtimelimit```: Update timelimit of job(s).

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
# psjob  2727657_48
JOBID               ARRAY_JOB_ID        ARRAY_TASK_ID       START_TIME          TIME                TIME_LIMIT
2727706             2727657             48                  2020-08-17T13:27:10 7:55:09             2-02:00:00
NODELIST: a134
---------------
a134
---------------
  PID S USER      STARTED NLWP     TIME %CPU   RSS COMMAND
30018 S user01   13:27:10    1 00:00:00  0.0  1392 /bin/bash /var/spool/slurmd/job2727706/slurm_scri
30059 S user01   13:27:15    5 00:00:00  0.0  5232 srun -n 8 -N 1 gpaw-python run_gpaw.py test
30061 S user01   13:27:15    1 00:00:00  0.0   256 srun -n 8 -N 1 gpaw-python run_gpaw.py test
30076 R user01   13:27:15    1 07:54:42 99.9 3313044 a.out
30077 R user01   13:27:15    1 07:54:58 99.9 3276640 a.out
30078 R user01   13:27:15    1 07:54:59 99.9 3315204 a.out
30079 R user01   13:27:15    1 07:54:59 99.9 3313304 a.out
30080 R user01   13:27:15    1 07:54:53 99.9 3311864 a.out
30082 R user01   13:27:15    1 07:54:53 99.9 3315336 a.out
30083 R user01   13:27:15    1 07:54:58 99.9 3306656 a.out
```
