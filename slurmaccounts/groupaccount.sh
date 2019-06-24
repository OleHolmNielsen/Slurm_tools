#!/bin/sh

# This script lists users whose UNIX group has no corresponding Slurm account.
# The Slurm user's Slurm account is queried and a list of UNIX group versus Slurm account is produced.

echo Listing users whose UNIX group has no corresponding Slurm account
echo

# Use a cache file if available
if test ! -f no_slurm_account
then
	echo Generating no_slurm_account file
        ./slurmusersettings | grep 'has no corresponding Slurm account' | awk '{print $9, $5}' | sort | uniq | sed /:/s/// > no_slurm_account
fi

cat no_slurm_account | awk '
{
        cmd = "sacctmgr -nor show assoc user=" $2 " format=Account"
        account=""
        while (( cmd | getline account ) > 0) {
                if (account=="") account="(no_account)"
                printf("%s %s %s\n", $1, $2, account)
        } 
        close(cmd)
        if (account=="") printf("### Group %s user %s account No_account\n", $1, $2)
}' > /tmp/accountlist

cat <<EOF
Count	UNIX Group	Slurm Account
=======	==========	=============
EOF

cat /tmp/accountlist | sed '/###/d' | awk '
{
	printf("%s\t\t%s\n", $1, $3)
}' | sort | uniq -c
