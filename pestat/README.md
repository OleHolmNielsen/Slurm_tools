The Slurm tool "pestat" (Processor Element status)
--------------------------------------------------

Prints a Slurm cluster nodes status with 1 line per node and job info.

Author: Ole Holm Nielsen <Ole.H.Nielsen \at/ fysik.dtu.dk>

Usage
-----

```
pestat [-p partition(s)] [-u username] [-q qoslist] [-s statelist] [-n/-w hostlist] [-j joblist]
	[-f | -F | -m free_mem | -M free_mem ] [-1] [-C/-c] [-V] [-h]
where:
	-p partition: Select only partion <partition>
	-u username: Print only user <username> 
	-q qoslist: Print only QOS in the qoslist <qoslist>
	-s statelist: Print only nodes with state in <statelist> 
	-n/-w hostlist: Print only nodes in hostlist
	-j joblist: Print only nodes in job <joblist>
	-f: Print only nodes that are flagged by * (unexpected load etc.)
	-F: Line -f, but only nodes flagged in RED are printed.
	-m free_mem: Print only nodes with free memory LESS than free_mem MB
	-M free_mem: Print only nodes with free memory GREATER than free_mem MB (under-utilized)
	-1 Only 1 line per node (unique nodes in multiple partitions are printed once only)
	-C: Color output is forced ON
	-c: Color output is forced OFF
	-h: Print this help information
	-V: Version information
```

![pestat example](pestat-example.png)

For continuous monitoring in a terminal window you may for example use this command:

```
	watch -n 60 --color 'pestat -f -C'
```

Installation
------------

Copy pestat:

```
wget https://raw.githubusercontent.com/OleHolmNielsen/Slurm_tools/master/pestat/pestat
chmod 755 pestat
cp pestat /usr/local/bin
```

If desired copy pestat.conf:

```
wget https://raw.githubusercontent.com/OleHolmNielsen/Slurm_tools/master/pestat/pestat.conf
cp pestat.conf /etc/
```

Edit pestat.conf according to your needs.
Users may copy and edit this file as ```$HOME/.pestat.conf```.

Configuration
-------------

Global configuration file for pestat: ```/etc/pestat.conf```

Per-user configuration file for pestat: ```$HOME/.pestat.conf```

It is strongly recommended that you do not change the pestat script itself,
but make changes only in the above mentioned configuration files for pestat
to suit your needs.

Please write to the author if additional configurations should be made possible.

History
-------

The pestat tool was inspired by a similar tool for Torque/PBS by David Singleton (Sep 23, 2004),
see https://github.com/abarbu/torque/blob/master/contrib/README.pestat

The present author later wrote a pestat bash script for Torque, see
http://www.clusterresources.com/pipermail/torqueusers/2007-September/006188.html
and https://ftp.fysik.dtu.dk/Torque/
