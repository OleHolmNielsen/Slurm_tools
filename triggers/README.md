Slurm trigger scripts
---------------------

Slurm "triggers" include events such as:

* a node is down, is drained, or fails.
* a Slurm daemon stops or restarts
* a job reaching its time limit
* a job terminating.

See the [strigger](https://slurm.schedmd.com/strigger.html) manual page.

Slurm controller scripts
------------------------

Some convenient scripts for working with the Slurm controller ```slurmctld```.
The following scripts are used to monitor the ```slurmctld``` and the ```slurmdbd``` using the ```strigger``` command:

* ```notify_slurmdbd_down```: Trigger script for primary_slurmdbd_failure
* ```notify_slurmdbd_resumed```: Trigger script for primary_slurmdbd_resumed
* ```notify_slurmctld_acct_buffer_full```: Trigger script for slurmctld_acct_buffer_full

See ```man strigger``` about usage of this command.

Usage of daemon triggers
------------------------

Copy these scripts to /usr/local/bin/.

Initialize the triggers by:
```
# strigger --set --primary_slurmdbd_failure --program=/usr/local/bin/notify_slurmdbd_down
# strigger --set --primary_slurmdbd_resumed --program=/usr/local/bin/notify_slurmdbd_resumed
# strigger --set --primary_slurmctld_acct_buffer_full --program=/usr/local/bin/notify_slurmctld_acct_buffer_full
```

Usage of node triggers
----------------------

Copy the scripts ```notify_nodes_down``` and ```notify_nodes_drained``` to /usr/local/bin/.
If necessary modify the variables slurm_user, slurm_notify, my_mail in the scripts.

Become the *slurm* user.

To set up the triggers:

```
slurm> strigger --set --node --down    --program=/usr/local/bin/notify_nodes_down
slurm> strigger --set --node --drained --program=/usr/local/bin/notify_nodes_drained
```

To display enabled triggers:

```
strigger --get
```

Example output
--------------

Example contents of a trigger mail message:

```
Sun Jul 16 21:28:05 2017
NODELIST   NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON              
b028           1    xeon8*        down    8    2:4:1  23900    32752      1 xeon5570 Node unexpectedly re
Setting new trigger --node --down --program=/usr/local/bin/notify_nodes_down
```
