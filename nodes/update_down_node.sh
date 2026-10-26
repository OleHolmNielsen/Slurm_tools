#!/bin/bash

# PURPOSE:
# This script is used for updating a Slurm nodelist where the nodes have been rebooted
# purposefully using the command "scontrol reboot ASAP nextstate=down <nodelist>".
# This provides a very simple way to trigger automatic updating of compute nodes.
#
# Homepage: https://github.com/OleHolmNielsen/Slurm_tools/tree/master/nodes#compute-node-os-and-firmware-updates
# Author: Ole Holm Nielsen <Ole.H.Nielsen@fysik.dtu.dk>
#
# NOTES:
# 1. If you want to update any nodes that are in Slurm State=powered_down 
#    you must do "scontrol power up <nodelist>" followed by the "scontrol reboot ...".
# 
# 2. The helper scripts $update_*.sh are sourced to perform any necessary updates.
#    The present script has been written for RPM-based Linux systems, but the logic should be generally applicable.
#
# 3. For convenience we also provide two helper scripts from this project: sreboot and reserve_on_idle
#
# INSTALLATION:
# Execute this script on all compute nodes at reboot time from root's crontab, for example:
# @reboot cat /root/update_down_node.sh | bash
# Note: Using "cat" protects against a possible overwrite of the script (up to 128 kB) while it is executing.
#
# CONFIGURATION:
# See the CONFIGURE section below.

# The updating procedure now consists of the following steps:
#
# 1. Simply do:
#    $ scontrol reboot ASAP nextstate=down <nodelist>
#    No more actions need to be taken.
#
# 2. Optional: For shared (mixed,non-exclusive) nodes only, add a Slurm reservation
#    that starts when the nodes become idle so that the nodes may run other jobs
#    by Slurm backfilling until they become idle:
#    $ reserve_on_idle <nodelist> update
#    The reservation will be automatically deleted as part of the script.
#
# 3. Schedule automated reboots and updates of the compute nodes:
#    $ sreboot -d -r UPDATE <nodelist>
#    The sreboot command lets shared nodes accept new jobs, whereas exclusive nodes are rebooted ASAP.
#    The "-d" flag sets NextState to Down.
#    The "-r" flag sets the Reason

# We need commands from /usr/sbin
export PATH=/usr/sbin:$PATH

# Log files are written to the compute node local folder:
LOG_FILE="/root/update.log"
LOG_FILE0="/root/update_down_node.log"

##########################################################################
# Detect the OS version (see man os-release) 
source /etc/os-release
osversion=`echo $CPE_NAME | awk -F: '{print int($5)}'`
echo "OS version is: $osversion" >> $LOG_FILE0
# Determine the OS platform of this node
platform=`grep PLATFORM_ID /etc/os-release`

##########################################################################
#
# CONFIGURE:
#
# The cluster software folders as seen from the compute nodes:
PACKAGEDIR="/home/server"
SCRIPTDIR="$PACKAGEDIR/scripts-dir"
# The $update_scripts live in the remote $SCRIPTDIR and will be copied to the local /root
# If you do not want to update any firmwares, simply remove update_firmware.sh from this list
update_scripts="update_software.sh update_firmware.sh"

# Determine the directory $RPMDIR where we store platform-specific packages for the nodes.
# For example, we use directories "RPMS8" and "RPMS9" for EL8 and EL9, respectively.
if [[ "X+$platform" =~ "el8" ]]
then
	RPMDIR=$PACKAGEDIR/RPMS8
elif [[ "X+$platform" =~ "el9" ]]
then
	RPMDIR=$PACKAGEDIR/RPMS9
else
	echo "OS platform $platform is not configured" >> $LOG_FILE0
	exit 1
fi

##########################################################################
#
# This function verifies that slurmd is installed, up, and started on the node.
#
function check_slurmd()
{
	# First ensure that the slurmd RPM package has been installed:
	if ! rpm -q slurm-slurmd > /dev/null
	then
		echo "ERROR: The required slurm RPM package is not installed" 
		return 1
	fi
	# Initialize a timer for checking slurmd
	t0="`date +%s`"
	# Allow 600 seconds max
	tmax=600
	# For "scontrol show slurmd" see https://slurm.schedmd.com/scontrol.html#OPT_slurmd
	until scontrol show slurmd > /dev/null 2>&1
	do
		date 
		sleep 5
		tdelta=$((`date +%s` - t0))
		if [ "$tdelta" -gt "$tmax" ]
		then
			echo "ERROR: slurmd did not start within $tdelta seconds" 
			return 1
		fi
	done
	return 0
}

##########################################################################
#
# This function checks the fileserver remote mounted directory 
#
function check_fileserver()
{
	echo "Check availability of NFS-mounted PACKAGEDIR=$PACKAGEDIR"
	# Initialize a timer for checking slurmd
	t0="`date +%s`"
	# Allow 600 seconds max
	tmax=600
	until [[ -d $PACKAGEDIR ]]
	do
		date 
		echo "WARNING: PACKAGEDIR=$PACKAGEDIR is not mounted, sleep and retry" 
		sleep 10
		tdelta=$((`date +%s` - t0))
		if [ "$tdelta" -gt "$tmax" ]
		then
			echo "ERROR: PACKAGEDIR=$PACKAGEDIR is not mounted after $tdelta seconds" 
			# Optional alert:
			# echo "ERROR: PACKAGEDIR=$PACKAGEDIR is not mounted" | mail -s "Script $0" root
			return 1
		fi
	done
	return 0
}
##########################################################################

