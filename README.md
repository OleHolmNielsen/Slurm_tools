# Slurm tools

These [Slurm](https://slurm.schedmd.com/overview.html)
tools have been developed for management and monitoring of our cluster:

1. [pestat](pestat/) Prints a Slurm cluster nodes status with 1 line per node and job info.

2. [slurmreportmonth](slurmreportmonth/) Generate monthly accounting statistics from Slurm using the sreport command.

3. [slurmacct](slurmacct/) Generate accounting statistics from Slurm as an alternative to the sreport command

4. [showuserjobs](showuserjobs/) Print the current node status and batch jobs status broken down into userids.

5. [slurmibtopology](slurmibtopology/) Infiniband topology tool for Slurm.

6. Slurm [triggers](triggers/) scripts.

7. Scripts for managing [nodes](nodes/).

8. Scripts for managing [jobs](jobs/).

9. Scripts for managing [Slurm accounts and users](slurmaccounts/).

Slurm deployment HOWTO
----------------------

Our [Slurm HOWTO guide](https://wiki.fysik.dtu.dk/niflheim/SLURM) for setting up a Slurm installation.
It's based on CentOS/RHEL 7 Linux, but much of the information should be relevant on other Linuxes as well.

Download
--------

Use the above ```Clone or download``` button,
or go to the individual tool page,
click on the desired file, and then click the ```Raw``` button
to get a link which you can use for download.
