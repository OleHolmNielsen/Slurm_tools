Slurm database dump backup scripts
----------------------------------

Some convenient scripts for managing Slurm database dump backups:

* ```slurm_acct_db_backup```: ```logrotate``` script for daily database dumps in ```/var/log/mariadb/```.

  Please note that SELinux restricts ```logrotate``` to create files only under ```/var/log/```.

  You have to create an empty backup file initially: ```touch /var/log/mariadb/slurm_acct_db_backup.bz2```

* ```mysqlbackup```: Script for making a database dump (with backup) from crontab.

