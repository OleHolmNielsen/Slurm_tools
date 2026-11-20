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

* [jobeff](jobeff) Print the CPU, memory and GPU efficiency of a completed or running job: ```jobeff [-h | -d] <jobid>```.
  See [Job CPU and GPU accounting](#job-cpu-and-gpu-accounting) below.

* [jobmail](jobmail) Slurm ```MailProg``` which adds a ```jobeff``` job efficiency report to the E-mail notifications from ``slurmctld`` when a job has ended.

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

Job CPU and GPU accounting
--------------------------

* The [jobeff](jobeff) script prints the CPU, memory and GPU efficiency of a completed or running job.
* The [jobmail](jobmail) script provides E-mail notifications from ``slurmctld`` to users,
  and adds a ``jobeff`` job efficiency report to the mail body when a job has ended.

These tools are alternatives to the ``smail`` and ``seff`` scripts from the ``slurm-contribs`` package,
and they furthermore provide GPU accounting statistics.

### jobeff

Usage:
```
jobeff [Options] <Jobid>
       Options:
       -h    Help menu
       -d    Debug mode: display raw Slurm data
```

The job efficiency data are read from the Slurm database with ``sacct``.
For a running job, the statistics so far are printed, and the job steps still running are read with ``sstat``.
The report contains:

* Job ID, Array Job ID (for array tasks), Job SLUID, cluster, partition, node list, user/group and job state with exit code.
* Submit, start and end times, and the elapsed time.
* Number of nodes and cores per node.
* CPU time used and CPU efficiency relative to the core-walltime.
* Memory used and memory efficiency relative to the allocated memory (per core or per node).
  The memory request type is read from ``sacct --json`` and requires the [jq](https://jqlang.org/) tool;
  without ``jq`` the memory is assumed to be allocated per node.
* GPU utilization and GPU memory (min/max/average), if the job was allocated GPUs (see the NOTE below).
  A warning is printed if the max or average GPU utilization is below 10% (the ``gpu_util_threshold`` variable in ``jobeff``).
* The energy consumed by the job in Joules and kWh, if Slurm has measured it (the ``energy`` field of the job's ``AllocTRES``).

The exit code of ``jobeff`` is 0 on success, 1 for usage errors, 2 if the job was not found
or ``sacct`` failed (for example when the Slurm database is not responding), and 4 if the job has not started yet.

Example output from ```jobeff```:

```
Efficiency report for Slurm job 11293137
========================================

Parameter           Value
---------           -----
Job ID:             11293137
Job SLUID:          s8FXM7QBF5ED00
Cluster:            niflheim
Partition:          a100el9
NodeList:           sd653
User/Group:         user1/group1
State:              COMPLETED (exit code 0)
Submit time:        2026-11-18T13:52:14
Start time:         2026-11-18T13:52:32
Elapsed time:       00:00:10
End time:           2026-11-18T13:52:42
Nodes:              1
Cores per node:     32
CPU Utilized:       00:00:00
CPU Efficiency:     0.00% of 00:05:20 core-walltime
Memory Utilized:    19.85 MB
Memory Efficiency:  0.06% of 31.25 GB (1000.00 MB/core)
GPU AllocTRES:      billing=128,cpu=32,energy=10218,gres/gpu:a100=1,gres/gpu=1,mem=32000M,node=1
GPU utilization:    min 0%, max 0%, avg 0% (gres/gpu=1)
Warning:            The max or avg GPU utilization is below 10%:
                    the job seems not to use the allocated GPUs efficiently
GPU memory:         min 0, max 0, avg 0 (MB) (gres/gpu=1)
Energy consumed:    10218 J (0.00284 kWh)
```

The SLUID (Slurm Lexicographically-sortable Unique ID) job field was added in Slurm 24.11.

### jobmail

``slurmctld`` calls the ``MailProg`` as ``<MailProg> -s "<subject>" <recipient>``
for the job events requested by the user with ``sbatch --mail-type``.
The ``jobmail`` script sends the mail with ``/bin/mail``.
When the job has ended (the subject contains an ending state such as COMPLETED, FAILED or TIMEOUT),
``jobmail`` waits a few seconds (``JOB_COMPLETION_TIME``) for the accounting data to be committed to ``slurmdbd``,
and then puts the ``jobeff`` report of the job (or array task) in the mail body.
Other mails, such as job start notifications, are sent without a report.

Installation:
Copy the [jobeff](jobeff) and [jobmail](jobmail) scripts to `/usr/local/bin/`,
where they must be readable and executable by the ``SlurmUser``.
``jobmail`` runs ``jobeff`` from `/usr/local/bin/`.
Configure ``jobmail`` in ``slurm.conf``:
```
MailProg=/usr/local/bin/jobmail
```
and reconfigure ``slurmctld`` (``scontrol reconfigure``).

NOTE: In order for the Slurm database to record GPU usage information,
it is required that Slurm has been built with the NVIDIA 
[NVML](https://developer.nvidia.com/management-library-nvml) library.
The details of configuring Slurm with [NVML](https://developer.nvidia.com/management-library-nvml) 
are discussed in the Wiki page
[NVIDIA NVML library and GPU GRES](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_installation/#nvidia-nvml-library-and-gpu-gres).
