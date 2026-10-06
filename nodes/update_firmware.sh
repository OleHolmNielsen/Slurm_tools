#!/bin/bash

# This script is used for updating system firmwares on a Slurm compute node.
#
# It is intended that this script is sourced by the script update_down_node.sh
# which should be started by crontab at reboot time.
#
# NOTE: Any system-specific firmware update commands must be edited suitably for 
# each individual node hardware as indicated by our examples below.
# Prerequisite RPM packages: dmidecode hostname

##########################################################################
#
# First define some vendor-specific firmware update functions to be used below:
#
# DELL servers
#
# Function for running a Dell PowerEdge .BIN Linux update file.
# Update files should be located in the $PACKAGEDIR subfolder Dell/<system-product-name>/
function dell_update()
{
	# Usage: dell_update <system-product-name> <BIN-file> [options]
	file=$PACKAGEDIR/Dell/$1/$2
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

#
# LENOVO servers
#
# Function for running a Lenovo firmware update file using the Lenovo "OneCLI" tool from
# https://support.lenovo.com/us/en/solutions/ht116433-lenovo-xclarity-essentials-onecli-onecli
# Note: OneCLI 5.7.0 has a bug which causes the command to fail.  Please use a different version.
# Update files should be in the subfolder Lenovo/<system-product-name>/<firmware-name>/
function lenovo_update()
{
	# Usage: lenovo_update <system-product-name> <subdir> <firmware-file>
	# where the firmware-file extension is omitted like this example:
	# lnvgy_fw_uefi_qge124h-5.20_anyos_comp
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

# Update NVIDIA/Mellanox network adapter firmware
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

##########################################################################

echo "Running $0 script at `date`"

##########################################################################
#
# BIOS/UEFI/BMC and other system firmware updates (these are system product specific)
#

# Determine the system product name etc.
product="`dmidecode -s system-product-name`"
family="`dmidecode -s system-family`"
manufacturer="`dmidecode -s system-manufacturer`"

cat <<EOF

=========================================================================
This node's system product name is $product manufactured by $manufacturer

EOF

##########################################################################
#
# Dell Poweredge server updates for C6420, R640, R650
# Dell downloads: https://linux.dell.com/repo/hardware/dsu/os_independent/x86_64/

if [ "$family" == "PowerEdge" ]
then
	# Update Dell DSU and racadm packages from the $RPMDIR folder
	dnf -y install $RPMDIR/srvadmin-*rpm $RPMDIR/dell-system-update*rpm
	# If RPM packages are unavailable, try to run this
	dell_update DSU Systems-Management_Application_VHT96_LN64_2.3.0.1_A00.BIN
	# Enable running of Dell System Update (DSU), the default is disabled
	# run_dsu=1
	run_dsu=0
	# Get firmware versions
	export RACADM=/opt/dell/srvadmin/bin/idracadm7
	$RACADM getversion
	$RACADM getversion -c
fi

# Please remember to comment out any firmware updates that have already been completed
if [ "$product" == "PowerEdge C6420" ]
then
	# dell_update C6420 iDRAC-with-Lifecycle-Controller_Firmware_K7H6Y_LN64_7.00.00.185_A00.BIN
	# dell_update C6420 BIOS_YF09V_LN64_2.28.1.BIN
	# dell_update C6420 Network_Firmware_PJDHV_LN_25.0.4_A00.BIN
	$RACADM getversion
	$RACADM getversion -c
elif [ "$product" == "PowerEdge R640" ]
then
	# dell_update R640 iDRAC-with-Lifecycle-Controller_Firmware_K7H6Y_LN64_7.00.00.185_A00.BIN
	# dell_update R640 BIOS_188CW_LN64_2.28.1.BIN
	# dell_update R640 Network_Firmware_WKRW3_LN64_23.71.1.BIN
	$RACADM getversion
	$RACADM getversion -c
elif [ "$product" == "PowerEdge R650" ]
then
	# dell_update R650 iDRAC-with-Lifecycle-Controller_Firmware_P3PPC_LN64_7.30.30.54_A00.BIN
	# dell_update R650 BIOS_8VG5Y_LN64_1.23.1.BIN
	$RACADM getversion
	$RACADM getversion -c
fi

##########################################################################
#
# Lenovo ThinkSystem servers: SD665 V3, SR850 V3, SD650-N V2 and V3
# If applicable, Lenovo firmware zip-files must be unpacked to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2

if [ "$family" == "ThinkSystem" ]
then
	# Update ThinkSystem packages
	# The OneCLI software is downloaded from the product's software page 
	# https://datacentersupport.lenovo.com/us/en
	echo "Update the ThinkSystem OneCLI RPM"
	dnf -y install $PACKAGEDIR/Lenovo/OneCLI/lnvgy_utl_lxcer_onecli*_linux_indiv.rpm
fi

# Notes about SD665 V3 left and right nodes:
#   The clush command can perform commands with increments, for example:
#   clush -b -w e[001-023/2] echo I am a left-hand node
#   clush -b -w e[002-024/2] echo I am a right-hand node
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
	# lenovo_update SD665V3 XCC lnvgy_fw_xcc_qgx3c2o-15.50_anyos_comp
	# lenovo_update SD665V3 UEFI lnvgy_fw_uefi_qge146k-8.52_anyos_comp
	# lenovo_mellanox_update SD665V3 mlxfwmanager_LES_26A_DOCA_3.3.0_build1
	# At this point stop the slurmd service because we must make Virtual Reseat of the nodes.
	# We do not want Slurm to resume the node after a reboot
	# echo "Stopping the slurmd service.  The node must make a Virtual Reseat"
	# systemctl stop slurmd
	# lenovo_update SD665V3 LXPM lnvgy_fw_drvln_gnl224e-4.20.05_anyos_comp
	# lenovo_update SD665V3 LXUM lnvgy_fw_lxum_eal506l-1.14_anyos_comp
	# lenovo_update SD665V3 LXUM lnvgy_fw_lxum_eal506m-1.15_anyos_comp
fi

# The Lenovo firmware zip-files must be unpacked to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2
if [ "$product" == "ThinkSystem SR850 V3" ]
then
	echo "Firmware updates for $manufacturer $product"
	# lenovo_update SR850V3 XCC lnvgy_fw_xcc_rsx312i-4.10_anyos_comp
	# lenovo_update SR850V3 UEFI lnvgy_fw_uefi_rse112g-3.20_anyos_comp
fi

if [ "$product" == "ThinkSystem SD650-N V2" ]
then
	# For Lenovo V2 servers only:
	# The firmware files .UXZ and .XML must be copied to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2/payloads/
	echo "Firmware updates for $manufacturer $product"
	# lenovo_update SD650N-V2 XCC lnvgy_fw_xcc_tgbt58d-6.10_anyos_noarch
	# lenovo_update SD650N-V2 UEFI lnvgy_fw_uefi_u8e134f-3.30_anyos_32-64
	# lenovo_update SD650N-V2 LXPM lnvgy_fw_lxpm_xwl130j-3.31.01_anyos_noarch
fi

if [ "$product" == "ThinkSystem SD650-N V3" ]
then
	# For Lenovo V3 servers only:
	# The firmware files .UXZ and .XML must be copied to dedicated folders in $PACKAGEDIR/Lenovo/$1/$2/payloads/
	echo "Firmware updates for $manufacturer $product"
	# lenovo_update SD650N-V3 XCC 
	# lenovo_update SD650N-V3 UEFI 
	# lenovo_update SD650N-V3 LXPM 
fi

echo
echo "Finished $0 script at `date`"
