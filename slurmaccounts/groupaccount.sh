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
BEGIN {
        # Read list of existing accounts (parseable output)
        command="/usr/bin/sacctmgr -nrp show accounts WithAssoc format=Account,User"
        FS="|"  # Set the Field Separatator to | for the account list
        while ((command | getline) > 0) {
		a = $1
		u = $2
                if (a == "root") continue      # Ignore the root account
                account[u][a]     = a	# Each user may have multiple accounts
                # Debug: print "Got account ", $0
        }
        close(command)
        FS=" "  # Now reset the Field Separatator
}
{
        acct=""
	g = $1
	u = $2
	if (isarray(account[u])) {
		for (i in account[u])
                	printf("%s %s %s\n", g, u, account[u][i])
	} else
        	printf("### Group %s user %s account No_account\n", g, u)
}' > /tmp/accountlist

cat <<EOF
Count	UNIX Group	Slurm Account
=======	==========	=============
EOF

cat /tmp/accountlist | sed '/###/d' | awk '
{
	printf("%s\t\t%s\n", $1, $3)
}' | sort | uniq -c
