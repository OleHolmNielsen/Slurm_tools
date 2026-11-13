Slurm job scripts
-----------------

Some convenient scripts for managing Slurm jobs:

* [psjob](psjob) ```ps``` process status on a job's node-list, but exclude system processes: ```psjob [-c columns | -h] <jobid>```.
  Requires [ClusterShell](https://clustershell.readthedocs.io/en/latest/intro.html).
  The scratch disk usage with Slurm *job_container/tmpfs* (if configured) is printed.
  GPU usage may also be printed.

* [showjob](showjob) Show status of Slurm job(s). Both queue information and accounting information is printed.

* [showjobreasons](showjobreasons) Show list of non-resource reasons for pending jobs, such as AssocGrpCpuLimit and AssocGrpNodeLimit

* [jobqos](jobqos) Set Quality of Service (QOS) of jobs, or list jobs with the given QOS.

* [jobnice](jobnice) Add nice level to jobs, or list jobs with non-zero nice level.

* [jobtimelimit](jobtimelimit) Update timelimit of job(s).

* [sbadjob](sbadjob) Print a warning about bad jobs hanging indefinitely in the queue.

* [notifybadjob](notifybadjob) Notify about or Kill a badly behaving job and send information mail to the user.

* [joblist](joblist) Handy utility for converting jobids to a comma-separated list when the input may be separated by spaces or in a multi-line file.

* [warn_maxjobs](warn_maxjobs) Issue warnings about the number of Slurm jobs approaching MaxJobCount

* [schedjobs](schedjobs) Stop or start job scheduling in ALL Slurm partitions

GPU monitoring
--------------

The ```psjob``` script can also monitor the job's GPU usage using the ```gpustat``` tool from https://github.com/wookayin/gpustat.
If the the job uses ```gres/gpu``` on nodes with GPUs, the ```gpustat``` tool is used to display GPU usage.
If ```gpustat``` isn't installed, set the variable ```enable_gpustat=0``` in the ```psjob``` script.

All GPU nodes should have this tool installed.
On EL8 systems:
```
dnf install gcc python3 python3-pip python3-devel
python3 -m pip install setuptools-scm
python3 -m pip install gpustat 
```

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

GPU accounting
--------------

The [seff](https://docs.hpc.shef.ac.uk/en/latest/referenceinfo/scheduler/SLURM/Common-commands/seff.html) script
from the ``slurm-contribs`` RPM package can be used together with the
[smail](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_configuration/#e-mail-notification-setup) script
to provide E-mail notifications to users about job efficiency.

However, no GPU usage statistics is reported by [seff](https://docs.hpc.shef.ac.uk/en/latest/referenceinfo/scheduler/SLURM/Common-commands/seff.html).
We offer here a script [seffgpu](seffgpu) which prints GPU usage of a job (completed or running).
This can be integrated with a slightly modified [smail](smail) script to combine reports from ``seff`` and ``seffgpu``.

In order for the Slurm database to record GPU usage information,
it is required that Slurm has been built with the NVIDIA 
[NVML](https://developer.nvidia.com/management-library-nvml) library.
The details of configuring Slurm with [NVML](https://developer.nvidia.com/management-library-nvml) 
are discussed in the Wiki page
[NVIDIA NVML library and GPU GRES](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_installation/#nvidia-nvml-library-and-gpu-gres).
