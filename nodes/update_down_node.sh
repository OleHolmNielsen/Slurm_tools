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
# 1. The present script has been written for RPM-based Linux systems, but the logic should be generally applicable.
#
# 2. If you want to update any nodes that are in Slurm State=powered_down
#    you must do "scontrol power up <nodelist>" followed by the "scontrol reboot ...".
#
# 3. The helper scripts $update_{software,firmware}.sh are sourced to perform any necessary updates.
#
# INSTALLATION:
# Execute this script on all compute nodes at reboot time from root's crontab, for example:
# @reboot cat /root/update_down_node.sh | bash
# Note: Using "cat" protects against a possible overwrite of the script (up to 128 kB) while it is executing.
#
# CONFIGURATION:
# See the CONFIGURE section below.
#
# UPDATING: The procedure now consists of the following steps:
#
# 1. Simply do:
#    $ scontrol reboot ASAP nextstate=down <nodelist>
#    No more actions need to be taken.
#
# 2. Optional for shared (mixed,non-exclusive) nodes only:
#    Add a Slurm reservation that starts when the nodes become idle
#    so that the nodes may run other jobs by Slurm backfilling:
#    $ reserve_on_idle <nodelist> update
#    The reservation will be automatically deleted as part of the script.
#
# 3. Optional for shared nodes: You can schedule reboots with this command:
#    $ sreboot -d -r UPDATE <nodelist>
#    The sreboot command lets shared nodes accept new jobs, whereas exclusive nodes are rebooted ASAP.
#    The "-d" flag sets NextState to Down.
#    The "-r" flag sets the Reason

# We need commands from /usr/sbin
export PATH=/usr/sbin:$PATH
# Name of the present script
SCRIPTNAME="update_down_node.sh"

# Log files are written to the compute node local folder:
LOG_FILE="/root/update.log"
LOG_FILE0="/root/update_down_node.log"

##########################################################################
#
# CONFIGURE:
#
# The cluster software folders as seen from the compute nodes:
PACKAGEDIR="/home/server"
SCRIPTDIR="$PACKAGEDIR/scripts-dir"
# Determine the directory $RPMDIR where we store platform-specific packages for the nodes.
# For example, we use directories "RPMS8" and "RPMS9" for EL8 and EL9, respectively.
RPMDIR_EL8="$PACKAGEDIR/RPMS8"
RPMDIR_EL9="$PACKAGEDIR/RPMS9"
# The $update_scripts live in the remote $SCRIPTDIR and will be copied to the local /root
# If you do not want to update any firmwares, simply remove update_firmware.sh from this list
update_scripts="update_software.sh update_firmware.sh"
# Maximum number of seconds to wait for slurmd and for the NFS mount:
WAIT_TIMEOUT=600

##########################################################################
#
# First we define some helper functions
#
# Stop without updating this node. Exit status 0 means cron does not send an error mail.
#
function skip_updates()
{
	echo "NOTICE: No updates will be performed on this node${1:+: $1}"
	exit 0
}

# Run a command repeatedly until it succeeds, or give up after $WAIT_TIMEOUT seconds.
# Usage: wait_for <sleep-seconds> <description> <command> [args...]
#
function wait_for()
{
	local interval=$1 description=$2
	shift 2
	local start=$SECONDS
	until "$@" > /dev/null 2>&1
	do
		if (( SECONDS - start > WAIT_TIMEOUT ))
		then
			echo "ERROR: Gave up waiting for $description after $((SECONDS - start)) seconds"
			return 1
		fi
		echo "$(date): Waiting for $description ..."
		sleep "$interval"
	done
	return 0
}

# This function verifies that slurmd is installed, up, and started on the node.
#
function check_slurmd()
{
	if ! rpm -q slurm-slurmd > /dev/null
	then
		echo "ERROR: The slurm-slurmd RPM package is not installed"
		return 1
	fi
	wait_for 5 "slurmd to start" scontrol show slurmd
}

# This function checks the fileserver remote mounted directory
#
function check_fileserver()
{
	wait_for 10 "NFS mount of PACKAGEDIR=$PACKAGEDIR" test -d "$PACKAGEDIR"
}

