Slurm account factors updating tool
------------------------------------

Manage Slurm accounts:

* Create, update or delete Slurm user accounts from the passwd file.
* Update the Slurm fairshare and limits configurations.

Usage:

```
slurmaccounts
```

Configure this value in the script in order to skip system accounts:

```
# Skip users with UID < MINUID
export MINUID=1002
```

Configuration file
------------------

The file ```/etc/slurm/account_settings.conf``` defines a hierarchical tree of Slurm accounts and their Slurm factors including:

```
fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefQOS
```

The syntax of this file is 3 items separated by ```:``` like:

```
[DEFAULT|UNIX_group|username]:[Type]:value
```

The example file in this directory should be edited and copied to ```/etc/slurm/account_settings.conf```.

Examples:

```
# The default fairshare and limits
DEFAULT:fairshare:1
DEFAULT:GrpTRES:cpu=1200
DEFAULT:GrpTRESRunMins:cpu=3000000

camdfac:fairshare:5
camdvip:fairshare:3
camdstud:fairshare:2

user01:fairshare:10
user02:fairshare:1
```
