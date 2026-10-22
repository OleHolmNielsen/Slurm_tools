#!/bin/bash

# This script is used for updating a Slurm node where the node has been rebooted
# purposefully by "scontrol reboot ASAP nextstate=down <nodelist>".
# This provides a very simple way to trigger automatic updating of compute nodes.
# 
# The helper script $update_*.sh scripts are sourced to perform any necessary updates.
# For convenience we recommend to use two helper scripts from this project: sreboot and reserve_on_idle
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
#    Alternatively simply do: scontrol reboot ASAP nextstate=down <nodelist>

# We need commands from /usr/sbin
export PATH=/usr/sbin:$PATH

# Log files are written to the compute node local folder:
LOG_FILE="/root/update.log"
LOG_FILE0="/root/update_down_node.log"

# Detect the OS version (see man os-release) 
source /etc/os-release
osversion=`echo $CPE_NAME | awk -F: '{print int($5)}'`
echo "OS version is: $osversion" >> $LOG_FILE0
# Determine the OS platform of this node
platform=`grep PLATFORM_ID /etc/os-release`

##########################################################################
# CONFIGURE:
# The cluster software folders as seen from the compute nodes:
PACKAGEDIR="/home/server"
SCRIPTDIR="$PACKAGEDIR/script-dir"
# The $update_* scripts live in the remote $SCRIPTDIR and will be copied to the local /root
update_software=update_software.sh
update_firmware=update_firmware.sh
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

# Record the timestamp of script execution
echo "============================" >> $LOG_FILE0
date >> $LOG_FILE0

##########################################################################
# Wait for network startup at reboot since this can take a number of seconds
echo "Ask NetworkManager whether the network startup is complete" >> $LOG_FILE0
nm-online --wait-for-startup >> $LOG_FILE0

# Make sure we have installed these prerequisite packages:
for p in dmidecode
do
	if ! rpm -q $p > /dev/null
	then
		dnf -y install $p >> $LOG_FILE0
	fi
done

######################################################
#
# Checking whether slurmd has been fully started and the Slurm node has "State=down".
#
if ! rpm -q slurm > /dev/null
then
	echo "ERROR: The required slurm RPM package is not installed" >> $LOG_FILE0
	echo "NOTICE: No updates will be performed on this node" >> $LOG_FILE0
	exit 0
fi
# Loop until slurmd has been started AND is responding
echo "Checking whether slurmd has been fully started" >> $LOG_FILE0
# A timer
t0="`date +%s`"
# See https://slurm.schedmd.com/scontrol.html#OPT_slurmd
until scontrol show slurmd > /dev/null 2>&1
do
	date >> $LOG_FILE0
	sleep 5
	tdelta=$((`date +%s` - t0))
	# Allow max 600 seconds
	if [ "$tdelta" -gt "600" ]
	then
		echo "ERROR: slurmd did not start within $tdelta seconds" >> $LOG_FILE0
		exit 0
	fi
done
date >> $LOG_FILE0
echo "OK: slurmd is now fully started" >> $LOG_FILE0
# Ask slurmd about this node's hostname
shortname="`scontrol show slurmd | grep Hostname | awk '{print $3}'`"

# Cache the output from scontrol
tempfile=`mktemp`
scontrol show node $shortname > $tempfile
# Get the Slurm node state and act on State=down nodes only
state="`cat $tempfile | grep '^   State=' | awk '{print $1}' | awk -F= '{print tolower($2)}'`"
# Get the NextState (may be down or resume, or empty if not set)
nextstate="`cat $tempfile | grep '^   NextState=' | awk '{print $1}' | awk -F= '{print tolower($2)}'`"
# Get the Slurm node Reason and skip nodes that unexpectedly rebooted
reason="`cat $tempfile | grep '^   Reason='`"
echo "INFO: Node $shortname has State=$state, NextState=$nextstate, and $reason" >> $LOG_FILE0
rm -f $tempfile

if [[ "X+$reason" =~ "Node unexpectedly rebooted" ]]
then
	echo "WARNING: This node has $reason" >> $LOG_FILE0
	echo "NOTICE: No updates will be performed on this node" >> $LOG_FILE0
	exit 0
fi

if [[ "X+$nextstate" =~ "resume" ]]
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

######################################################
#
# Check fileserver directories and copy scripts

echo "Check availability of NFS-mounted PACKAGEDIR=$PACKAGEDIR" >> $LOG_FILE0
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

echo "Copy the $update_software script from the remote server" >> $LOG_FILE0
if [ -s $SCRIPTDIR/$update_software ]
then
	cp $SCRIPTDIR/$update_software /root/
else
	echo "ERROR: Update script $SCRIPTDIR/$update_software not found" >> $LOG_FILE0
	exit 0
fi
echo "Copy the $update_firmware script from the remote server" >> $LOG_FILE0
if [ -s $SCRIPTDIR/$update_firmware ]
then
	cp $SCRIPTDIR/$update_firmware /root/
else
	echo "ERROR: Update script $SCRIPTDIR/$update_firmware not found" >> $LOG_FILE0
	exit 0
fi

##########################################################################
#
# Now do software and firmware updates

# Redirect stdout and stderr to $LOG_FILE in stead of the crontab output (mail)
exec 1>$LOG_FILE
exec 2>&1

# Source the update scripts which performs the actual updating
source /root/$update_software

# If you do not want to update any firmwares, simply comment out this line:
source /root/$update_firmware

##########################################################################

# Updates have been completed.  Update and resume the node

echo
echo "Script $0: Reboot this node $shortname at `date`"

# NOTICE: It is required that slurmd is running for "scontrol reboot" to work!
echo
echo "Check if the slurmd process is still running:"
if pgrep --full --list-full -u root slurmd
then
	echo "OK: the slurmd process is running"
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
