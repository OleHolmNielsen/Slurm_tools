Job_submit plugin
=================

The ```job_submit.lua``` script can be copied to the ```/etc/slurm/``` directory.
The script is structured as a number of self-contained functions that perform very specific tasks.
The functions ```slurm_job_submit()``` and ```slurm_job_modify()``` are called by ```slurmctld```,
and they simply loop over the desired functions in the present script:
```
functionlist = { check_arg_list, forbid_reserved_name, check_partition, check_num_nodes, check_num_tasks, forbid_memory_eq_0, check_cpus_tasks, check_gpus }
```


There is more information about [job submit plugins]( https://slurm.schedmd.com/job_submit_plugins.html).

See the Niflheim Wiki page https://wiki.fysik.dtu.dk/niflheim/Slurm_configuration#job-submit-plugins 
about building an enabling this plugin.

NOTES:

* Some variables in the script should be adjusted for your cluster setup:

  - badstring="BAD:"
  - partitions
  - default_partition
  - default_nodes=1
  - default_tasks=1

* The ```slurm.log_info()``` function logs to the slurmctld.log
  We print the "badstring" string to identify bad job submissions, for example:
  ```
  grep BAD: /var/log/slurm/slurmctld.log
  ```
* The ```slurm.log_user()``` function prints an error message to the user's terminal.    
  This currently doesn't work in the ```slurm_job_modify()``` function, 
  see [bug 14539](https://bugs.schedmd.com/show_bug.cgi?id=14539) but will be fixed in 23.02.
* Slurm Error numbers are defined in the source file ```slurm/slurm_errno.h```
* For the list of available Lua ```slurm.*``` fields check the job_desc variable in ```src/plugins/job_submit/lua/job_submit_lua.c```.

Slurm error numbers
---------------------

Error numbers are defined in the source file ```/usr/include/slurm/slurm_errno.h```.
We currently have to define error symbols manually, see [bug 14500](https://bugs.schedmd.com/show_bug.cgi?id=14500),
and only a few selected symbols ESLURM_* are exposed to the Lua script.
These issues will be resolved in Slurm 23.02.
