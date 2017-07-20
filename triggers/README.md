Slurm trigger scripts
---------------------

Slurm "triggers" include events such as:

* a node failing
* daemon stops or restarts
* a job reaching its time limit
* a job terminating.

Usage
-----

Copy the scripts ```notify_nodes_down``` and ```notify_nodes_drained``` to /usr/local/bin/.

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

example contents of a trigger mail message:

```
Sun Jul 16 21:28:05 2017
NODELIST   NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON              
b028           1    xeon8*        down    8    2:4:1  23900    32752      1 xeon5570 Node unexpectedly re
Setting new trigger --node --down --program=/usr/local/bin/notify_nodes_down
```
