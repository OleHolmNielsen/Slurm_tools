# shellcheck shell=bash

# Slurm command completions used for the tools from https://github.com/OleHolmNielsen/Slurm_tools
# Command completion: https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html

# Enable shell options
shopt -s extglob

# Check for interactive bash and that we haven't already been sourced.
if [ -n "${BASH_VERSION-}" -a -n "${PS1-}" ]
then
	[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion" ] && \
		. "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion"
	if shopt -q progcomp && [ -r /usr/share/bash-completion/completions/slurm_completion.sh ]
	then
		# Source Slurm completion code.
		. /usr/share/bash-completion/completions/slurm_completion.sh
		# Slurm nodes hostlist completion handler (where -w/-N options are not used)
		#   (adapted from slurm_completion.sh)
		function _hostlist() {
			local cur prev words cword split
			__slurm_compinit "$1" || return
			__slurm_log_info "$(__func__): prev='$prev' cur='$cur'"
			$split && return
			__slurm_compreply_list "$(__slurm_nodes)" "ALL" "true"
		}

		# Add Slurm completion for these commands:
		complete -o nospace -F _squeue pestat
		complete -o nospace -F _squeue showpower
		complete -o nospace -F _squeue showuserjobs
		complete -o nospace -F _squeue showuserlimits
		complete -o nospace -F _squeue showevents
		complete -o nospace -F _squeue slurmusersettings
		complete -o nospace -F _sinfo showpartitions
		complete -o nospace -F _hostlist shownode
		complete -o nospace -F _hostlist sdrain
		complete -o nospace -F _hostlist sresume
		complete -o nospace -F _hostlist sreboot
		complete -o nospace -F _hostlist psnode
		complete -o nospace -F _hostlist spowerdown
		complete -o nospace -F _hostlist spowerup
	fi
fi
