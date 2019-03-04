Slurm controller scripts
------------------------

Some convenient scripts for working with the Slurm controller ```slurmctld```.
The following scripts are used to monitor the ```slurmctld``` and the ```slurmdbd``` using the ```strigger``` command:

* ```notify_slurmdbd_down```: Trigger script for primary_slurmdbd_failure
* ```notify_slurmdbd_resumed```: Trigger script for primary_slurmdbd_resumed
* ```notify_slurmctld_acct_buffer_full```: Trigger script for slurmctld_acct_buffer_full

See ```man strigger``` about usage of this command.

Usage
-----

Copy these scripts to /usr/local/bin/.

Initialize the triggers by:
```
# strigger --set --primary_slurmdbd_failure --program=/usr/local/bin/notify_slurmdbd_down
# strigger --set --primary_slurmdbd_resumed --program=/usr/local/bin/notify_slurmdbd_resumed
# strigger --set --primary_slurmctld_acct_buffer_full --program=/usr/local/bin/notify_slurmctld_acct_buffer_full
```

List all current triggers by:
```
# strigger --get
```
