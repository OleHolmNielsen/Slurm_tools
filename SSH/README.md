Creating the user SSH v2 AUTHORIZEDKEYS file
--------------------------------------------

The ```authorized_keys``` tool will generate SSH public/private keypairs
for a number of SSH keytypes using the ```ssh-keygen``` tool.
Already existing SSH keys will not be modified.

Beware: An empty passphrase is used which means a lower security level
than what may be required by your organization.

The ```authorized_keys``` tool will add any new SSH keys to the $HOME/.ssh/authorized_keys file,
but already existing keys in the file will not be modified.
