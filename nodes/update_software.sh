# This helper script is used for updating RPM package softwares on a Slurm compute node
# It is intended that this script is sourced by the script update_down_node.sh
# which should be started by crontab at reboot time.
# The variable $RPMDIR defines the location of local RPM packages.

# List of package name patterns which we install from a local folder in stead of making remote repo downloads:
LOCALPACKAGELIST="cpuid apptainer freeipmi slurm"

if [[ -d $RPMDIR ]]
then
	echo "Contents of RPM directory $RPMDIR:"
	ls -l $RPMDIR
else
	echo "ERROR: RPM directory $RPMDIR not found"
	exit 1
fi

for p in $LOCALPACKAGELIST
do
	echo "Update the $p packages"
	dnf -y update $RPMDIR/$p*rpm
done

# Now make a standard "dnf update" command
echo
echo "Running dnf clean all"
dnf clean all
echo "Running dnf update"
dnf -y update

# OPTIONAL:

# The yum repo files may have been reinstalled by the above dnf update
echo
echo "Remove original Almalinux and RockyLinux yum repo files again"
rm -f /etc/yum.repos.d/almalinux-*
rm -f /etc/yum.repos.d/Rocky-*
dnf clean all
echo "Contents of /etc/yum.repos.d"
ls -la /etc/yum.repos.d
