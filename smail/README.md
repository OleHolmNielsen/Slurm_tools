Modified /usr/bin/smail
-----------------------

The /usr/bin/smail is part of the *slurm-contribs* RPM (17.02, previously *slurm-seff*).
It sends E-mail to users it slurm.conf contains:

MailProg=/usr/bin/smail

This modified script prepends the *ClusterName* to the subject line of the message.
