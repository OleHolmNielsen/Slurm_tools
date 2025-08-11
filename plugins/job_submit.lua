--[[
Niflheim job_submit.lua file for Slurm based upon the source file etc/job_submit.lua.example

For more information check https://slurm.schedmd.com/job_submit_plugins.html
An example is in the source code at .../etc/job_submit.lua.example
See also the Wiki page https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_configuration/#job-submit-plugins

NOTES:
* The slurm.log_info() function logs to the slurmctld.log
    We print the "badstring" string to identify bad job submissions.
* The slurm.log_user() function prints an error message to the user's terminal.
* Slurm Error numbers are defined in the source file slurm/slurm_errno.h
* For the list of available Lua slurm.* fields check the job_desc variable
    in src/plugins/job_submit/lua/job_submit_lua.c
* The job_submit.lua file is called with these arguments:
    job_desc (input/output) the job allocation request specifications.
    job_ptr (input/output) slurmctld daemon's current data structure for the job to be modified.
    part_list (input) List of pointer to partitions which this user is authorized to use.
    modify_uid (input) user ID initiating the request.
    See https://slurm.schedmd.com/job_submit_plugins.html#lua

ERROR NUMBERS:
Error numbers are defined in the source file /usr/include/slurm/slurm_errno.h
Prior to Slurm 23.02 we have to define error symbols manually, see https://bugs.schedmd.com/show_bug.cgi?id=14500
Only a few selected symbols ESLURM_* were exposed to the Lua script, but from Slurm 23.02 all the error codes are exposed.
--]]

badstring="BAD:"	-- This string is printed to slurmctld.log and can be grepped for
userinfo=""
--[[
-- Prior to Slurm 23.02 we had to define these error codes:
slurm.ESLURM_INVALID_PARTITION_NAME=2000
slurm.ESLURM_INVALID_NODE_COUNT=2006
slurm.ESLURM_PATHNAME_TOO_LONG=2012
slurm.ESLURM_BAD_TASK_COUNT=2025
slurm.ESLURM_INVALID_TASK_MEMORY=2044
slurm.ESLURM_INVALID_GRES=2072
--]]

--
-- Define our partitions and defaults
--
partitions = {
	-- partition name (NOTE: a substring which begins the name), number of cores, entire node is 0/1, number of gpus
	-- Multiple partitions can be lumped together, for example, xeon24, xeon24_512, xeon24_1024 as "xeon24"
	{ partition="xeon24", numcores=24, entirenode=0, num_gpus=0 },
	{ partition="xeon32", numcores=32, entirenode=0, num_gpus=0 },
	{ partition="xeon40", numcores=40, entirenode=1, num_gpus=0 },
	{ partition="xeon56", numcores=56, entirenode=1, num_gpus=0 },
	{ partition="sm3090", numcores=80, entirenode=0, num_gpus=10 },
	{ partition="epyc96", numcores=96, entirenode=1, num_gpus=0 },
	{ partition="a100", numcores=128, entirenode=0, num_gpus=4 },
	{ partition="h200", numcores=96, entirenode=0, num_gpus=4 }
}
default_partition="xeon24el8"	-- This partition will be set if none was requested
default_nodes=1			-- Number of nodes if none was requested
default_tasks=1			-- Number of tasks if none was requested
interactive_max_time=240	-- Default maximum time in minutes for all interactive jobs

--
-- Define functions to be used
--

