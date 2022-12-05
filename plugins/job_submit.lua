--[[
Example job_submit.lua file for Slurm from source etc/job_submit.lua.example

For more information check https://slurm.schedmd.com/job_submit_plugins.html
See also the Wiki page https://wiki.fysik.dtu.dk/niflheim/Slurm_configuration#job-submit-plugins

NOTES:
* The slurm.log_info() function logs to the slurmctld.log
  We print the "badstring" string to identify bad job submissions.
* The slurm.log_user() function prints an error message to the user's terminal.
* Slurm Error numbers are defined in the source file slurm/slurm_errno.h
* For the list of available Lua slurm.* fields check the job_desc variable
* in src/plugins/job_submit/lua/job_submit_lua.c

ERROR NUMBERS:
Error numbers are defined in the source file /usr/include/slurm/slurm_errno.h
We currently have to define error symbols manually, see https://bugs.schedmd.com/show_bug.cgi?id=14500
Only a few selected symbols ESLURM_* are exposed to the Lua script,
but from Slurm 23.02 all the error codes are exposed.
--]]

badstring="BAD:"	-- This string is printed to slurmctld.log and can be grepped for
userinfo=""
slurm.ESLURM_INVALID_PARTITION_NAME=2000
slurm.ESLURM_INVALID_NODE_COUNT=2006
slurm.ESLURM_PATHNAME_TOO_LONG=2012
slurm.ESLURM_BAD_TASK_COUNT=2025
slurm.ESLURM_INVALID_TASK_MEMORY=2044
slurm.ESLURM_INVALID_GRES=2072

--
-- Define our partitions and defaults
--
partitions = {
	-- partition name (NOTE: a substring which begins the name), number of cores, entire node is 0/1, number of gpus
	-- Multiple partitions can be lumped together, for example, xeon24, xeon24_512, xeon24_1024 as "xeon24"
	-- { partition="xeon8",  numcores=8,  entirenode=1, num_gpus=0 },
	{ partition="xeon16", numcores=16, entirenode=0, num_gpus=0 },
	{ partition="xeon24", numcores=24, entirenode=1, num_gpus=0 },
	{ partition="xeon40", numcores=40, entirenode=1, num_gpus=0 },
	{ partition="xeon56", numcores=56, entirenode=1, num_gpus=0 },
	{ partition="sm3090", numcores=80, entirenode=0, num_gpus=10 }
}
default_partition="xeon16"	-- This partition will be set if none was requested
default_nodes=1			-- Number of nodes if none was requested
default_tasks=1			-- Number of tasks if none was requested

--
-- Define functions to be used
--
script_error="ERROR: Please modify your batch job script"

-- Sanity check of partition
-- Policy: the partition must be specified by the job
function check_partition (job_desc, submit_uid, log_prefix)
	-- Informational web page
	local partitions_page="Our partitions are listed in https://wiki.fysik.dtu.dk/niflheim/Niflheim7_Getting_started#compute-node-partitions"
	local sbatch_msg="Please read the sbatch manual page about setting partitions with -p/--partition"
	local support_msg="NOTICE: Please contact your local support people if you do not know how to use partitions"
	-- The case where the job does not specify the partition name
	if job_desc.partition == nil then
		slurm.log_info("%s: user %s %s no partition specified", log_prefix, userinfo, badstring)
		slurm.log_user("WARNING: The compute node partition has not been specified!")
		slurm.log_user(sbatch_msg)
		slurm.log_user(partitions_page)
		slurm.log_user(support_msg)
		if default_partition ~= nil then
			job_desc.partition = default_partition
			slurm.log_user("Setting default partition: %s", job_desc.partition)
			return slurm.SUCCESS
		else
			slurm.log_user(script_error)
			return slurm.ESLURM_INVALID_PARTITION_NAME
		end
	end
	-- Check if the partition name is valid (maybe sbatch already checked this)
	-- Loop over partitions
	for i, p in ipairs(partitions) do
		if string.find(job_desc.partition,p.partition,1,true) == 1 then
			-- partition name which begins with p.partition
			return slurm.SUCCESS
		end
	end
	-- No partition was matched
	-- slurm.log_info("%s: user %s(%u) job_name=%s %s Invalid partition %s specified",
		-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring, job_desc.partition)
	slurm.log_info("%s: user %s %s Invalid partition %s specified",
		log_prefix, userinfo, badstring, job_desc.partition)
	slurm.log_user("Invalid Slurm partition specified, please specify a valid partition")
	slurm.log_user(partitions_page)
	slurm.log_user(script_error)
	return slurm.ESLURM_INVALID_PARTITION_NAME