# This function prints the value of a "Key=Value" field from the saved "scontrol show node"
# output in the $node_info variable.
# The value is lowercased and is empty if the field is missing.
#
function node_field()
{
	awk -v key="$1" '$1 ~ "^" key "=" { sub("^" key "=", "", $1); print tolower($1); exit }' <<< "$node_info"
}

##########################################################################
#
# Main program
#
# Phase 1 (decide whether to update) appends to $LOG_FILE0.
exec >> "$LOG_FILE0" 2>&1

echo "============================"
# Record the timestamp of script execution
date

# Wait for network startup at reboot since this can take a number of seconds
echo "Ask NetworkManager whether the network startup is complete"
nm-online --wait-for-startup

# Startup of slurmd can potentially take 1-2 minutes on GPU nodes
echo "Checking the slurmd service"
date
check_slurmd || skip_updates "slurmd is not running"
echo "OK: slurmd is now fully started"

# Ask slurmd about this node's hostname
shortname=$(scontrol show slurmd | awk '/Hostname/ {print $3}')
[[ -n $shortname ]] || skip_updates "Could not get the hostname from slurmd"

node_info=$(scontrol show node "$shortname")
state=$(node_field State)            # e.g. down, down+reserved, idle
nextstate=$(node_field NextState)    # down, resume, or empty if not set
reason=$(grep -m1 '^ *Reason=' <<< "$node_info" | sed 's/^ *//')   # may be empty
echo "INFO: Node $shortname has State=$state, NextState=$nextstate, $reason"

##########################################################################
#
# Act on various Slurm state and reason information
#
if [[ $reason == *"Node unexpectedly rebooted"* ]]
then
	skip_updates "$reason"
elif [[ $nextstate == *resume* ]]
then
	skip_updates "NextState=$nextstate"
elif [[ $state != *down* ]]
then
	# Matching *down* also covers combined states such as down+reserved
	skip_updates "State=$state is not down"
fi

# Find the $RPMDIR for our OS platform
source /etc/os-release
case "$PLATFORM_ID" in
	*el8*)	RPMDIR=$RPMDIR_EL8 ;;
	*el9*)	RPMDIR=$RPMDIR_EL9 ;;
	*)	echo "ERROR: OS platform PLATFORM_ID=$PLATFORM_ID is not configured"
		exit 1 ;;
esac

# Check if the fileserver $SCRIPTDIR directory is mounted
check_fileserver || skip_updates "PACKAGEDIR=$PACKAGEDIR is not mounted"
echo "OK: Fileserver directory $SCRIPTDIR is mounted"

# Copy up-to-date $update_scripts files from the fileserver to local disk
for scr in $update_scripts
do
	echo "Copy the $scr script from the remote server $SCRIPTDIR"
	if [[ -s "$SCRIPTDIR/$scr" ]]
	then
		cp "$SCRIPTDIR/$scr" /root/
	else
		skip_updates "Update script $SCRIPTDIR/$scr not found"
	fi
done

echo "All checks passed: $SCRIPTNAME will now perform updates, see $LOG_FILE"

##########################################################################
#
# Phase 2 (do the updates and reboot) writes to $LOG_FILE.

# Redirect stdout and stderr to $LOG_FILE (overwrite) instead of the crontab output to mail
exec > "$LOG_FILE" 2>&1

# Source the $update_scripts in /root which perform the actual updating
for scr in $update_scripts
do
	source /root/"$scr"
done

##########################################################################
#
# Updates have been completed, now reboot and resume the node
#

echo
echo "Script $SCRIPTNAME: Reboot this node $shortname at $(date)"

# NOTICE: It is required that slurmd is running for "scontrol reboot" to work!
echo
echo "Check if the slurmd service is still running:"
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
scontrol delete ReservationName="update-$shortname"

# Reboot the node with Slurm
echo
echo "Rebooting the node with Slurm, setting NextState=resume"
scontrol reboot nextstate=resume reason=Update_done "$shortname"

exit 0
