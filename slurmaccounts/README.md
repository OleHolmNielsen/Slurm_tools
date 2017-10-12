Slurm account factors updating tool
------------------------------------

Manage Slurm user fairshare, QOS and limits:

* Create, update or delete Slurm user accounts from the passwd file.
* Update the fairshare, QOS and limits configurations.

Usage:

```
slurmusersettings
```

You may configure this value in the script in order to skip system accounts:

```
# Skip users with UID < MINUID
export MINUID=1002
```

Also the variable ```user_settings_conf=/etc/slurm/user_settings.conf``` may be changed.

Configuration file
------------------

The file ```/etc/slurm/user_settings.conf``` defines users' Slurm factors including:

```
fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefaultQOS
```

The syntax of this file is 3 items separated by ```:``` like:

```
[DEFAULT|UNIX_group|username]:[Type]:value
```

The example file in this directory should be edited and copied to ```/etc/slurm/account_settings.conf```.

Examples:

```
# The default fairshare, QOS and limits
DEFAULT:fairshare:1
DEFAULT:GrpTRES:cpu=1200
DEFAULT:GrpTRESRunMins:cpu=3000000
DEFAULT:QOS:normal

camdfac:fairshare:5
camdvip:fairshare:3
camdstud:fairshare:2

user01:fairshare:10
user02:fairshare:1
user03:QOS:high
```
