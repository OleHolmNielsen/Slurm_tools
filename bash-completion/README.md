Slurm command completions for our Slurm tools
===============================================

Bash command completion 
==================================

The [Bash shell](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) includes a TAB command-completion feature
described in these resources:

* [Bash TAB completion tutorial](https://www.gnu.org/software/gnuastro/manual/html_node/Bash-TAB-completion-tutorial.html)

* [Programmable Completion Builtins](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html)

* [bash-completion](https://github.com/scop/bash-completion) source code on GitHub.

On EL8/EL9 Linux enable this feature by:
```
dnf install bash-completion
```

Command completion for Slurm commands
----------------------------------------

Slurm includes a [slurm_completion_help](https://github.com/SchedMD/slurm/tree/master/contribs/slurm_completion_help)
script which offers completion for user commands like ```squeue``` , ```sbatch``` etc.

This feature is installed by the ```slurm``` package starting from Slurm 24.11,
see [ticket_20932](https://support.schedmd.com/show_bug.cgi?id=20932).
The relevant installed file is ```/usr/share/bash-completion/completions/slurm_completion.sh```.

See also our Wiki section [Bash command completion for Slurm](https://wiki.fysik.dtu.dk/Niflheim_system/Slurm_configuration/#bash-command-completion-for-slurm).

Command completion for our Slurm tools
--------------------------------------------

We utilize the Slurm command completion feature to add command completion for these tools in the present project:

```
pestat
showpower
showuserjobs
showuserlimits
slurmusersettings
showpartitions
```
We leverage the functions defined in ```/usr/share/bash-completion/completions/slurm_completion.sh```
to offer completions for ```-u``` (username) and ```-p``` (partition name), 
for example:
```
pestat -u user[TAB][TAB]
showuserjobs -p partition[TAB][TAB]
```

Furthermore, a number of our tools only take a Slurm *hostlist* argument (without any -w/-N options):
```
shownode
sdrain
sresume
sreboot
psnode
spowerdown
spowerup
```

These are utilized as for example:
```
shownode nodename[TAB][TAB]
sreboot nodename[TAB][TAB]
```

The implementation of this requires an additional ```function _hostlist()```.

Installation
-------------

Copy the file ```slurm_tools_completion.sh``` to the ```/etc/profile.d/``` folder,
where application-specific files are sourced when a user logs in:
```
cp slurm_tools_completion.sh /etc/profile.d/
```
