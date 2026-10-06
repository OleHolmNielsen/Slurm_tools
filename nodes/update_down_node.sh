#!/bin/bash

# This script is used for updating a Slurm node where the node has been rebooted
# purposefully by "scontrol reboot ASAP nextstate=down <nodelist>".
# This provides a very simple way to trigger automatic updating of compute nodes.
# 
# The helper script $update_* scripts are sourced to perform any necessary updates.
# For convenience we use two helper scripts from this project: sreboot and reserve_on_idle
#
# Installation: Execute this script at reboot time from root's crontab, for example:
# @reboot /root/update_down_node.sh

# The updating procedure now consists of the following steps:
#
# 1. Optional: For shared (mixed,non-exclusive) nodes only, add a Slurm reservation
#    that starts when the nodes become idle so that the nodes may run other jobs
#    by Slurm backfilling until they become idle:
#    $ reserve_on_idle <nodelist> update
#    The reservation will be automatically deleted as part of the script.
#
# 2. Schedule automated reboots and updates of the compute nodes:
#    $ sreboot -d -r UPDATE <nodelist>
#    The sreboot command lets shared nodes accept new jobs, whereas exclusive nodes are rebooted ASAP.
#    The "-d" flag sets NextState to Down.
#    The "-r" flag sets the Reason

##########################################################################
#
# CONFIGURE these lines:
#
# The cluster software and script folders as seen from the compute nodes:
PACKAGEDIR="/home/server"
SCRIPTDIR="$PACKAGEDIR/script-directory"
# The $update_* scripts live in the remote $SCRIPTDIR and will be copied to the local /root
update_software=update_software.sh
update_firmware=update_firmware.sh
##########################################################################

# We need commands from /usr/sbin
export PATH=/usr/sbin:$PATH

# Log files are written to the compute node local folder:
LOG_FILE="/root/update.log"
LOG_FILE0="/root/update0.log"
# Record the timestamp of script execution
echo "============================" >> $LOG_FILE0
date >> $LOG_FILE0

##########################################################################
# Wait for network startup at reboot since this can take a number of seconds
echo "Ask NetworkManager whether the network startup is complete" >> $LOG_FILE0
nm-online --wait-for-startup >> $LOG_FILE0

# Make sure we have installed these packages:
for p in hostname dmidecode
do
	if ! rpm -q $p > /dev/null
	then
		dnf -y install $p >> $LOG_FILE0
	fi
done

# Get the Slurm node's short name (first field in DNS name)
shortname="`hostname -s`"

######################################################
#
# Checking whether the Slurm node has "State=down".
#
# We must sleep some seconds to allow:
# 1) slurmd to be started at reboot, and
# 2) to allow slurmctld to set node state=down in stead of reboot/mixed etc.
sleep 30

# Check if the slurmd process is running:
if pgrep --full --list-full -u root slurmd > /dev/null
then
	echo "Check OK: the slurmd process is running" >> $LOG_FILE0
else
	echo "ERROR: no slurmd process is running" >> $LOG_FILE0
	exit 0
fi

# Get the Slurm node state and act on State=down nodes only
state="`scontrol show node $shortname | grep "^   State=" | awk '{print $1}' | awk -F= '{print tolower($2)}'`"
# We could alternatively use: sinfo -h -O StateLong -n $shortname | awk '{print $1}'
echo "INFO: This node $shortname has Slurm state=$state" >> $LOG_FILE0
# Using =~ "down" allows for down+reserved or similar states:
if [[ "$state" =~ "down" ]]
then
	echo "All checks passed: This script $0 will now perform updates" >> $LOG_FILE0
	echo "The logfile is $LOG_FILE" >> $LOG_FILE0
elif [[ "$state" == "mixed" ]]
then
	# Debugging:
	scontrol show node $shortname >> $LOG_FILE0
	echo "Slurm bug on node state mixed: This script $0 will now perform updates" >> $LOG_FILE0
	echo "The logfile is $LOG_FILE" >> $LOG_FILE0
else
	echo "NOTICE: No updates will be performed on this node" >> $LOG_FILE0
	exit 0
fi

echo "Check availability of NFS-mounted PACKAGEDIR=$PACKAGEDIR"
if [[ ! -d $PACKAGEDIR ]]
then
	echo "WARNING: PACKAGEDIR=$PACKAGEDIR is not mounted"  >> $LOG_FILE0
	echo "Sleep and retry filesystem mount..."  >> $LOG_FILE0
	sleep 90
	if [[ ! -d $PACKAGEDIR ]]
	then
		echo "ERROR: PACKAGEDIR=$PACKAGEDIR is not mounted"  >> $LOG_FILE0
		echo "ERROR: PACKAGEDIR=$PACKAGEDIR is not mounted" | mail -s "Script $0" root
	fi
	ls -l $PACKAGEDIR  >> $LOG_FILE0
	exit 0
fi

echo "Copy the $update_software script from the remote server"
if [ -s $SCRIPTDIR/$update_software ]
then
	cp $SCRIPTDIR/$update_software /root/
else
	echo "ERROR: Update script $SCRIPTDIR/$update_software not found" >> $LOG_FILE0
	exit 0
fi
echo "Copy the $update_firmware script from the remote server"
if [ -s $SCRIPTDIR/$update_firmware ]
then
	cp $SCRIPTDIR/$update_firmware /root/
else
	echo "ERROR: Update script $SCRIPTDIR/$update_firmware not found" >> $LOG_FILE0
	exit 0
fi

##########################################################################

# Redirect stdout and stderr to $LOG_FILE in stead of the crontab output (mail)
exec 1>$LOG_FILE
exec 2>&1

# Source the update scripts which performs the actual updating
source /root/$update_software
source /root/$update_firmware

##########################################################################

# Updates have been completed.  Update and resume the node

echo
echo "Script $0: Reboot this node $shortname at `date`"

# NOTICE: It is required that slurmd is running for "scontrol reboot" to work!
echo
echo "Check if the slurmd process is running:"
if pgrep --full --list-full -u root slurmd
then
	echo "Check OK: the slurmd process is running"
else
	echo "ERROR: no slurmd process is running"
	echo "Reboot the node immediately"
	shutdown -r now
fi

# Remove this node from any possible update related reservations update-$shortname
# The magic reservation name is set by the "reserve_on_idle" script.
# If the node is not in a reservation, the delete command will just print a warning message.
echo
echo "Notice: Delete reservation update-$shortname if it exists"
scontrol delete ReservationName=update-$shortname

# Reboot the node with Slurm
NEXTSTATE=resume
echo "Next Slurm node state is: $NEXTSTATE"
echo "Reboot node by Slurm scontrol reboot, setting nextstate=$NEXTSTATE"
scontrol reboot nextstate=$NEXTSTATE reason=Update_done $shortname

exit 0
