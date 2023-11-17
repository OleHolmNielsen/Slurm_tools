#!/bin/bash -x

# Updating firmware and RPMs on a set of Slurm compute nodes.
# NOTE: The firmware update commands must be edited to fit the node hardware.

# Copy the present file to the compute nodes:
# clush -bw <nodelist> --copy update.sh --dest /root/
#
# On the compute nodes append this crontab entry:
# clush -bw <nodelist> 'echo "@reboot root /bin/bash /root/update.sh" >> /etc/crontab'
# Duplicate crontab lines should be avoided, but are caught using the STOP_FILE below.
#
# Then reboot the nodes with:
# scontrol reboot ASAP nextstate=DOWN reason=UPDATE <nodelist>
#
# After updating has completed, check the status of the DOWN nodes by:
# clush -bw@slurmstate:down 'uname -r; nhc; dmidecode -s bios-version'
# When the node has been updated and tested, resume nodes by:
# scontrol update nodename=<nodelist> state=resume
#
# Alternatively, you can add this line at the end of this script:
# scontrol reboot nextstate=resume `hostname -s`

LOCK_FILE="/root/update.lock"
LOG_FILE="/root/update.log"
STOP_FILE="/root/update.done"

# Configure: Where RPM packages and drivers live:
PACKAGEDIR=/home/que

# Function for running a Dell PowerEdge .BIN update file
# We assume update files to be in the folder .../PowerEdge/system-product-name/
# Usage: dell_update system-product-name BIN-file [options]
function dell_update()
{
	file=$PACKAGEDIR/PowerEdge/$1/$2
	options="$3"
	echo
	echo Dell $1 update file $file with option $options
	# Check for the .BIN extension
	if [[ ${file: -4} != ".BIN" ]]
	then
		echo ERROR: File $file does not have the .BIN extension
	elif test -x $file
	then
		# Execute the update package in quick-mode
		$file -q $options
		echo Update completed
	else
		echo ERROR: Update file $file was not found or is not executable
		ls -l $file
	fi
}

# Clean up /etc/crontab
function crontab_cleanup ()
{
	echo
	echo Remove the crontab entry for /root/update.sh
	/bin/cat /etc/crontab | /bin/grep -v /update.sh > /etc/crontab.tmp
	# Could do: chcon --reference=/etc/crontab /etc/crontab.tmp
	# Use cp to preserve the SELinux context
	/bin/cp /etc/crontab.tmp /etc/crontab
	/bin/rm /etc/crontab.tmp 
	echo Crontab file is now:
	# The correct SELinux context may be set by:
	# chcon system_u:object_r:system_cron_spool_t:s0 /etc/crontab
	ls -l /etc/crontab
	ls -Z /etc/crontab
	cat /etc/crontab
}

# Check for a lock file and exit if it exists.
# Duplicates may happen if multiple lines have been added to /etc/crontab by mistake.
# Sleep a random number of microseconds in order to avoid a race condition:
usleep $RANDOM
if [ -e $LOCK_FILE ]
then
	echo "ERROR: Stop file $LOCK_FILE already exists, exiting..."
	exit 0
else
	touch $LOCK_FILE
fi

# Remove any previous stop file
rm -f $STOP_FILE

# Redirect stdout and stderr
exec 1>$LOG_FILE
exec 2>&1

echo "Running $0 script at `date`"

if [ ! `rpm -q dmidecode` ]
then
	echo ERROR: The dmidecode package is absent, please install it.
	exit 1
fi

echo
echo "Ask NetworkManager whether the network startup is complete"
nm-online --wait-for-startup

# Detect OS version
if [ -s /etc/os-release ]
then
	echo
	echo "Detect the OS version (see man os-release)"
	. /etc/os-release
	osversion=`echo $CPE_NAME | awk -F: '{print int($5)}'`
	echo "OS version is: $osversion"
fi

# YUM update

echo
echo Running yum clean all
yum clean all
echo Running yum update
yum -y update

# BIOS updates (system product specific)

# Determine the system product name
product="`dmidecode -s system-product-name`"
echo
echo "This node's system product name is $product"

# Reboot after BIOS update
if [ "$product" == "PowerEdge C6420" ]
then
	dell_update C6420 BIOS_RHYDH_LN64_2.12.2.BIN -r
elif [ "$product" == "PowerEdge R640" ]
then
	dell_update R640 BIOS_4CRD2_LN64_2.12.2.BIN -r
elif [ "$product" == "PowerEdge R650" ]
then
	dell_update R650 BIOS_CNDYW_LN64_1.3.8.BIN -r
fi

# Dell PowerEdge iDRAC firmware update and Dell System Update (DSU)

if [ "`dmidecode -s system-family`" == "PowerEdge" ]
then
	dell_update iDRAC iDRAC-with-Lifecycle-Controller_Firmware_7CH5T_LN64_5.00.10.00_A00.BIN
	ipmitool bmc info
	echo
	echo Running Dell System Update
	if test -x /usr/sbin/dsu
	then
		echo Setting up DSU
		wget -q -O - http://linux.dell.com/repo/hardware/dsu/bootstrap.cgi | bash
		echo Execute DSU
		/usr/sbin/dsu -q -u --import-public-key
	else
		echo Please install Dell System Update first
	fi
fi

# Now do the crontab cleanup
crontab_cleanup

# Create the stop-file indicating that the script has completed
touch $STOP_FILE
echo
echo "Finished $0 script at `date`"

# Remove the lock file
rm -f $LOCK_FILE

# Check if this is a Slurm compute node and then reboot it
echo
if [ `rpm -q slurm` ]
then
	shortname=`hostname -s`
	if [ -n "`sinfo -N -hn $shortname`" ]
	then
		echo Reboot and resume node by Slurm scontrol reboot
		scontrol reboot nextstate=resume $shortname
	else
		echo NOTICE: This node $shortname is not a Slurm compute node, reboot it manually.
	fi
else
	echo NOTICE: Slurm is not installed.  Reboot this node $shortname manually.
fi
