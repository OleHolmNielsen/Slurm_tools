#!/bin/bash -x

# Updating firmware and RPMs on a set of Slurm compute nodes.
# NOTE: The system-specific firmware update commands must be edited suitably for the node hardware.

# Required helper scripts: clush (from ClusterShell), sreboot, reserve_on_idle

# CONFIGURE: Location where local RPM packages and drivers live:
PACKAGEDIR=/home/que
RPMDIR=$PACKAGEDIR/RPMS8

# The updating procedure consists of the following steps:
#
# 1. Copy the present file to the compute nodes:
#    $ clush -bw <nodelist> --copy update.sh --dest /root/
#
# 2. On the compute nodes append this crontab entry:
#      (Using "cat" avoids a possible overwrite of update.sh (up to 128 kB) while executing the script.)
#    $ clush -bw <nodelist> 'echo "@reboot root cat /root/update.sh | bash" >> /etc/crontab'
#
#    (Duplicate crontab lines should be avoided, but are caught using the COMPLETION_FILE below.)
#
# 3. Optional: Remove any dangling update.lock files from previous failed updates:
#    $ clush -bw <nodelist> rm -f update.lock
#
# 4. Optional: For non-exclusive nodes only, add a reservation that starts
#    when the nodes become idle so that the nodes may run other jobs
#    by Slurm backfilling until they become idle.
#    The reservation will be automatically deleted as part of the present script.
#    $ reserve_on_idle <nodelist> update
#
# 5. Then reboot the nodes with:
#    $ sreboot -d -r UPDATE <nodelist>
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
COMPLETION_FILE="/root/update.done"

# Function for running a Dell PowerEdge .BIN update file
# We assume update files to be in the folder .../PowerEdge/system-product-name/
# Usage: dell_update system-product-name BIN-file [options]
function dell_update()
{
	file=$PACKAGEDIR/PowerEdge/$1/$2
	options="$3"
	echo
	echo "Dell $1 update file $file with option $options"
	echo "Start time " `date`
	# Check for the .BIN extension
	if [[ ${file: -4} != ".BIN" ]]
	then
		echo "ERROR: File $file does not have the .BIN extension"
		return 1
	elif [ -f $file -a -x $file ]
	then
		# Determine if the update can be applied to the system (return code 0)
		if `$file -q -c > /dev/null` 
		then
			# Execute the update package in quick-mode
			$file -q $options
			echo "Update completed"
			echo "Completion time " `date`
			return 0
		else
			echo "The update $file cannot be applied to this system"
			return 3
		fi
	else
		echo "ERROR: Update file $file was not found or is not executable"
		ls -l $file
		return 1
	fi
}

# Function for running a Lenovo update file using Lenovo "OneCLI"
# https://support.lenovo.com/us/en/solutions/ht116433-lenovo-xclarity-essentials-onecli-onecli
# We assume update files to be in the folder .../Lenovo/<system-product-name>/<firmware-name>
# Usage: lenovo_update <system-product-name> <subdir> <firmware-file>
# where the firmware-file extension is omitted like this example: lnvgy_fw_uefi_qge124h-5.20_anyos_comp
function lenovo_update()
{
	fwdir=$PACKAGEDIR/Lenovo/$1/$2
	file="$3"
	payload=$fwdir/payloads/$file.uxz
	echo
	echo "Lenovo $1 update file $file"
	echo "Start time " `date`
	if [ -f $payload ]
	then
		echo "OneCLI installing payload file $payload"
		# The OneCLI logfiles will be in /tmp
		echo onecli update flash --scope individual --dir $fwdir --nocompare  --includeid $file --output /tmp --quiet
		onecli update flash --scope individual --dir $fwdir --nocompare  --includeid $file --output /tmp --quiet
		echo "Update completed"
		echo "Completion time " `date`
		return 0
	else
		echo "ERROR: Update payload file $payload was not found"
		ls -l $fwdir
		return 1
	fi
}

function lenovo_mellanox_update()
{
	fwdir=$PACKAGEDIR/Lenovo/$1
	file="$2"
	echo
	echo "Lenovo $1 update file $file"
	echo "Start time " `date`
	if [ -x $file ]
	then
		# Execute the Mellanox firmware for Lenovo update file
		yes | $fwdir/$file
		echo "Update completed"
		echo "Completion time " `date`
		return 0
	else
		echo "ERROR: Update executable file $file was not found"
		ls -l $fwdir
		return 1
	fi
}