# Record the timestamp of script execution
echo "============================" >> $LOG_FILE0
date >> $LOG_FILE0

##########################################################################
#
# The real action of this script starts here:
#

# Wait for network startup at reboot since this can take a number of seconds
echo "Ask NetworkManager whether the network startup is complete" >> $LOG_FILE0
nm-online --wait-for-startup >> $LOG_FILE0

# Startup of slurmd can potentially take 1-2 minutes on GPU nodes
echo "Checking whether slurmd has been fully started" >> $LOG_FILE0
date >> $LOG_FILE0
if check_slurmd >> $LOG_FILE0
then
	echo "OK: slurmd is now fully started" >> $LOG_FILE0
else
	echo "NOTICE: No updates will be performed on this node" >> $LOG_FILE0
	exit 0
fi

# Ask slurmd about this node's hostname
shortname="`scontrol show slurmd | grep Hostname | awk '{print $3}'`"

# Cache the output from "scontrol show node" and get state and reason information
tempfile=`mktemp`
scontrol show node $shortname > $tempfile
# Get the Slurm node state 
state="`cat $tempfile | grep '^   State=' | awk '{print $1}' | awk -F= '{print tolower($2)}'`"
# Get the NextState (may be down or resume, or empty if not set)
nextstate="`cat $tempfile | grep '^   NextState=' | awk '{print $1}' | awk -F= '{print tolower($2)}'`"
# Get the Slurm node Reason (may be empty)
reason="`cat $tempfile | grep '^   Reason='`"
rm -f $tempfile

echo "INFO: Node $shortname has State=$state, NextState=$nextstate, $reason" >> $LOG_FILE0

##########################################################################
#
# Act on various Slurm state and reason information
#
if [[ "X+$reason" =~ "Node unexpectedly rebooted" ]]
then
	echo "WARNING: This node has $reason" >> $LOG_FILE0
	echo "NOTICE: No updates will be performed on this node" >> $LOG_FILE0
	exit 0
elif [[ "X+$nextstate" =~ "resume" ]]
then
	date >> $LOG_FILE0
	echo "NOTICE: No updates will be performed on this node because nextstate=$nextstate" >> $LOG_FILE0
	exit 0
elif [[ "$state" =~ "down" ]]
then
	# Using =~ "down" allows for down+reserved or similar states:
	echo "All checks passed: This script $0 will now perform updates" >> $LOG_FILE0
	echo "The logfile is $LOG_FILE" >> $LOG_FILE0
else
	echo "NOTICE: No updates will be performed on this node" >> $LOG_FILE0
	exit 0
fi

##########################################################################
#
# Check if the fileserver $SCRIPTDIR directory is mounted
#
if check_fileserver >> $LOG_FILE0
then
	echo "OK: Fileserver $SCRIPTDIR directory is mounted" >> $LOG_FILE0
else
	echo "NOTICE: No updates will be performed on this node"  >> $LOG_FILE0
	exit 0
fi

##########################################################################
#
# Now do software and firmware updates
#

# Redirect stdout and stderr to $LOG_FILE in stead of the crontab output (mail)
exec 1>$LOG_FILE
exec 2>&1

# Copy up-to-date $update_scripts files from the fileserver to local disk
for scr in $update_scripts
do
	echo "Copy the $scr script from the remote server $SCRIPTDIR" >> $LOG_FILE0
	if [ -s $SCRIPTDIR/$scr ]
	then
		cp $SCRIPTDIR/$scr /root/
	else
		echo "ERROR: Update script $SCRIPTDIR/$scr not found" >> $LOG_FILE0
		exit 0
	fi
done

# Source the $update_scripts in /root which performs the actual updating
for scr in $update_scripts
do
	source /root/$scr
done

##########################################################################
#
# Updates have been completed, now reboot and resume the node
#

echo
echo "Script $0: Reboot this node $shortname at `date`"

# NOTICE: It is required that slurmd is running for "scontrol reboot" to work!
echo
echo "Check if the slurmd process is still running:"
if check_slurmd
then
	echo "OK: slurmd is running" 
else
	echo "NOTICE: Reboot the node immediately"
	shutdown -r now "No slurmd process is running"
	exit 0
fi

# Remove this node from any possible update related reservations update-$shortname
# The magic reservation name (if used) is set by the "reserve_on_idle" script.
# If the node is not in a reservation, the delete command will just print a warning message.
echo
echo "Notice: Delete reservation update-$shortname (if it exists)"
scontrol delete ReservationName=update-$shortname

# Reboot the node with Slurm
NEXTSTATE=resume
echo "Next Slurm node state is: $NEXTSTATE"
echo "Reboot node by Slurm scontrol reboot, setting nextstate=$NEXTSTATE"
scontrol reboot nextstate=$NEXTSTATE reason=Update_done $shortname

exit 0