end

-- Sanity check of argument list in sbatch command:
--    sbatch [OPTIONS(0)...] [ : [OPTIONS(N)...]] script(0) [args(0)...]
-- Do not allow too long argument strings:
-- Very long strings might potentially cause Slurm to crash due to a database issue!
function check_arg_list (job_desc, submit_uid, log_prefix)
	local maxargc=10	-- Maximum number of job script arguments
	local maxarglen=1024	-- Maximum length of job script arguments, should be less than 1000000
	if job_desc.argc == 1 then
		return slurm.SUCCESS
	elseif job_desc.argc > (maxargc+1) then
		-- slurm.log_info("%s: user %s(%u) job_name=%s %s argc=%u is too large",
			-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring, job_desc.argc)
		slurm.log_info("%s: user %s %s argc=%u is too large",
			log_prefix, userinfo, badstring, job_desc.argc)
		slurm.log_user("ERROR: The number of script arguments %u is too large, maximum is %u",
			job_desc.argc - 1, maxargc)
		slurm.log_user(script_error)
		return slurm.ESLURM_PATHNAME_TOO_LONG
	else
		-- Calculate total length of argument strings
		local arglength=0
		for i = 1, job_desc.argc - 1 do
			if job_desc.argv[i] ~= nil then
				arglength = arglength + string.len(job_desc.argv[i]) + 1
			end
		end
		if arglength > maxarglen then
			-- slurm.log_info("%s: user %s(%u) job_name=%s %s argc=%u argv list length=%u",
				-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring, job_desc.argc, arglength)
			slurm.log_info("%s: user %s %s argc=%u argv list length=%u",
				log_prefix, userinfo, badstring, job_desc.argc, arglength)
			slurm.log_user("ERROR: The script argument list exceeds %u characters, length=%u",
				maxarglen, arglength)
			slurm.log_user(script_error)
			return slurm.ESLURM_PATHNAME_TOO_LONG
		end
		return slurm.SUCCESS
	end
end

-- Sanity check of number of nodes (default=slurm.NO_VAL)
function check_num_nodes (job_desc, submit_uid, log_prefix)
	local sbatch_msg="Please read the sbatch manual page about setting nodes with -N/--nodes"
	if job_desc.max_nodes == slurm.NO_VAL then
		slurm.log_user("WARNING: The number of nodes has not been specified!")
		slurm.log_user(sbatch_msg)
		if default_nodes ~= nil then
			job_desc.max_nodes = default_nodes
			slurm.log_user("NOTICE: Setting default number of nodes: %u", job_desc.max_nodes)
			return slurm.SUCCESS
		else
			-- slurm.log_info("%s: user %s(%u) job_name=%s %s No max_nodes specified, min=0x%x max=0x%x ntasks=0x%x",
				-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring, job_desc.min_nodes, job_desc.max_nodes, job_desc.num_tasks)
			slurm.log_info("%s: user %s %s No max_nodes specified, min=0x%x max=0x%x ntasks=0x%x",
				log_prefix, userinfo, badstring, job_desc.min_nodes, job_desc.max_nodes, job_desc.num_tasks)
			slurm.log_user(script_error)
			return slurm.ESLURM_INVALID_NODE_COUNT
		end
	else
		return slurm.SUCCESS
	end
end

-- Sanity check of number of tasks (default=slurm.NO_VAL)
function check_num_tasks (job_desc, submit_uid, log_prefix)
	local sbatch_msg="Please read the sbatch manual page about setting tasks with -n/--tasks"
	if job_desc.num_tasks == slurm.NO_VAL then
		-- slurm.log_info("%s: user %s(%u) job_name=%s %s No num_tasks specified",
			-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring)
		slurm.log_info("%s: user %s %s No num_tasks specified",
			log_prefix, userinfo, badstring)
		slurm.log_user("WARNING: The number of tasks has not been specified!")
		slurm.log_user(sbatch_msg)
		if default_tasks ~= nil then
			job_desc.num_tasks = default_tasks
			slurm.log_user("Setting default number of tasks: %u", job_desc.num_tasks)
			return slurm.SUCCESS
		else
			slurm.log_user(script_error)
			return slurm.ESLURM_BAD_TASK_COUNT
		end
	else
		return slurm.SUCCESS
	end
end


