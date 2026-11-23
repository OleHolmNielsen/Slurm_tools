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

* [jobeff](jobeff) Print the CPU, memory and GPU efficiency of a completed or running job: ```jobeff [-h | -d] [jobid | SLUID]```.
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

Job accounting reports are provided by:

* The [jobeff](jobeff) script prints the CPU, memory, GPU efficiency,
  and energy consumption of a completed or running job.
  This script may be used with the [jobmail](jobmail) script,
  or used by itself on the command line, or used from inside a running Slurm job.
* The [jobmail](jobmail) script provides E-mail notifications from ``slurmctld`` to users,
  and adds a ``jobeff`` job efficiency report to the mail body when a job has ended.

They are drop-in alternatives to the ``smail`` and ``seff`` scripts available from the ``slurm-contribs`` package.
Besides CPU and memory accounting, the present tools can also provide:

* **GPU accounting** using NVIDIA
  [NVML](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_installation/#configuring-slurm-with-nvml).
* **Energy consumption accounting** using
  [IPMI power monitoring](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_configuration/#ipmi-power-monitoring).

These two Slurm plugins would have to be configured in your installation as described in the links,
otherwise GPU and energy accounting will be absent from the reports.

Installation: 
Copy the scripts to the ``/usr/local/bin/`` folder:
```
chmod +x jobeff jobmail
cp jobeff /usr/local/bin/	# All nodes
cp jobmail /usr/local/bin/	# Only the slurmctld server
```
Configure [MailProg](https://slurm.schedmd.com/slurm.conf.html#OPT_MailProg) in  ``slurm.conf``:
```
MailProg=/usr/local/bin/jobmail
```
and reconfigure Slurm with ``scontrol reconfigure``.

### jobeff

Usage:
```
jobeff [Options] [Jobid | SLUID]
       The job may be given by its Jobid or its Slurm SLUID.
       If omitted, the environment variable SLURM_JOB_ID is used.
       Options:
       -h    Help menu
       -d    Debug mode: display raw Slurm data
```

The job can be specified by its numeric ``Jobid`` or by its SLUID (*Slurm Lexicographically-sortable Unique ID*),
for example ``jobeff 11293137`` or ``jobeff s8FXM7QBF5ED00``, provided that the ``sacct -j`` option of your Slurm version accepts a SLUID.
Inside a Slurm job the argument can be omitted, since ``jobeff`` then reads the job ID from ``SLURM_JOB_ID``.
An explicit ``Jobid`` or SLUID takes precedence. If none is given, an error message is printed and the exit code is 1.

The job efficiency data are read from the Slurm database with ``sacct``.
For a running job, the statistics so far are printed, and the job steps still running are read with ``sstat``.
The report contains:

* Job ID, Array Job ID (for array tasks), Job SLUID, cluster, partition, node list, user/group with the user's full name (from the passwd GECOS field, if available), working directory (``WorkDir`` from ``sacct``) and job state with exit code.
* Submit, start and end times, and the elapsed time.
* Number of nodes and cores per node.
* CPU time used and CPU efficiency relative to the core-walltime.
* Memory used and memory efficiency relative to the allocated memory (per core or per node).
  The memory request type is read from ``sacct --json`` and requires the [jq](https://jqlang.org/) tool;
  without ``jq`` the memory is assumed to be allocated per node.
* GPUs per node (with the GPU type, if any), GPU utilization and GPU memory (min/max/average), if the job was allocated GPUs (see the NOTE below).
  A warning is printed if the max or average GPU utilization is below 10% (the ``gpu_util_threshold`` variable in ``jobeff``).
* The energy consumed by the job in Joules and kWh, if Slurm has measured it (the ``sacct`` field ``ConsumedEnergyRaw``).
  Values above 10 GJ (2778 kWh) are reported as invalid (the ``max_energy`` variable in ``jobeff``), as former Slurm bugs sometimes gave astronomically large values.
  For a running job, the energy so far of the running job steps is read with ``sstat``.
  Slurm measures the energy of entire nodes, so the energy is only that of the job if it had the nodes to itself
  (``sacct`` field ``Exclusive=NODE``, from ``sbatch --exclusive``).
  Otherwise a note is printed if other jobs ran on the same nodes during the job (Mixed node state).
  Normal users can usually only see their own jobs with ``sacct``, so if the job did not allocate all CPUs of its nodes,
  a note says that the energy may include other jobs (except when ``jobeff`` is run by root or SlurmUser, the ``slurm_user`` variable in ``jobeff``).

The exit code of ``jobeff`` is 0 on success, 1 for usage errors, 2 if the job was not found
or ``sacct`` failed (for example when the Slurm database is not responding), and 4 if the job has not started yet.

Example output from ```jobeff```:

```
Efficiency report for Slurm job 11326159
========================================

Parameter           Value
---------           -----
Job ID:             11326159
Job SLUID:          s8FXM7Z40K2Q00
Cluster:            niflheim
Partition:          h200el9
NodeList:           sd656
User/Group:         user1/group1 (Full Name)
WorkDir:            /home/user1
State:              RUNNING (statistics so far)
Submit time:        2026-11-21T14:15:52
Start time:         2026-11-21T14:15:53
Elapsed time:       2-01:39:52
End time:           Unknown
Nodes:              1
Cores per node:     8
CPU Utilized:       3-09:18:13
CPU Efficiency:     20.46% of 16-13:18:56 core-walltime
Memory Utilized:    79.95 GB
Memory Efficiency:  99.94% of 80.00 GB (10.00 GB/core)
Please note:        The task which had the largest memory consumption
                    differs by 100.02% from the average task max memory consumption
GPUs per node:      1 (h200)
GPU AllocTRES:      billing=256,cpu=8,gres/gpu:h200=1,gres/gpu=1,mem=81920M,node=1
GPU utilization:    min 87%, max 87%, avg 85% (gres/gpu=1)
GPU memory:         min 21920M, max 21920M, avg 21920M (MB) (gres/gpu=1)
Energy consumed:    99 kWh (358.11 MJ)
                    Note: This is the energy of the entire nodes, which were shared with 5 other job(s)
                    (Mixed node state), so it is not the energy of this job alone
```

The SLUID (*Slurm Lexicographically-sortable Unique ID*) job field was added in Slurm 24.11.

### jobmail

``slurmctld`` calls the ``MailProg`` as ``<MailProg> -s "<subject>" <recipient>``
for the job events requested by the user with ``sbatch --mail-type``.
The ``jobmail`` script sends the mail with ``/bin/mail``.
When the job has ended (the subject contains an ending state such as COMPLETED, FAILED or TIMEOUT),
``jobmail`` waits a few seconds (``JOB_COMPLETION_TIME``) for the accounting data to be committed to ``slurmdbd``,
and then puts the ``jobeff`` report of the job (or array task) in the mail body.
Other mails, such as job start notifications, are sent without a report.
