Slurm account factors updating tool
------------------------------------

Manage Slurm accounts:

* Create, update or delete Slurm user accounts from the passwd file.
* Update the Slurm fairshare and limits configurations.

Configure this value in the script:

```
# Skip users with UID < MINUID
export MINUID=1002
```

Configuration file
------------------

The file ```account_settings.conf``` defines a hierarchical tree of Slurm accounts and their
Slurm factors including:

```
fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefQOS
```

# Syntax of this file is 3 items separated by ":" like:

```
[DEFAULT|UNIX_group|username]:[Type]:value
```

Type: fairshare, GrpTRES, GrpTRESRunMins etc.

Examples:

```
# The default limits
DEFAULT:GrpTRES:cpu=1200
DEFAULT:GrpTRESRunMins:cpu=3000000

camdfac:fairshare:5
camdvip:fairshare:3
camdstud:fairshare:2

user01:fairshare:10
user02:fairshare:1
```
