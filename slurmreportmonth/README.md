Slurm monthly accounting report tool
------------------------------------

Generate monthly accounting statistics from Slurm using the ```sreport``` command.
The script calculates last month's dates by default.

Specific accounts and start/end dates may be specified.
In addition, the report may be E-mailed and/or copied to some report directory (for example, on a web server).

Usage
-----

```
slurmreportmonth [-m] [-c | -w] [-a accountlist] [-s startdate -e enddate] [-r report-directory]
where:
	-m: Send report by E-mail to root@localhost
	-a: Select an account (or list of accounts)
	-s -e: Select Start and End dates of the report
        -c: Select current month from the 1st until today
	-w: Select the last week
	-r: Copy the report to a specified directory as well
```

Date format: MMDD (Month-Day)


