#!/bin/sh

# Discover Infiniband network and print a Slurm topology.conf file
# Author: Ole.H.Nielsen@fysik.dtu.dk
# URL: https://ftp.fysik.dtu.dk/Slurm/slurmibtopology.sh
VERSION="slurmibtopology.sh version 0.22. Date: 09-May-2017"

# CONFIGURE the paths to the commands below (defaults are from CentOS Linux):

# Directories where commands live:
sprefix=/usr/sbin
prefix=/usr/bin

# Commands used from the infiniband-diags RPM:
IBNETDISCOVER=$sprefix/ibnetdiscover
IBSTAT=$sprefix/ibstat

# Slurm command for printing sorted hostlists
export MY_SCONTROL=$prefix/scontrol

# GNU Awk (gawk version 4 is better, but gawk version 3 should work)
MY_AWK=$prefix/gawk

# Command usage:
function usage()
{
	cat <<EOF
Usage: slurmibtopology.sh [-c]
where:
	-c: comments in the output will be filtered
	-V: Version information
	-h: Print this help information
EOF
}

# Filtering comment lines from the output:
MY_FILTER="cat"

while getopts "cVh" options; do
	case $options in
		c ) export MY_FILTER="grep -v ^#"
			;;
		V ) echo $VERSION
			exit 1;;
		h|? ) usage
			exit 1;;
		* ) usage
			exit 1;;
	esac
done
# Test for extraneous command line arguments
if test $# -gt $(($OPTIND-1))
then
	echo ERROR: Too many command line arguments: $*
	usage
	exit 1
fi

if test ! -x $IBNETDISCOVER -o ! -x $IBSTAT
then
	echo Error: Command $IBNETDISCOVER not found
	echo Please install the RPM package infiniband-diags
	exit -1
fi

if test ! -x $MY_SCONTROL
then
	echo "Notice: Command $MY_SCONTROL not found (for sorting hostlists)"
	export MY_SCONTROL=""
fi

echo Verify the Infiniband interface:

if $IBSTAT -l 
then
	echo Infiniband interface OK
else
	echo Infiniband interface NOT OK
	exit -1
fi

cat <<EOF

Generate the Slurm topology.conf file for Infiniband switches.

Beware: The Switches= lines need to be reviewed and edited for correctness.
Read also https://slurm.schedmd.com/topology.html

EOF

# Discover IB switches (-S) and ports (-p):
$IBNETDISCOVER -S -p | $MY_AWK '
BEGIN {
	# Read the required environment variables:
        scontrol=ENVIRON["MY_SCONTROL"]	
}

# Define a hostname collapse function:
function collapse_list(list)
{
	if (scontrol == "") {
		return list	# No scontrol command: collapse cannot be done
	} else {
		# Collapse the list: Slurm command for sorting hostlists nicely
		cmd = scontrol " show hostlistsorted " list
		cmd | getline sortedlist
		close (cmd)
		return sortedlist
	}
}

$1 == "SW" {
	guid = $4			# Switch GUID
	linkwidth = $5
	split($0,comment,"\047")	# Split line at single-quotes (octal \047) to get comment fields
	swdesc = comment[2]		# First field in '' is the switch node description
	nodedescription = comment[4]	# Second field in '' is the neighbor node description
	if (nswitch == 0 || switchguid[nswitch] != guid) {
		nswitch++		# A new switch
		switchguid[nswitch] = guid	# We have to identify switches by their GUID
		switchnum[guid] = nswitch	# Index switches by GUID
		switchdescription[nswitch] = swdesc	# Switch description
		SEP = ""		# Hostlist separator
	}
	if (linkwidth == "??") next		# Skip inactive link
	neighbortype = $8
	neighborguid = $11
	if (neighbortype == "CA") {		# Host link "CA" (HCA)
		linkcount[nswitch,neighbortype]++
		split(nodedescription, desc, " ")
		hostname = desc[1]			# First item in nodedescription should be the hostname
		neighborlist[nswitch,hostname]++	# Count number of links to this hostname
		if (neighborlist[nswitch,hostname] == 1) {
			# Append hostname to list (only once per host in case it has multiple links)
			hostlist[nswitch] = hostlist[nswitch] SEP hostname
			SEP = ","	# Hostlist separator
		}
	} else if (neighbortype == "SW") {	# Switch link "SW"
		linkcount[nswitch,neighborguid]++
		switchneighbor[nswitch,neighborguid] = neighborguid
	}
} END {

	# Select a switch name prefix, initialize switchname list
	switchprefix="ibsw"
	for (i=1; i<=nswitch; i++) {
		switchname[i] = switchprefix sprintf("%d", i)
	}

	# Loop over switches
	for (i=1; i<=nswitch; i++) {
		HSEP = ""	# Hostlist separator
		printf("#\n# IB switch no. %d: %s GUID: %s Description: %s\n#\n", i, switchname[i], switchguid[i], switchdescription[i])
		totallinks = 0
		# With GAWK v4 the loop is simply: for (l in linkcount[i]) {
		# With GAWK v3 you need to manipulate indices yourself:
		# Print the switch-to-switch link list:
		for (ind in linkcount) {
			split (ind, t, SUBSEP)
			if (t[1] != i) continue
			l = t[2]
			totallinks += linkcount[i,l]
			print "# Switch neighbor ", l, " with " linkcount[i,l] " links"
		}
		print "# Total number of links in this switch = ", totallinks

		# Notice: Slurm topology.conf SwitchName lines can either contain Nodes= OR Switches=
		# See https://slurm.schedmd.com/topology.conf.html
		if (hostlist[i] == "") {
			# A top-level switch with no leaf compute nodes
			print "# NOTICE: This switch " switchname[i] " has no attached nodes (empty hostlist)"
			# Gather list of switches with links to this switch
			switchlist = ""
			SWSEP = ""	# Switch list separator
			for (ind in switchneighbor) {
				split (ind, t, SUBSEP)
				if (t[1] != i) continue
				n = t[2]
				neighborguid = switchneighbor[i,n]
				switchlist = switchlist SWSEP switchname[switchnum[neighborguid]]
				SWSEP = ","	# Switch list separator
			}
			printf("SwitchName=%s Switches=%s\n", switchname[i], collapse_list(switchlist))
		} else {
			printf("SwitchName=%s Nodes=%s\n", switchname[i], collapse_list(hostlist[i]))
			HSEP = ","	# Hostlist separator
			allswitches = allswitches "," switchname[i]
		}
	}
	# printf("#\n# Merging all switches in a top-level spine switch\n#\n")
	# print "SwitchName=spineswitch Switches=" collapse_list(allswitches)
}' | $MY_FILTER
