Slurm job scripts
-----------------

Some convenient scripts for managing Slurm jobs:

* [psjob](psjob) ```ps``` process status on a job's node-list, but exclude system processes: ```psjob [-c columns | -h] <jobid>```.
  Requires [ClusterShell](https://clustershell.readthedocs.io/en/latest/intro.html).
  The scratch disk usage with Slurm *job_container/tmpfs* (if configured) is printed.
  GPU usage may also be printed.

* [showjob](showjob) Show status of a Slurm job: ```showjob <jobid | jobid_arraytaskid | SLUID>```.
  Both queue information and accounting information is printed, including the CPU, memory and GPU usage of each job step,
  and the relevant limits for pending job reasons.
  See [showjob](#showjob) below.

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

showjob
-------

Usage:
```
showjob <jobid | jobid_arraytaskid | SLUID>
```

The job can be specified by its numeric ``jobid``, by an array task as ``jobid_arraytaskid`` (for example ``showjob 11340632_11``),
or by its SLUID (*Slurm Lexicographically-sortable Unique ID*, for example ``showjob s8FXM83YXNWJ00``).
A SLUID is converted to the jobid by looking first in the queue (``squeue``) and then in the Slurm database (``sacct``),
and the line ``SLUID <sluid> is JobID <jobid>`` is printed.
Note that the Slurm database has a separate SLUID per job record, which changes when a job is requeued or resized.

Requirements:

* GNU awk (``gawk``) version 4.0 or newer. The script checks this and stops with an error message if ``gawk`` is missing or too old.
* The ``showuserlimits`` command from [Slurm_tools](https://github.com/OleHolmNielsen/Slurm_tools/) is used for some pending job reasons.
  It is optional: if it is not installed, a message is printed only when it would have been used.
* A Slurm version with SLUID support (Slurm 24.11 or newer) for the SLUID argument.

### Jobs in the queue

For a job in the queue ``showjob`` prints:

* A job summary: user, account, submit time, state, number of CPUs, the time limit and the ``TRESRunMin`` (CPUs times time limit in minutes).
  A time limit such as ``UNLIMITED`` is reported as such, and then the ``TRESRunMin`` cannot be calculated.
* For a pending job, the reason why it is pending, with more information for these reasons:
  * ``AssocGrpCPURunMinutesLimit``, ``AssocGrpCPUMinutesLimit``, ``AssocGrpCpuLimit``, ``AssocGrpGRES`` and ``AssocMaxJobsLimit``:
    what the job requires, the current usage of the user in the job's account, and the limits from ``showuserlimits``.
    For ``AssocGrpGRES`` the GRES request is found whether it was given per job (``--gpus``), per node (``--gres``), per socket or per task.
    If the job was submitted to several partitions, the limits for all partitions are shown.
  * All QOS reasons (``QOSGrpCpuLimit``, ``QOSMaxCpuPerUserLimit``, ``QOSMaxJobsPerUserLimit``, ``QOSMaxWallDurationPerJobLimit`` etc.):
    the TRES and time limit requested by the job, and the limits that are set in the job's QOS, with their current usage,
    for the whole QOS and for the job's account and user (from ``scontrol show assoc_mgr flags=qos``).
    If a partition of the job has a partition QOS, its limits are shown as well.
  * ``Dependency`` and ``DependencyNeverSatisfied``: the job's dependency.
* The queued job information from ``scontrol --details show job``.
* The E-mail notification settings (``MailUser`` and ``MailType``), if the user requested E-mail notification
  with ``sbatch --mail-user`` or ``--mail-type`` in the job script or on the command line.
* When the job has started (any state except ``PENDING``, for example ``RUNNING``, ``SUSPENDED`` or ``COMPLETING``),
  the accounting information described below.

If the jobid of a job array with several jobs in the queue is given, ``showjob`` lists the array jobs and asks you to select one of them.
For a heterogeneous job the job summary is for the first component, and the queued job information is for all components.

Example of the additional information for a job pending with a QOS reason:

```
Information about QOSMaxCpuPerUserLimit:
This job requests TRES: cpu=96,mem=720000M,node=1,billing=384
This job has a time limit of: 10:00:00

Limits of QOS high (the QOS of the job), with the current usage in parentheses:
   The whole QOS high:
      MaxWallPJ=600 (minutes)
      MaxTRESPJ=cpu=1000
   Account account1 in QOS high: no limits
   User user1 in QOS high:
      MaxTRESPU=cpu=1000(192)
```

### Accounting information

For a job that is no longer in the queue, or that has started, ``showjob`` prints the accounting information from the Slurm database:

* The job parameters and job details (``sacct``).
* The resource usage of each job step (the batch step and the ``srun`` steps, and for a job array the steps of each array task):
  elapsed time, CPUs, CPU time and CPU utilization, memory used, allocated and utilization,
  and for jobs with GPUs also the GPUs, average GPU utilization and maximum GPU memory,
  and the energy consumed by each step if Slurm has measured it.
  Finished steps are read from the Slurm database with ``sacct``, and running or suspended steps are read with ``sstat``.
  * CPU util = CPU time / (Elapsed * CPUs).
  * Mem used = the sum over the tasks of the peak memory of each task (``TRESUsageInTot mem``).
  * Max GPU mem is shown as reported by Slurm (``TRESUsageInMax gres/gpumem``).
  * Energy consumed = the energy of the step in kWh and Joules (``ConsumedEnergyRaw``), so far for running steps.
    The column is only shown if Slurm has measured the energy, which requires energy accounting (``AcctGatherEnergyType`` in ``slurm.conf``).
    Values above 10 GJ (2778 kWh) are shown as ``n/a``, as former Slurm bugs sometimes gave astronomically large values (the ``max_energy`` variable in ``showjob``).
    Slurm measures the energy of entire nodes, so the energy includes any other jobs that ran on the same nodes.
  * Steps without usage data (such as the ``extern`` step) are not shown.
    If ``sstat`` cannot get the usage of a running step, the step is shown with blank values and a note.
* The ``SubmitLine`` and ``WorkDir`` of the job (each different line is printed once for a job array).
* The user's fairshare information (``sshare``).
* The batch script, if ``AccountingStoreFlags=job_script`` is enabled in ``slurm.conf``.
  For a job array the batch script is printed only once, since all array tasks use the same batch script.

A job array may have very many array tasks and job steps,
so each accounting table prints at most 50 lines, followed by a note about how many lines were not shown.
This maximum may be changed with the environment variable ``SHOWJOB_MAXLINES``, for example:
```
SHOWJOB_MAXLINES=200 showjob 11340632
```

The accounting information may only be inquired by the job owner or by root.
Normal users can usually only see their own jobs with ``sacct``, so for other jobs ``showjob`` reports
that the job was not found in the Slurm database, or that it is not visible to you.

The exit code of ``showjob`` is 0 on success,
and 1 for usage errors, if ``gawk`` is missing, if the job or SLUID was not found or is not visible to you,
if a job array with several jobs in the queue was given, or if the job belongs to another user.

Example output from ```showjob``` for a job that has ended:

```
Job 11290700 is not in the current Slurm queue

Accounting information from the Slurm database:

Job parameters for jobid 11290700:
   JobID JobName  User  Account Partition Timelimit 
-------- ------- ----- -------- --------- --------- 
11290700  gpujob user1 account1   a100el9  00:10:00 

Job details information for jobid 11290700:
   JobID              Submit            Eligible               Start  Elapsed                 End  CPUTime NNodes NCPUS ExitCode NodeList     State 
-------- ------------------- ------------------- ------------------- -------- ------------------- -------- ------ ----- -------- -------- --------- 
11290700 2026-11-18T08:35:37 2026-11-18T08:35:37 2026-11-18T08:35:38 00:01:40 2026-11-18T08:37:18 00:53:20      1    32      0:0    sd652 COMPLETED 

Resource usage per job step for jobid 11290700:
----------------------------------------------
JobID          State      Elapsed CPUs CPU time CPU util Mem used Mem alloc Mem util GPUs Avg GPU util Max GPU mem       Energy consumed 
-------------- --------- -------- ---- -------- -------- -------- --------- -------- ---- ------------ ----------- --------------------- 
11290700.batch COMPLETED 00:01:40   32 00:00:01       0%    18.2M     31.2G       0%    1           0%           0 0.0231 kWh (83.02 kJ) 
CPU util = CPU time / (Elapsed * CPUs)
Mem used = sum over the tasks of the peak memory of each task (TRESUsageInTot mem)
Max GPU mem is shown as reported by Slurm (TRESUsageInMax gres/gpumem)
Energy consumed = energy of the step measured by Slurm (ConsumedEnergyRaw), so far for running steps
Slurm measures the energy of entire nodes, so it includes any other jobs on the same nodes

SubmitLine:
-----------
sbatch gpujob.sh

WorkDir:
--------
/home/user1

User fairshare information:
...
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
Note: The SLUID (*Slurm Lexicographically-sortable Unique ID*) job field was added in Slurm 24.11.

### jobmail

``slurmctld`` calls the ``MailProg`` as ``<MailProg> -s "<subject>" <recipient>``
for the job events requested by the user with ``sbatch --mail-type``.
The ``jobmail`` script sends the mail with ``/bin/mail``.
When the job has ended (the subject contains an ending state such as COMPLETED, FAILED or TIMEOUT),
``jobmail`` waits a few seconds (``JOB_COMPLETION_TIME``) for the accounting data to be committed to ``slurmdbd``,
and then puts the ``jobeff`` report of the job (or array task) in the mail body.
Other mails, such as job start notifications, are sent without a report.
