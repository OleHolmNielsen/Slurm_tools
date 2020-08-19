#!/bin/bash -x

# Updating firmware and RPMs on a set of Slurm compute nodes.
# NOTE: The firmware update commands must be edited to fit the node hardware.

# Copy the present file to the compute nodes:
# clush -bw <nodelist> --copy update.sh --dest /root/
#
# On the compute nodes append this crontab entry:
# clush -bw <nodelist> 'echo "@reboot root /bin/bash /root/update.sh" >> /etc/crontab'
#
# Then reboot the nodes with:
# scontrol reboot ASAP nextstate=DOWN reason=UPDATE <nodelist>
#
# After updating has completed, check the status of the DOWN nodes by:
# clush -bw@slurmstate:down 'uname -r; nhc; dmidecode -s bios-version'
#
# When the node has been updated and tested, resume nodes by:
# scontrol update nodename=<nodelist> state=resume

LOG_FILE="/root/update.log"
STOP_FILE="/root/update.done"

rm -f $STOP_FILE

# Redirect stdout and stderr
exec 1>$LOG_FILE
exec 2>&1

echo "Running $0 script at `date`"
echo
echo Running yum update
yum clean all
yum -y update

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

echo
echo Doing firmware updates
# Example firmware update:
# echo C6420 BIOS update with automatic reboot
# /home/Dell/C6420/BIOS_5K73K_LN_2.8.1.BIN -q

touch $STOP_FILE

echo
echo "Finished $0 script at `date`"

# echo "Rebooting..."
# /usr/sbin/shutdown -r now

echo Reboot and resume node by Slurm scontrol reboot
scontrol reboot nextstate=resume `hostname -s`
