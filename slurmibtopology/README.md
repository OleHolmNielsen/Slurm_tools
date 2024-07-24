Infiniband topology tool slurmibtopology.sh for Slurm
-----------------------------------------------------

Create a Slurm ```topology.conf``` file to get the correct node and switch Infiniband connectivity.

Prerequisites
-------------

The OFED command ```ibnetdiscover```.
On EL8/9 Linux this is part of the ```infiniband-diags``` RPM package.

Usage
-----

```
Usage: slurmibtopology.sh [-c]
where:
        -c: comments in the output will be filtered
        -V: Version information
        -h: Print this help information
```

The comments are useful to understand the output of ```ibnetdiscover```,
but you may want to filter them using -c.