-- Check for interactive jobs
function check_interactive_job (job_desc, part_list, submit_uid, log_prefix)
	if (job_desc.script == nil or job_desc.script == '') then
		-- Job script is missing, assuming an interactive job
		slurm.log_info("%s: user %s submitted an interactive job to partition(s) %s",
			log_prefix, userinfo, job_desc.partition)
		slurm.log_user("NOTICE: Job script is missing, assuming an interactive job")
		-- Loop over the (possibly multiple) partitions requested by the job
		--   Split job_desc.partition on the "," separator between multiple PartitionNames (such as a,b,c)
		--   gmatch: see http://lua-users.org/wiki/StringLibraryTutorial
		local max_time = interactive_max_time
		for pjob in string.gmatch(job_desc.partition, "[^,]+") do	-- Select substrings without comma ("^," means not-comma)
			-- Loop over partitions in part_list to determine the partition's max_time time limit
			for i, p in pairs(part_list) do
				if pjob == p.name then
					if p.max_time ~= nil and p.max_time < max_time then
						max_time = p.max_time		-- Reduce max_time to the partition max_time
					end
					break	-- no more partitions to check
				end
			end
			if job_desc.time_limit == nil or job_desc.time_limit > max_time then
				job_desc.time_limit = max_time
				slurm.log_info("%s: NOTICE: Job time_limit in partition %s has been set to %d minutes",
					log_prefix, pjob, max_time)
				slurm.log_user("        Job time limit is set to %d minutes on partition %s",
					max_time, pjob)
			end
		end
	end
	return slurm.SUCCESS
end

-- Check for unspecified partition
-- Policy: the partition MUST be specified by the job
partitions_page="Our partitions are listed in https://wiki.fysik.dtu.dk/Niflheim_users/Niflheim_Getting_Started/#compute-node-partitions"
script_error="ERROR: Please modify your batch job script"
function check_partition_unspecified (job_desc, part_list, submit_uid, log_prefix)
	-- Informational web pages
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
	return slurm.SUCCESS
end

-- Sanity check of partition
-- The above check_partition_unspecified should be called first
function check_partition_name (job_desc, part_list, submit_uid, log_prefix)
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

-- Sanity check of partition modification
function modify_partition (job_desc, job_ptr, part_list, modify_uid, log_prefix)
	if job_desc.partition == nil or job_desc.partition == job_ptr.partition then
		-- The case where the modify request does not modify the partition name
		return slurm.SUCCESS
	else
		slurm.log_user("Change of partition not permitted: %s", job_desc.partition)
		return slurm.ESLURM_INVALID_PARTITION_NAME
	end
end

-- Sanity check of argument list in sbatch command:
--    sbatch [OPTIONS(0)...] [ : [OPTIONS(N)...]] script(0) [args(0)...]
-- Do not allow too long argument strings:
-- Very long strings might potentially cause Slurm to crash due to a database issue!
function check_arg_list (job_desc, part_list, submit_uid, log_prefix)
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
function check_num_nodes (job_desc, part_list, submit_uid, log_prefix)
	local sbatch_msg="Please read the sbatch manual page about setting nodes with -N/--nodes"
	if job_desc.min_nodes == slurm.NO_VAL and job_desc.max_nodes == slurm.NO_VAL then
		slurm.log_user("WARNING: The number of nodes has not been specified!")
		slurm.log_user(sbatch_msg)
		if default_nodes ~= nil then
			job_desc.min_nodes = default_nodes
			job_desc.max_nodes = default_nodes
			slurm.log_user("NOTICE: Setting default number of nodes min-max = %u-%u",
				job_desc.min_nodes, job_desc.max_nodes)
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

-- Sanity check of modified number of nodes (default=slurm.NO_VAL)
function modify_num_nodes (job_desc, job_ptr, part_list, modify_uid, log_prefix)
	if job_desc.min_nodes == slurm.NO_VAL and job_desc.max_nodes == slurm.NO_VAL then
		-- The case where the modify request does not modify the min_nodes or max_nodes
		return slurm.SUCCESS
	else
		slurm.log_user("Change of number of nodes not permitted")
		return slurm.ESLURM_INVALID_NODE_COUNT
	end
end

