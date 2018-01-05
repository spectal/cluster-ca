# cluster-ca
Create a CA for your cluster apps (e.g. etcd, vault, ...)

Create the CA
-------------

```
./init-ca.sh <name_of_ca>
cd <name_of_ca>
./createCerts.sh server <with-intermediate> <intermediate_cert_name> testsrv-1 testsrv-2 testsrv-3
./createCerts.sh client <with-intermediate> <intermediate_cert_name> crazy_einstein
./createCerts.sh multi <with-intermediate> <intermediate_cert_name> my-etcd-cluster etcd-1 etcd-2 etcd-3
./createCerts.sh intermediate <nopass> cert_name
```
Done.

Use "server" followed by a list of hostnames to create multiple certs, one for every listed hostname.
Use "client" followed by the name of the user to create a user certificate.
Use "multi" followed by the name of the cert and a list of hostnames to create a cert which contains the listed hosts in SAN.

Use  with-intermediate followed by the name of the intermediate cert you want to use to sign the new certs for any of the above commands

Use "intermediate" followed by a cert name to create an intermediate cert, optional nopass creates a cert without passphrase.
