Slurm account and user updating tools
=====================================

Maintenance of Slurm accounts and user settings is a tedious and error-prone task if done manually.
The tools in this project offer a way of defining and configuring Slurm accounts and user settings by means of 
some tools with corresponding configuration files,
which you use to define your site's preferences.

* Firstly, you need to define a hierarchical tree of Slurm accounts from the top-level root and down through the organization.
This is the purpose of the ```slurmaccounts``` tool.
We have selected the users' UNIX groups as the bottom level of the account tree.
You may use the ```slurmaccounts2conf``` tool to create a configuration file using the contents of your current Slurm database.

* Secondly, when the account tree has been defined, users can be defined in the Slurm database.
This is the purpose of the ```slurmusersettings``` tool.
The user's Slurm ```default account``` is selected to be the UNIX group name at the bottom of the account tree.
Furthermore, a number of user settings can be defined in the configuration file:
```fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefaultQOS```.

When users or accounts are added, removed or modified in the configuration files,
rerun the tools to pick up the changes to the Slurm database.

Getting started
---------------

Configuration files: Steps 1 and 2 are used only during the initial setup:

1. Create the ```/etc/slurm/accounts.conf``` file by running the ```slurmaccounts2conf``` tool (see below).

2. Create the ```/etc/slurm/user_settings.conf``` file by running the ```slurmusersettings2conf``` tool (see below).

Review the new files in ```/etc/slurm/``` to make sure they correctly reflect your account hierarchy and user settings.

From now on you may update these configuration files and subsequently use the following tools to print commands for updating the Slurm database:

3. Run ```slurmaccounts``` to update your account hierarchy.

4. Run ```slurmusersettings``` to update your Slurm user settings.

These commands don't modify the Slurm database, they only print commands which you should review before actually executing them.

slurmaccounts tool
------------------

The ```slurmaccounts``` should be run to initially setup (or later reconfigure) the
hierarchical tree of Slurm *accounts*.

Usage:

```
slurmaccounts
```

The output consists of command lines which could be executed directly by:

```
slurmaccounts | bash
```
It is however recommended to review and edit the commands before actually executing them.

The file ```/etc/slurm/accounts.conf``` defines the hierarchical tree of Slurm accounts.
The syntax of this file is 4 items separated by ```:``` like:

```
account_name:parent_account:fairshare_value:Description_of_account
```

The example file in this directory should be edited and copied to ```/etc/slurm/accounts.conf```.

slurmaccounts2conf tool
-----------------------

This tool reads the Slurm database accounts and prints out the slurm accounts file.

Usage:

```
slurmaccounts2conf
```

The output should be copied to the file ```/etc/slurm/accounts.conf```.

slurmusersettings tool
----------------------

Manage Slurm *user* fairshare, QOS and limits:

* Create, update or delete Slurm users as defined in the system passwd database.
* Update users' fairshare, QOS and limits configurations.

```NOTICE:``` This script requires GNU awk version 4 with support of *arrays of arrays*.
The gawk 4.0 is available on RHEL/CentOS 7, whereas RHEL/CentOS 6 supplies the older gawk 3.1.
For gawk 3.x users there is a rewritten script ```slurmusersettings.awk3``` so that you can try it out.

You can alternatively run this tool on a machine with gawk 4 and execute remote commands by SSH on the Slurm server.
To use this feature uncomment and customize the script line ```# export remote="ssh <slurm-host>"```.

Usage:

```
slurmusersettings
```

The output consists of command lines which could be executed directly by:

```
slurmusersettings | bash
```
It is however recommended to review and edit the commands before actually executing them.

You may configure this value in the script in order to skip system accounts:

```
# Skip users with UID < MINUID
export MINUID=1002
```

The file ```/etc/slurm/user_settings.conf``` defines users' Slurm factors including:

```
fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefaultQOS
```

The syntax of this file is 3 items separated by ```:``` like:

```
[DEFAULT|UNIX_group|username]:[Type]:value
```

The example file in this directory should be edited and copied to ```/etc/slurm/user_settings.conf```.

Examples:

```
# The default fairshare, QOS and limits
DEFAULT:fairshare:1
DEFAULT:GrpTRES:cpu=1200
DEFAULT:GrpTRESRunMins:cpu=3000000
DEFAULT:QOS:normal
DEFAULT:MaxJobs:500
DEFAULT:MaxSubmitJobs:5000

# UNIX group defaults
camdfac:fairshare:5
camdvip:fairshare:3
camdstud:fairshare:2

# User values that differ from the defaults
user01:fairshare:10
user02:fairshare:1
user03:QOS:normal,high
```

slurmusersettings2conf tool
---------------------------

This tool reads your current Slurm database accounts and prints out the slurm user setting file.

```NOTICE:``` This script requires GNU awk version 4 with support of *arrays of arrays*.

You can alternatively run this tool on a machine with gawk 4 and execute remote commands by SSH on the Slurm server.
To use this feature uncomment and customize the script line ```# export remote="ssh <slurm-host>"```.

Usage:

```
slurmusersettings2conf
```

The output should be copied to the file ```/etc/slurm/user_settings.conf```.

showuserlimits tool
-------------------

This tool prints out the Slurm associations limits for a user.

Usage:

```
showuserlimits			# Current user
showuserlimits -u <userid>
showuserlimits -a		# All users
```