-- Sanity check of number of tasks (default num_tasks=slurm.NO_VAL)
function check_num_tasks (job_desc, part_list, submit_uid, log_prefix)
	-- NOTE: From Slurm 23.02 job_desc.num_tasks may be undefined, see https://bugs.schedmd.com/show_bug.cgi?id=17564
	-- In https://bugs.schedmd.com/show_bug.cgi?id=17564#c6 --ntasks-per-gpu currently causes num_tasks to be set (might change in the future)
	local sbatch_msg="Please read the sbatch manual page about setting tasks with -n/--tasks or --ntasks-per-node or --ntasks-per-gpu"
	if job_desc.num_tasks == slurm.NO_VAL then
		-- Workaround for Slurm 23.02 where job_desc.num_tasks is undefined at job submission time
		if job_desc.ntasks_per_node ~= slurm.NO_VAL16 and job_desc.min_nodes ~= slurm.NO_VAL then
			job_desc.num_tasks = job_desc.ntasks_per_node * job_desc.min_nodes
			slurm.log_user("Setting number of tasks: %u", job_desc.num_tasks)
			return slurm.SUCCESS
		end
		slurm.log_info("%s: user %s %s No num_tasks specified",
			log_prefix, userinfo, badstring)
		slurm.log_user("WARNING: The number of tasks has not been specified!")
		slurm.log_user(sbatch_msg)
		if job_desc.min_nodes ~= slurm.NO_VAL then
			-- Setting 1 task per node
			job_desc.num_tasks = job_desc.min_nodes
			slurm.log_user("Setting default number of tasks to the number of nodes: %u", job_desc.num_tasks)
			return slurm.SUCCESS
		elseif default_tasks ~= nil then
			-- Setting the default number of tasks
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

-- Sanity check of modified number of tasks (default num_tasks=slurm.NO_VAL)
function modify_num_tasks (job_desc, job_ptr, part_list, modify_uid, log_prefix)
	-- The cases where the modify request does not modify the num_tasks
	if job_desc.num_tasks == slurm.NO_VAL then
		return slurm.SUCCESS
	elseif job_ptr.num_tasks ~= slurm.NO_VAL then
		if job_desc.num_tasks == job_ptr.num_tasks then
			return slurm.SUCCESS
		end
	end
	slurm.log_user("Change of number of tasks not permitted")
	return slurm.ESLURM_BAD_TASK_COUNT
end


--Forbid the use of jobname="MAINT"
function forbid_reserved_name (job_desc, part_list, submit_uid, log_prefix)
	local reserved="MAINT"
	if job_desc.name ~= nil and job_desc.name == reserved then
		slurm.log_info("%s: user %s %s JobName=%s reserved",
			log_prefix, userinfo, badstring, reserved)
		slurm.log_user("JobName=%s is reserved. Please use another job name.", reserved)
		slurm.log_user(script_error)
		return slurm.ERROR
	else
		return slurm.SUCCESS
	end
end

-- Check usage of big-memory nodes using --mem=xxx etc.
function check_big_memory (job_desc, part_list, submit_uid, log_prefix)
	-- Policy: Define acceptable lower limits on memory on a 4 TB node (32 cores)
	local min_mem_per_node = 700000
	local cores_per_node = 32
	local min_mem_per_cpu = min_mem_per_node / cores_per_node
	local usage_page="https://wiki.fysik.dtu.dk/Niflheim_users/Niflheim_Getting_Started/#usage-of-big-memory-nodes"
	-- This check only applies to xeon32* partitions (return otherwise)
	if string.find(job_desc.partition,"xeon32_") == nil then
		return slurm.SUCCESS
	end
	if job_desc.min_mem_per_node == nil and job_desc.min_mem_per_cpu == nil then
		-- Neither min_mem_per_node nor min_mem_per_cpu was specified
		slurm.log_info("%s: user %s %s Job did not specify min_mem_per_* for partition %s",
			log_prefix, userinfo, badstring, job_desc.partition)
		slurm.log_user("Big-memory partition %s requires jobs to specify memory explicitly.", job_desc.partition)
		slurm.log_user("See the Wiki page %s", usage_page)
		return slurm.ESLURM_INVALID_TASK_MEMORY
	end
	-- Note: With Lua 5.1.4 (CentOS 7) printing a nil value generates an error (fixed in 5.3.4),
	-- so we need to check carefully for any nil values (see bug 19564)
	if job_desc.min_mem_per_node ~= nil and job_desc.min_mem_per_node < min_mem_per_node then
		slurm.log_user("Big-memory partition %s requires jobs to specify a memory per node of at least %d MB",
			job_desc.partition, min_mem_per_node)
		slurm.log_user("Your job requested %s MB", job_desc.min_mem_per_node)
		slurm.log_user("See the Wiki page %s", usage_page)
		return slurm.ESLURM_INVALID_TASK_MEMORY
	end
	if job_desc.min_mem_per_cpu ~= nil and job_desc.min_mem_per_cpu < min_mem_per_cpu then
		slurm.log_user("Big-memory partition %s requires jobs to specify a memory per cpu of at least %d MB",
			job_desc.partition, min_mem_per_cpu)
		slurm.log_user("Your job requested %s MB", job_desc.min_mem_per_cpu)
		slurm.log_user("See the Wiki page %s", usage_page)
		return slurm.ESLURM_INVALID_TASK_MEMORY
	end
	return slurm.SUCCESS
