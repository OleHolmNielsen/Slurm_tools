Slurm account and user updating tools
=====================================

Maintenance of Slurm accounts and user settings is a tedious and error-prone task if done manually.
The tools in this project offer a way of defining and configuring Slurm accounts and user settings by means of 
some tools with corresponding configuration files, which you use to define your site's preferences.

Basic concepts
--------------

The mapping of UNIX groups onto Slurm accounts is the fundamental concept of this project!
UNIX group names (the UNIX ```group``` file) are used to define the corresponding Slurm account names.
In the present project we have chosen the users' UNIX groups as the bottom level (leaf nodes) of the Slurm account tree.

In this setup, the user's primary UNIX group becomes the user's Slurm *Default account*.
If the user has any secondary UNIX group memberships, the user is also added to the corresponding Slurm accounts (if they exist).
To print all groups to which a username belongs:
```
id --name --groups <username>
```

There are restrictions in these tools:

* One or more UNIX groups may map uniquely onto a Slurm account.
However, we do not support Slurm setups where one UNIX group has been mapped onto multiple, distinct Slurm accounts.

* We do not support per-user UNIX groups where each username's primary UNIX group is the same as the username (groupname=username).

The tools read the UNIX user database using the commands ```getent passwd``` and ```getent group```.
If these commands list the complete user database relevant for Slurm, you should be ready to start.
Furthermore, the Slurm command ```sacctmgr``` is used to read the list of Slurm accounts.

These tools may be run by any non-administrator account initially while you test whether they work as expected in your environment.
The configuration files ```accounts.conf``` and ```user_settings.conf``` files would have to be placed in a temporary location while testing.

* Firstly, you can define a hierarchical tree of Slurm accounts from the top-level root and down through the organization.
Use the UNIX group names to define the bottom level of the account tree.
Creation of this tree is the purpose of the ```slurmaccounts``` tool.
You may use the ```slurmaccounts2conf``` tool to create a configuration file using the contents of your current Slurm database.

* Secondly, when the account tree has been defined, users can be defined in the Slurm database.
This is the purpose of the ```slurmusersettings``` tool.
The user's Slurm ```default account``` is selected to be the primary UNIX group name at the bottom of the account tree.
Furthermore, a number of user settings can be defined in the configuration file:
```fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefaultQOS MaxJobsAccrue GrpJobsAccrue```.

When Slurm accounts are added, removed or modified in the configuration files, or UNIX users are changed in the system passwd/group files,
rerun the tools to pick up the changes to the Slurm database.

Presentations
-------------

The work in this project was presented at the *Slurm User Group* (SLUG) meeting in Salt Lake City on September 18, 2019 
and the slides are in ![this PDF file](Slurm_account_synchronization.pdf).

Getting started
---------------

Configuration files: Steps 1 and 2 are used only during the initial setup:

1. Create the ```/etc/slurm/accounts.conf``` file by running the ```slurmaccounts2conf``` tool (see below).

2. Create the ```/etc/slurm/user_settings.conf``` file by running the ```slurmusersettings2conf``` tool (see below).

Review the new files in ```/etc/slurm/``` to make sure they correctly reflect your account hierarchy and user settings.

From now on you may update these configuration files and subsequently use the following tools to print commands for updating the Slurm database:

3. Run ```slurmaccounts``` to update your account hierarchy when new (group) accounts are added or accounts deleted.

4. Run ```slurmusersettings``` to update your Slurm user settings.

5. Run ```showuserlimits``` to display a Slurm user's limits, or the limits of all users.

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

Account configuration file accounts.conf
----------------------------------------

The file ```/etc/slurm/accounts.conf``` defines the hierarchical tree of Slurm accounts.
The syntax of this file is 4 or 5 items separated by ```:``` like:

```
account_name:parent_account:fairshare_value:Description_of_account[:group1[,group2]...]
```

The optional field 5 is a comma-separated list of UNIX groups which are aliased to the Slurm ```account_name```,
and this list must be added manually.

It is possible to add also a fake ```account_name=NOACCOUNT``` where the UNIX groups listed in field 5 will be ignored from further processing,
for example:

```
NOACCOUNT:::We ignore these groups:group3,group4
```

The file generated by ```slurmaccounts``` should be edited as needed and copied to ```/etc/slurm/accounts.conf```.

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
slurmusersettings [-u username]
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

Users are considered having NEWUSER status for the first $newuserperiod after the Slurm account was created.
Lower limits may be implemented for NEWUSERs so they do not consume excessive resources.
After $newuserperiod the usual DEFAULT limits will be applied.
You may configure this value in the script:

```
export newuserperiod="30 days"
```


The file ```/etc/slurm/user_settings.conf``` defines users' Slurm factors including:

```
fairshare GrpTRES GrpTRESMins MaxTRES MaxTRESPerNode MaxTRESMins GrpTRESRunMins QOS DefaultQOS GrpJobsAccrue MaxJobsAccrue
```

The syntax of this file is 3 items separated by ```:``` like:

```
[DEFAULT|UNIX_group|username|NEWUSER]:[Type]:value
```

The example file in this directory should be edited and copied to ```/etc/slurm/user_settings.conf```.

Examples:

```
# The default fairshare, QOS and limits
DEFAULT:fairshare:1
DEFAULT:GrpTRES:cpu=1200,gres/gpu=20
DEFAULT:GrpTRESRunMins:cpu=3000000
DEFAULT:QOS:normal
DEFAULT:MaxJobs:500
DEFAULT:MaxSubmitJobs:5000
DEFAULT:MaxJobsAccrue:50

# The NEWUSER fairshare, QOS and limits
NEWUSER:fairshare:0
NEWUSER:GrpTRES:cpu=100
NEWUSER:GrpTRESRunMins:cpu=400000
NEWUSER:QOS:normal
NEWUSER:MaxJobs:50
NEWUSER:MaxSubmitJobs:50
NEWUSER:MaxJobsAccrue:10
# Configure "username" so that NEWUSER settings will be ignored
# NEWUSER:username:ignore
# Configure NEWUSER "username" so we do not create this Slurm user
# NEWUSER:username:dontcreate

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

slurmusertable tool
-------------------

This tool reads your current Slurm database ```user_table``` and prints out a list of usernames, creation time, and modification time.

Read access to the Slurm MySQL database is required, so the appropriate MySQL user and hostname must be configured in the MySQL server,
see https://wiki.fysik.dtu.dk/niflheim/Slurm_database#set-up-mariadb-database

Usage:

```
slurmusertable [username(s)]
```
