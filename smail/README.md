Modified /usr/bin/smail
-----------------------

The ```/usr/bin/smail``` is part of the ```slurm-contribs``` RPM (17.02, previously ```slurm-seff```).
It sends E-mail to users if ```slurm.conf``` contains:

```
MailProg=/usr/bin/smail
```

This modified script prepends the ```ClusterName``` to the subject line of the message.

Update: This feature will be part of Slurm 17.11, see https://bugs.schedmd.com/show_bug.cgi?id=1611#c9