end

-- Forbid unlimited memory using --mem=0 etc.
function forbid_memory_eq_0 (job_desc, part_list, submit_uid, log_prefix)
	local checklist = {
		{ name="--mem",		value=job_desc.min_mem_per_node },
		{ name="--mem-per-cpu",	value=job_desc.min_mem_per_cpu },
		{ name="--mem-per-gpu",	value=job_desc.min_mem_per_gpu }
	}
	for i, check in ipairs(checklist) do
		if check.value ~= nil and check.value == 0 then
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
-- Policy: We require the use of entire nodes for some partitions (xeon40 etc.)
-- as defined by "entirenode" in the "partitions" table.
function check_cpus_tasks (job_desc, part_list, submit_uid, log_prefix)
	local cpus_per_task = 1		-- Default value
	-- Informational web page
	local cpucores_page="See https://wiki.fysik.dtu.dk/Niflheim_users/Niflheim_Getting_Started/#usage-of-multi-cpu-nodes"
	if job_desc.cpus_per_task ~= slurm.NO_VAL16 then
		cpus_per_task = job_desc.cpus_per_task		-- Value has been specified by job script
	end
	local num_cpus = 0
	local num_gpus = 0
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
			num_gpus = p.num_gpus	-- Number of GPUs in this partition
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
	-- The check below is only for non-GPU-nodes /OHN, 11-Oct-2024, requested by user mohsa
	if num_gpus == 0 and num_cpus ~= job_desc.num_tasks * cpus_per_task then
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
function check_gpus (job_desc, part_list, submit_uid, log_prefix)
	-- Loop over partitions
	for i, p in ipairs(partitions) do
		if p.num_gpus > 0 then
			-- Code adapted from https://lists.schedmd.com/pipermail/slurm-users/2020-December/006459.html
			if string.find(job_desc.partition,p.partition,1,true) == 1 then
				-- partition name begins with p.partition
				if job_desc.gres == nil then
						-- No GRES specified 
						slurm.log_info("%s: user %s %s No GRES specified for GPU partition %s",
							log_prefix, userinfo, badstring, job_desc.partition)
						slurm.log_user("No GRES was specified, GRES must be 1 or more GPUs in partition %s",
							job_desc.partition)
						slurm.log_user(script_error)
						return slurm.ESLURM_INVALID_GRES
				elseif job_desc.gres ~= nil then
					if string.find(job_desc.gres, "gpu") then
						-- Get number of GPUs specified
						local numgpu = string.match(job_desc.gres, ":%d+$")
					else
						-- GRES specified but no "gpu" was given
						slurm.log_info("%s: user %s %s No GPUs specified in GRES for GPU partition %s",
							log_prefix, userinfo, badstring, job_desc.partition)
						slurm.log_user("No GPU GRES was specified, GRES must be 1 or more GPUs in partition %s",
							job_desc.partition)
						slurm.log_user(script_error)
						return slurm.ESLURM_INVALID_GRES
					end
					if numgpu ~= nil then
						numgpu = numgpu:gsub(':', '')
						if tonumber(numgpu) < 1 then
							-- Alert on invalid gpu count - eg: gpu:0 , gpu:p100:0
							slurm.log_info("%s: user %s %s Invalid GPU count specified in GRES",
								log_prefix, userinfo, badstring)
							slurm.log_user("Invalid GPU count specified in GRES, must be greater than 0")
							slurm.log_user(script_error)
							return slurm.ESLURM_INVALID_GRES
						end
					end
				--Alternative use of gpus in newer versions of slurm
				elseif job_desc.tres_per_node == nil and job_desc.tres_per_socket == nil and job_desc.tres_per_task == nil then
					slurm.log_info("%s: user %s %s No GPUs requested for GPU partition %s",
						log_prefix, userinfo, badstring, job_desc.partition)
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
function get_userinfo (job_desc, part_list, submit_uid)
	if job_desc.account ~= NIL then
		userinfo = string.format("%s(UID=%u) account=%s job_name=%s",
			job_desc.user_name, submit_uid, job_desc.account, job_desc.name)
	else
		-- The job's account is the user's default account
		if job_desc.name ~= NIL then
			userinfo = string.format("%s(UID=%u) job_name=%s",
				job_desc.user_name, submit_uid, job_desc.name)
		else
			userinfo = string.format("%s(UID=%u) job_name=(nil)",
				job_desc.user_name, submit_uid)
		end
	end
	return slurm.SUCCESS
