BINDIR=/usr/local/bin
SBINDIR=/usr/local/sbin

pestat=pestat/pestat
slurm_tools_completion=bash-completion/slurm_tools_completion.sh

usertools=showuserjobs/showuserjobs showuserlimits/showuserlimits
accountingtools=slurmacct/slurmacct slurmacct/jobstats slurmacct/topreports slurmreportmonth/slurmreportmonth

jobtools=jobs/joblist jobs/psjob jobs/showjob jobs/showjobreasons
job_admintools=jobs/jobnice jobs/jobqos jobs/jobtimelimit jobs/notifybadjob jobs/sbadjobs jobs/schedjobs jobs/sratelimit jobs/warn_maxjobs

nodetools=nodes/psnode nodes/shownode nodes/showevents nodes/showpower nodes/showpower_nvidia
node_admintools=nodes/alive nodes/alive_bmc nodes/checktopology nodes/sdrain nodes/spowerdown nodes/spowerup nodes/sreboot nodes/sresume nodes/sversion \
	       	power_save/power_ipmi power_save/nodesuspend power_save/noderesume power_save/nodefailresume

partitiontools=partitions/showpartitions partitions/showhidden

install: ${pestat} ${usertools} ${jobtools} ${nodetools} ${partitiontools} 
	cp --no-clobber $^ ${BINDIR}/

install_admintools: ${job_admintools} ${node_admintools} ${accountingtools}
	cp --no-clobber $^ ${SBINDIR}/

# ${slurm_tools_completion}: /etc/profile.d/slurm_tools_completion.sh
/etc/profile.d/slurm_tools_completion.sh: ${slurm_tools_completion}
	cp --no-clobber $^ $@

all: /etc/profile.d/slurm_tools_completion.sh install install_admintools 

