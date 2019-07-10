The Slurm tool "showpartitions"
-------------------------------

Prints a Slurm cluster partition status 

Author: Ole Holm Nielsen <Ole.H.Nielsen \at/ fysik.dtu.dk>

Usage
-----

```
Usage: showpartitions [-p partition(s)] [-g]
where:
        -p partition: Select only partion <partition>
	-g: Print also GRES (Generic Resources)
```

History
-------

The showpartitions tool was inspired by the excellent tool ```spart```, see https://github.com/mercanca/spart
