#!/bin/bash

# This script is used for updating softwares on a Slurm compute node:
# - RPM packages
#
# It is intended that this script is sourced by the script update_down_node.sh
# which should be started by crontab at reboot time.
#
# NOTE: Any system-specific firmware update commands must be edited suitably for 
# each individual node hardware as indicated by our examples below.
# Prerequisite RPM packages: dmidecode hostname

echo "Running $0 script at `date`"

# Detect OS version and platform
echo
echo "Detect the OS version (see man os-release)"
source /etc/os-release
osversion=`echo $CPE_NAME | awk -F: '{print int($5)}'`
echo "OS version is: $osversion"
# Determine the OS platform of this node
platform=`grep PLATFORM_ID /etc/os-release`

# Determine the directory RPMDIR where we store platform-specific packages for the nodes
if [[ $platform =~ "el8" ]]
then
	RPMDIR=$PACKAGEDIR/RPMS8
elif [[ $platform =~ "el9" ]]
then
	RPMDIR=$PACKAGEDIR/RPMS9
else
	echo "OS platform $platform is not recognized"
	exit 1
fi

if [[ -d $RPMDIR ]]
then
	echo "Contents of RPM directory $RPMDIR:"
	ls -l $RPMDIR
else
	echo "ERROR: RPM directory $RPMDIR not found"
	exit 1
fi

# Update from local RPM packages in stead of making remote repo downloads.
# List of package name patterns:
for p in Lmod cpuid apptainer freeipmi slurm 
do
	echo "Update the $p packages"
	dnf -y update $RPMDIR/$p*rpm
done

# Make a standard "dnf update" command
echo
echo "Running dnf clean all"
dnf clean all
echo "Running dnf update"
dnf -y update

# OPTIONAL:
# The yum repo files may have been reinstalled by the above dnf update
echo "Remove original Almalinux and RockyLinux yum repo files again"
rm -f /etc/yum.repos.d/almalinux-*
rm -f /etc/yum.repos.d/Rocky-*
dnf clean all
echo "Contents of /etc/yum.repos.d"
ls -la /etc/yum.repos.d

echo
echo "Finished $0 script at `date`"
