Job_submit plugin
=================

Read the documentation of Slurm [job submit plugins]( https://slurm.schedmd.com/job_submit_plugins.html).

The present ```job_submit.lua``` script can be copied to the ```/etc/slurm/``` directory.
The script is structured as a number of self-contained sub-functions that perform very specific tasks.
The functions ```slurm_job_submit()``` and ```slurm_job_modify()``` are called by ```slurmctld```,
and these functions simply loop over the desired sub-functions in the present script:
```
functionlist = { check_arg_list, forbid_reserved_name, check_partition, check_num_nodes, check_num_tasks, forbid_memory_eq_0, check_cpus_tasks, check_gpus }
```

See the [Niflheim Wiki page on job submit plugins](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_configuration/#job-submit-plugins)
about building and enabling [job submit plugins]( https://slurm.schedmd.com/job_submit_plugins.html).

Notes about the plugin
----------------------

* Some variables in the script should be adjusted for your cluster setup:
  ```
  partitions=...
  default_partition=...
  default_nodes=1
  default_tasks=1
  ```
* Define your partitions and usage policies:
  ```
  { partition="xeon24", numcores=24, entirenode=1, num_gpus=0 }
  ```
  where the variables mean:

  - ```partition``` name: a **substring** which begins the name.   
    Multiple partitions can be lumped together, for example, xeon24, xeon24_512, xeon24_1024 as ```xeon24```.
  - ```numcores```: number of CPU cores in each node in the partition.
  - ```num_gpus```: number of gpus in each node in the partition.
  - ```entirenode```: **A site policy:** 1 if jobs **must** be submitted for entire nodes, 0 otherwise.   
    Obviously such policies will have to be configured for each site.
* The ```slurm.log_info()``` function logs to the ```slurmctld.log```.   
  We log the ```BAD:``` "badstring" to identify bad job submissions, example outputs may be:
  ```
  $ grep BAD: /var/log/slurm/slurmctld.log
  lua: slurm_job_submit: user aaaa(UID=245729) job_name=job_0.4 BAD: Invalid partition xeon8 specified
  lua: slurm_job_submit: user bbbb(UID=226995) job_name=x16_old for 1 nodes in partition xeon24 BAD: num_tasks=4 cpus_per_task=1
  lua: slurm_job_submit: user bbbb(UID=226995) job_name=x16_inner_B_3_outer_B_0 for 1 nodes in partition xeon24 BAD: num_tasks=4 cpus_per_task=1
  lua: slurm_job_submit: user cccc(UID=288886) job_name=F_desp_cadena BAD: Invalid partition xeon25 specified
  lua: slurm_job_submit: user dddd(UID=216593) job_name=gpaw BAD: Invalid partition pluto specified
  ```
* The ```slurm.log_user()``` function prints an error message to the user's terminal.    
  This didn't work in the ```slurm_job_modify()``` function prior to Slurm 23.02, 
  see [bug 14539](https://bugs.schedmd.com/show_bug.cgi?id=14539).
* Slurm Error numbers are defined in the source file ```slurm/slurm_errno.h``` as well as ```/usr/include/slurm/slurm_errno.h```.
* For the list of available Lua ```slurm.*``` fields check the job_desc variable in the source file
  ```src/plugins/job_submit/lua/job_submit_lua.c```.

Slurm error numbers
---------------------

Error numbers are defined in the source file ```/usr/include/slurm/slurm_errno.h```.
Prior to Slurm 23.02 we had to define error symbols manually, see [bug 14500](https://bugs.schedmd.com/show_bug.cgi?id=14500),
and only a few selected symbols ESLURM_* are exposed to the Lua script.