--Forbid the use of jobname="MAINT"
function forbid_reserved_name (job_desc, submit_uid, log_prefix)
	local reserved="MAINT"
	if job_desc.name ~= nil and job_desc.name == reserved then
		-- slurm.log_info("%s: user %s(%u) job_name=%s %s JobName=%s reserved",
			-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring, reserved)
		slurm.log_info("%s: user %s %s JobName=%s reserved",
			log_prefix, userinfo, badstring, reserved)
		slurm.log_user("JobName=%s is reserved. Please use another job name.", reserved)
		slurm.log_user(script_error)
		return slurm.ERROR
	else
		return slurm.SUCCESS
	end
end

-- Forbid unlimited memory using --mem=0 etc.
function forbid_memory_eq_0 (job_desc, submit_uid, log_prefix)
	local checklist = {
		{ name="--mem",		value=job_desc.min_mem_per_node },
		{ name="--mem-per-cpu",	value=job_desc.min_mem_per_cpu },
		{ name="--mem-per-gpu",	value=job_desc.min_mem_per_gpu }
	}
	for i, check in ipairs(checklist) do
		if check.value ~= nil and check.value == 0 then
			-- slurm.log_info("%s: user %s(%u) job_name=%s %s Memory %s=0 is not allowed",
				-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring, check.name)
			slurm.log_info("%s: user %s %s Memory %s=0 is not allowed",
				log_prefix, userinfo, badstring, check.name)
			slurm.log_user("Specifing ALL memory with %s=0 is not allowed", check.name)
			slurm.log_user(script_error)
			return slurm.ESLURM_INVALID_TASK_MEMORY
		end
	end
	return slurm.SUCCESS
end

-- Check the match of number of CPUs and tasks
-- Policy: We require the use of entire nodes for some partitions (xeon24 etc.)
-- as defined by "entirenode" in the "partitions" table.
function check_cpus_tasks (job_desc, submit_uid, log_prefix)
	local cpus_per_task = 1		-- Default value
	-- Informational web page
	local cpucores_page="See https://wiki.fysik.dtu.dk/niflheim/Niflheim7_Getting_started#correct-usage-of-multi-cpu-nodes"
	if job_desc.cpus_per_task ~= slurm.NO_VAL16 then
		cpus_per_task = job_desc.cpus_per_task		-- Value has been specified by job script
	end
	local num_cpus = 0
	-- Loop over partitions
	for i, p in ipairs(partitions) do
		if string.find(job_desc.partition,p.partition,1,true) == 1 then
			-- partition name which begins with p.partition
			if p.entirenode > 0 or job_desc.max_nodes > 1 then
				-- Multi-node jobs must use entire nodes
 				num_cpus = job_desc.max_nodes * p.numcores
			else
				-- Submitting to 1 partial node is OK for these partitions
 				num_cpus = job_desc.num_tasks * cpus_per_task
			end
			break	-- no more partitions to check
		end
	end
	-- Submitting to partial nodes would be OK in case of any unlisted partitions
	-- Warning: Any UNLISTED partition (if it really exists) may be added to the "partitions" list above!
	if num_cpus == 0 then
 		num_cpus = job_desc.num_tasks
		-- slurm.log_info("%s: WARNING: user %s(%u) job_name=%s for %u nodes in AN UNLISTED partition=%s %s num_tasks=%u cpus_per_task=%u",
			-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, job_desc.max_nodes, job_desc.partition, badstring, job_desc.num_tasks, cpus_per_task)
		slurm.log_info("%s: WARNING: user %s for %u nodes in AN UNLISTED partition=%s %s num_tasks=%u cpus_per_task=%u",
			log_prefix, userinfo, job_desc.max_nodes, job_desc.partition, badstring, job_desc.num_tasks, cpus_per_task)
	end
	-- Note: Maybe we can use total_cpus or max_cpus_per_node here?
	if num_cpus ~= job_desc.num_tasks * cpus_per_task then
		-- Log this job to slurmctld.log:
		-- slurm.log_info("%s: user %s(%u) job_name=%s for %u nodes in partition %s %s num_tasks=%u cpus_per_task=%u",
			-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, job_desc.max_nodes, job_desc.partition, badstring, job_desc.num_tasks, cpus_per_task)
		slurm.log_info("%s: user %s for %u nodes in partition %s %s num_tasks=%u cpus_per_task=%u",
			log_prefix, userinfo, job_desc.max_nodes, job_desc.partition, badstring, job_desc.num_tasks, cpus_per_task)
		-- Message to the user:
		slurm.log_user("NOTICE: Jobs for %u nodes in partition %s must use entire nodes!", job_desc.max_nodes, job_desc.partition)
		slurm.log_user(cpucores_page)
		slurm.log_user("This job requests %u cpus but only runs %u tasks and %u cpus_per_task.", num_cpus, job_desc.num_tasks, cpus_per_task)
		slurm.log_user(script_error)
		return slurm.ESLURM_BAD_TASK_COUNT
	else
		return slurm.SUCCESS
	end
