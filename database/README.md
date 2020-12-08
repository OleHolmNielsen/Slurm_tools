Slurm database dump backup scripts
----------------------------------

Some convenient scripts for managing Slurm database dump backups:

* ```slurm_acct_db_backup```: Script for daily database dumps using ```logrotate```.

  You have to create an empty backup file initially: touch /root/slurm_acct_db_backup.bz2

* ```mysqlbackup```: Script for making a database dump (with backup) from crontab.