end


function slurm_job_submit(job_desc, part_list, submit_uid)
	-- Arguments:
	-- job_desc (input/output) the job allocation request specifications.
	-- part_list (input) List of pointer to partitions which this user is authorized to use.
	-- submit_uid (input) user ID initiating the request.
	local log_prefix = 'slurm_job_submit'

	-- Don't block any activity from root. This may make reproduction of user errors difficult.
	if submit_uid == 0 then
		return slurm.SUCCESS
	end
	get_userinfo(job_desc, part_list, submit_uid) 

	-- Loop over the function list
	-- We will call these functions in the order listed
	local functionlist = { check_arg_list, forbid_reserved_name, check_partition_unspecified, check_partition_name, 
		check_interactive_job, check_big_memory,
		check_num_nodes, check_num_tasks, forbid_memory_eq_0, check_cpus_tasks, check_gpus }

	local check = slurm.SUCCESS
	for i, func in ipairs(functionlist) do
		check = func(job_desc, part_list, submit_uid, log_prefix) 
		if check ~= slurm.SUCCESS then
			return check
		end
	end

	return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_ptr, part_list, modify_uid)
	-- Arguments:
	-- job_desc (input/output) the job allocation **modification request** specifications.
	-- job_ptr (input/output) slurmctld daemon's **current** data structure for the job to be modified.
	-- part_list (input) List of pointer to partitions which this user is authorized to use.
	-- modify_uid (input) user ID initiating the request.
	local log_prefix = 'slurm_job_modify'

	--Don't block/modify any update from root 
	if modify_uid == 0 then
		return slurm.SUCCESS
	end
	get_userinfo(job_desc, modify_uid) 

	-- Loop over the function list no. 1 for checking job_desc
	-- We will call these functions in the order listed
	local functionlist1 = { forbid_reserved_name, forbid_memory_eq_0 }

	local check = slurm.SUCCESS
	-- Warning: Calling log_user() from slurm_job_modify() fails when using Slurm < 23.02
	-- See https://bugs.schedmd.com/show_bug.cgi?id=14539
	for i, func in ipairs(functionlist1) do
		check = func(job_desc, modify_uid, log_prefix) 
		if check ~= slurm.SUCCESS then
			return check
		end
	end
	-- Loop over the function list no. 2 for checking job_desc as well as job_ptr
	-- local functionlist2 = { modify_partition, modify_num_nodes, modify_num_tasks }
	local functionlist2 = { modify_partition, modify_num_nodes, modify_num_tasks }
	for i, func in ipairs(functionlist2) do
		check = func(job_desc, job_ptr, part_list, modify_uid, log_prefix) 
		if check ~= slurm.SUCCESS then
			return check
		end
	end

	return slurm.SUCCESS
end