end

-- Check if GPU partitions are used correctly
function check_gpus (job_desc, submit_uid, log_prefix)
	-- Loop over partitions
	for i, p in ipairs(partitions) do
		if p.num_gpus > 0 then
			-- Code adapted from https://lists.schedmd.com/pipermail/slurm-users/2020-December/006459.html
			if string.find(job_desc.partition,p.partition,1,true) == 1 then
				-- partition name begins with p.partition
				if job_desc.gres ~= nil and string.find(job_desc.gres, "gpu") then
					--Alert on invalid gpu count - eg: gpu:0 , gpu:p100:0
					local numgpu = string.match(job_desc.gres, ":%d+$")
					if numgpu ~= nil then
						numgpu = numgpu:gsub(':', '')
						if tonumber(numgpu) < 1 then
							-- slurm.log_info("%s: user %s(%u) job_name=%s %s Invalid GPU count specified in GRES",
								-- log_prefix, job_desc.user_name, badstring, submit_uid, job_desc.name)
							slurm.log_info("%s: user %s %s Invalid GPU count specified in GRES",
								log_prefix, userinfo, badstring)
							slurm.log_user("Invalid GPU count specified in GRES, must be greater than 0")
							slurm.log_user(script_error)
							return slurm.ESLURM_INVALID_GRES
						end
					end
				--Alternative use of gpus in newer versions of slurm
				elseif job_desc.tres_per_node == nil and job_desc.tres_per_socket == nil and job_desc.tres_per_task == nil then
					-- slurm.log_info("%s: user %s(%u) job_name=%s %s No GPUs requested for GPU partition",
						-- log_prefix, job_desc.user_name, submit_uid, job_desc.name, badstring)
					slurm.log_info("%s: user %s %s No GPUs requested for GPU partition",
						log_prefix, userinfo, badstring)
					slurm.log_user("You tried submitting to a GPU partition, but you did not request any GPU with GRES or GPUS")
					slurm.log_user(script_error)
					return slurm.ESLURM_INVALID_GRES
				elseif job_desc.num_tasks == slurm.NO_VAL then
					slurm.log_user("--gpus-per-task option requires --tasks specification")
					slurm.log_user(script_error)
					return slurm.ESLURM_BAD_TASK_COUNT
				end
				break	-- no more partitions to check
			end
		end
	end
	return slurm.SUCCESS
end


-- Sets a global string "userinfo" containing user, account and job information for this job
function get_userinfo (job_desc, submit_uid)
	if job_desc.account ~= NIL then
		userinfo = string.format("%s(UID=%u) account=%s job_name=%s",
			job_desc.user_name, submit_uid, job_desc.account, job_desc.name)
	else
		-- The job's account is the user's default account
		userinfo = string.format("%s(UID=%u) job_name=%s",
			job_desc.user_name, submit_uid, job_desc.name)
	end
	return slurm.SUCCESS
end


function slurm_job_submit(job_desc, part_list, submit_uid)
	local log_prefix = 'slurm_job_submit'

	-- Don't block any activity from root. This may make reproduction of user errors difficult.
	if submit_uid == 0 then
		return slurm.SUCCESS
	end
	get_userinfo(job_desc, submit_uid) 

	-- Loop over the function list
	-- We will call these functions in the order listed
	local functionlist = { check_arg_list, forbid_reserved_name, check_partition,
		check_num_nodes, check_num_tasks, forbid_memory_eq_0, check_cpus_tasks, check_gpus }

	local check = slurm.SUCCESS
	for i, func in ipairs(functionlist) do
		check = func(job_desc, submit_uid, log_prefix) 
		if check ~= slurm.SUCCESS then
			return check
		end
	end

	return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_ptr, part_list, modify_uid)
	local log_prefix = 'slurm_job_modify'

	--Don't block/modify any update from root 
	if modify_uid == 0 then
		return slurm.SUCCESS
	end
	get_userinfo(job_desc, modify_uid) 

	-- Loop over the function list
	-- We will call these functions in the order listed
	local functionlist = { forbid_reserved_name, forbid_memory_eq_0 }

	local check = slurm.SUCCESS
	-- Warning: Calling log_user() from slurm_job_modify() fails when using Slurm < 23.02
	-- See https://bugs.schedmd.com/show_bug.cgi?id=14539
	for i, func in ipairs(functionlist) do
		check = func(job_desc, modify_uid, log_prefix) 
		if check ~= slurm.SUCCESS then
			return check
		end
	end

	return slurm.SUCCESS
end