# Clean up /etc/crontab
function crontab_cleanup ()
{
	if [[ $# -ne 1 ]]
	then
		echo "Usage: clean_crontab <string-to-remove>"
		return
	fi
	echo
	echo "Remove the crontab entry for $1"
	/bin/cat /etc/crontab | /bin/grep -v $1 > /etc/crontab.tmp
	# Could do: chcon --reference=/etc/crontab /etc/crontab.tmp
	# Use cp to preserve the SELinux context
	# Make a backup copy
	/bin/cp -p /etc/crontab /etc/crontab.BAK
	/bin/cp /etc/crontab.tmp /etc/crontab
	/bin/rm /etc/crontab.tmp 
	echo "Crontab file is now:"
	# The correct SELinux context may be set by:
	# chcon system_u:object_r:system_cron_spool_t:s0 /etc/crontab
	ls -l /etc/crontab
	ls -Z /etc/crontab
	cat /etc/crontab
}

# Wipe old messages in the Sendmail clientmqueue and restart Sendmail service during the update
systemctl stop sendmail
rm -f /var/spool/clientmqueue/*
systemctl restart sendmail

# Check for a lock file and possibly exit if it exists.
# Duplicates may happen if multiple lines have been added to /etc/crontab by mistake.
# Sleep a random number of microseconds in order to avoid a race condition:
# (Bash cannot perform floating-point arithmetic, so use awk)
sleep `awk -v ran=$RANDOM 'BEGIN{printf("%10.6f\n"), ran / 1000000}'`
# Note: The usleep command is now deprecated: usleep $RANDOM
if [ -e $LOCK_FILE ]
then
	# Check the age in seconds of LOCK_FILE, since it may be a leftover from a previous failed update
	locktime=`stat -c "%Y" $LOCK_FILE`
	now=`date -d now +%s`
	lockage=$(($now-$locktime))
	maxage=60
	if [[ $lockage -lt $maxage ]]
	then
		echo "ERROR: Stop file $LOCK_FILE already exists (aged $lockage seconds), exit this script..."
		ls -l $LOCK_FILE
		exit 0
	else
		echo "NOTICE: An outdated file $LOCK_FILE already exists, ignore it..."
		echo "The file age $lockage is greater than $maxage seconds"
		ls -l $LOCK_FILE
	fi
fi
touch $LOCK_FILE

# Remove any previous completion file
rm -f $COMPLETION_FILE

# Redirect stdout and stderr to the logfile
exec 1>$LOG_FILE
exec 2>&1

echo "Running $0 script at `date`"
echo
echo "Ask NetworkManager whether the network startup is complete"
nm-online --wait-for-startup

echo "Check availability of NFS-mounted PACKAGEDIR=$PACKAGEDIR"
sleep 10
if [[ ! -d $PACKAGEDIR ]]
then
	echo "WARNING: PACKAGEDIR=$PACKAGEDIR is not mounted"
	echo "Sleep and retry filesystem mount..."
	sleep 90
	if [[ ! -d $PACKAGEDIR ]]
	then
		echo "ERROR: PACKAGEDIR=$PACKAGEDIR is not mounted"
		echo "ERROR: PACKAGEDIR=$PACKAGEDIR is not mounted" | mail -s update.sh root
	fi
	ls -l $PACKAGEDIR
	exit 1
fi

if [ ! `rpm -q dmidecode` ]
then
	echo "WARNING: The dmidecode package is absent: installing it."
	dnf -y install dmidecode
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

# --------------------------------------------------------
# RPM package updates
# Update from local RPM packages in stead of making EPEL repo downloads
echo "Update the Lmod package"
dnf -y update $RPMDIR/Lmod*rpm
echo "Update the cpuid package"
dnf -y update $RPMDIR/cpuid*rpm
echo "Update the apptainer package"
dnf -y update $RPMDIR/apptainer*rpm
echo "Update the freeipmi package"
dnf -y update $RPMDIR/freeipmi-1.6*rpm
# echo "Update the munge package"
# dnf -y update $RPMDIR/munge*rpm

# OPTIONAL:
# echo "Remove original Almalinux and RockyLinux yum repo files"
# rm -f /etc/yum.repos.d/almalinux-*
# rm -f /etc/yum.repos.d/Rocky-*
# --------------------------------------------------------

echo
echo Running dnf clean all
dnf clean all
echo Running dnf update
dnf -y update

# OPTIONAL:
# The yum repo files may have been reinstalled by the above dnf update
# echo "Remove original Almalinux and RockyLinux yum repo files again"
# rm -f /etc/yum.repos.d/almalinux-*
# rm -f /etc/yum.repos.d/Rocky-*
# rm -f /etc/yum.repos.d/CornelisOPX.*
# rm -f /etc/yum.repos.d/*.rpmnew
# echo "Contents of /etc/yum.repos.d"
# ls -la /etc/yum.repos.d

# --------------------------------------------------------
#
# BIOS updates (system product specific)

# Determine the system product name etc.
product="`dmidecode -s system-product-name`"
family="`dmidecode -s system-family`"
manufacturer="`dmidecode -s system-manufacturer`"

echo
echo "This node's system product name is $product"

# --------------------------------------------------------
#
# Dell Poweredge server updates for C6420, R640, R650

if [ "$family" == "PowerEdge" ]
then
	# Update Dell DSU and racadm packages
	dnf -y install $RPMDIR/srvadmin-*rpm $RPMDIR/dell-system-update*rpm
	# If RPM packages are unavailable, try to run this
	# dell_update DSU Systems-Management_Application_RXKJ5_LN64_2.2.0.1_A00.BIN
	# Enable running of Dell System Update (DSU), the default is disabled
	# run_dsu=1
	run_dsu=0
	# Get firmware versions
	export RACADM=/opt/dell/srvadmin/bin/idracadm7
	$RACADM getversion
	$RACADM getversion -c
fi

if [ "$product" == "PowerEdge C6420" ]
then
	dell_update C6420 iDRAC-with-Lifecycle-Controller_Firmware_VP556_LN64_7.00.00.183_A00.BIN
	dell_update C6420 BIOS_FPF49_LN64_2.26.0.BIN
	$RACADM getversion
	$RACADM getversion -c
elif [ "$product" == "PowerEdge R640" ]
then
	dell_update R640 iDRAC-with-Lifecycle-Controller_Firmware_VP556_LN64_7.00.00.183_A00.BIN
	dell_update R640 BIOS_W23XX_LN64_2.26.1.BIN
	$RACADM getversion
	$RACADM getversion -c
elif [ "$product" == "PowerEdge R650" ]
then
	dell_update R650 DRAC-with-Lifecycle-Controller_Firmware_924YT_LN64_7.30.10.50_A00.BIN
	dell_update R650 BIOS_GWT21_LN64_1.20.2.BIN
	$RACADM getversion
	$RACADM getversion -c
fi

# Dell PowerEdge iDRAC firmware update and Dell System Update (DSU)

if [ "$family" == "PowerEdge" ]
then
	ipmitool bmc info
	echo
	echo Running Dell System Update
	if [ $run_dsu -eq 0 ]
	then
		echo "DSU is omitted in this script"
	elif [[ -x /usr/sbin/dsu ]]
	then
		echo "Setting up DSU"
		wget -q -O - http://linux.dell.com/repo/hardware/dsu/bootstrap.cgi 
		yes | bash bootstrap.cgi
		echo "Execute DSU"
		/usr/sbin/dsu -q -u --import-public-key --ignore-signature
	else
		echo Please install Dell System Update first
	fi
fi

# --------------------------------------------------------
#
# Lenovo ThinkSystem servers: SD665 V3, SR850 V3, SD650-N V2 and V3
# If applicable, Lenovo firmware zip-files must be unpacked to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2

# Notes about SD665 V3 left and right nodes:
#   The clush command can perform commands with increments, for example:
#   clush -bw e[001-023/2] echo I am a left-hand node
#   clush -bw e[002-024/2] echo I am a right-hand node
# Unfortunately, Slurm doesn’t recognize this syntax of node number increments.
# Here you can use the ClusterShell_tool’s command nodeset to print Slurm compatible nodelists
# to be used as Slurm command arguments:
# $ nodeset -f e[001-024/2]
# e[001,003,005,007,009,011,013,015,017,019,021,023]
# $ nodeset -f e[002-024/2]
# e[002,004,006,008,010,012,014,016,018,020,022,024]

if [ "$product" == "ThinkSystem SD665 V3" ]
then
	echo "Firmware updates for $manufacturer $product"
	# echo "Update the OneCLI RPM"
	# dnf -y update $PACKAGEDIR/Lenovo/OneCLI/lnvgy_utl_lxcer_onecli*_linux_indiv.rpm
	# lenovo_update SD665V3 XCC lnvgy_fw_xcc_qgx394l-14.12_anyos_comp
	# lenovo_update SD665V3 XCC lnvgy_fw_xcc_qgx3a6g-15.10_anyos_comp
	# lenovo_update SD665V3 UEFI lnvgy_fw_uefi_qge144d-8.40_anyos_comp
	# lenovo_mellanox_update SD665V3 mlxfwmanager_LES_24B_OFED-24.10-1_build5
	# lenovo_mellanox_update SD665V3 mlxfwmanager_LES_25B_DOCA_3.2.0_build3
	# At this point stop the slurmd service because we must make Virtual Reseat of the nodes.
	# We do not want Slurm to resume the node after a reboot
	# echo "Stopping the slurmd service.  The node must make a Virtual Reseat"
	# systemctl stop slurmd
	# lenovo_update SD665V3 LXPM lnvgy_fw_lxpm_gnl122c-4.20.04_anyos_comp
	# lenovo_update SD665V3 LXUM lnvgy_fw_lxum_eal506l-1.14_anyos_comp
	# lenovo_update SD665V3 LXUM lnvgy_fw_lxum_eal506m-1.15_anyos_comp
fi

# The Lenovo firmware zip-files must be unpacked to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2
if [ "$product" == "ThinkSystem SR850 V3" ]
then
	echo "Firmware updates for $manufacturer $product"
	dnf -y update $PACKAGEDIR/Lenovo/OneCLI/lnvgy_utl_lxcer_onecli*_linux_indiv.rpm
	# lenovo_update SR850V3 XCC lnvgy_fw_xcc_rsx312i-4.10_anyos_comp
	# lenovo_update SR850V3 UEFI lnvgy_fw_uefi_rse112g-3.20_anyos_comp
fi

if [ "$product" == "ThinkSystem SD650-N V2" ]
then
	# For Lenovo V2 servers only:
	# The firmware files .UXZ and .XML must be copied to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2/payloads/
	echo "Firmware updates for $manufacturer $product"
	dnf -y update $PACKAGEDIR/Lenovo/OneCLI/lnvgy_utl_lxcer_onecli*_linux_indiv.rpm
	# lenovo_update SD650N-V2 XCC lnvgy_fw_xcc_tgbt58d-6.10_anyos_noarch
	# lenovo_update SD650N-V2 UEFI lnvgy_fw_uefi_u8e134f-3.30_anyos_32-64
	# lenovo_update SD650N-V2 LXPM lnvgy_fw_lxpm_xwl130j-3.31.01_anyos_noarch
fi

if [ "$product" == "ThinkSystem SD650-N V3" ]
then
	# For Lenovo V3 servers only:
	# The firmware files .UXZ and .XML must be copied to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2/payloads/
	echo "Firmware updates for $manufacturer $product"
	# dnf -y update $PACKAGEDIR/Lenovo/OneCLI/lnvgy_utl_lxcer_onecli*_linux_indiv.rpm
	# lenovo_update SD650N-V3 XCC 
	# lenovo_update SD650N-V3 UEFI 
	# lenovo_update SD650N-V3 LXPM 
fi

# --------------------------------------------------------

# Finished all firmware updates: Now do the crontab cleanup
crontab_cleanup update.sh

# Create the stop-file indicating that the script has completed
touch $COMPLETION_FILE
echo
echo "Finished $0 script at `date`"

# Remove the lock file
rm -f $LOCK_FILE

# --------------------------------------------------------

# Check if this is a Slurm compute node and then reboot it

echo
echo "Reboot this node `hostname` at `date`"
echo
echo -n "Check the slurm rpm package: "

if rpm -q slurm
then
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
	echo
	shortname=`hostname -s`
	if [[ -n "`sinfo -N -hn $shortname`" ]]
	then
		# Remove this node from any possible update related reservations.
	       	# The magic reservation name is set by the reserve_on_idle script.
		# If the node is not in a # reservation, the delete command
		# will just print a warning message and continue.
		echo "Deleteting reservation update-$shortname if it exists"
		scontrol delete ReservationName=update-$shortname

		NEXTSTATE=resume
		echo "Next Slurm node state is: $NEXTSTATE"
		echo "Reboot node by Slurm scontrol reboot, setting nextstate=$NEXTSTATE"
		scontrol reboot nextstate=$NEXTSTATE reason=Update_done $shortname
	else
		echo "NOTICE: This node $shortname is not a Slurm compute node, reboot it manually."
		echo "Reboot the node immediately"
		shutdown -r now
	fi
else
	echo "NOTICE: Slurm is not installed.  Reboot this node $shortname manually."
	echo "Reboot the node immediately"
	shutdown -r now
fi

