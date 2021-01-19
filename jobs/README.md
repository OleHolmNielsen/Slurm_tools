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
$ psjob  3378173_124
JOBID     TASKS USER      ARRAY_JOB_ID ARRAY_TASK_ID START_TIME          TIME          TIME_LIMIT    
3378599   16    user01    3378173      124           2021-01-18T11:48:10 3:05:07       15:00:00      
NODELIST: g012
---------------
g012
---------------
  PID NLWP S USER      STARTED     TIME %CPU   RSS COMMAND
57532    1 S user01   11:48:10 00:00:00  0.0  2432 /bin/bash /var/spool/slurmd/job3378599/slurm_scri
57550    1 S user01   11:48:12 00:00:00  0.0 42532 python run_vasp.py
57556    1 S user01   11:48:13 00:00:00  0.0  1672 sh -c srun /home/user01/bin/vasp/5.4.4-intel20
57557    5 S user01   11:48:13 00:00:00  0.0  5872 srun /home/user01/bin/vasp/5.4.4-intel2019/bin
57558    1 S user01   11:48:13 00:00:00  0.0   836 srun /home/user01/bin/vasp/5.4.4-intel2019/bin
57573    1 R user01   11:48:13 03:04:46 99.8 579552 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57574    1 R user01   11:48:13 03:04:41 99.7 562172 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57575    1 R user01   11:48:13 03:04:50 99.8 551500 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57576    1 R user01   11:48:13 03:04:52 99.8 550996 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57577    1 R user01   11:48:13 03:04:48 99.8 563908 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57578    1 R user01   11:48:13 03:04:52 99.8 554440 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57579    1 R user01   11:48:13 03:04:47 99.8 567204 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57580    1 R user01   11:48:13 03:04:51 99.8 547952 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57581    1 R user01   11:48:13 03:04:51 99.8 553780 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57582    1 R user01   11:48:13 03:04:52 99.8 570144 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57583    1 R user01   11:48:13 03:04:45 99.8 556076 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57584    1 R user01   11:48:13 03:04:51 99.8 543584 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57585    1 R user01   11:48:13 03:04:47 99.8 552348 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57586    1 R user01   11:48:13 03:04:50 99.8 552232 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57587    1 R user01   11:48:13 03:04:50 99.8 555896 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
57588    1 R user01   11:48:13 03:04:52 99.8 556588 /home/user01/bin/vasp/5.4.4-intel2019/bin/vas
Total: 21 processes and 25 threads
```
