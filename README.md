# cluster-ca
Create a CA for your cluster apps (e.g. etcd, vault, ...)

Create the CA
-------------

```
./init-ca.sh <name_of_ca>
cd <name_of_ca>
./createCerts.sh server testsrv-1 testsrv-2 testsrv-3
./createCerts.sh client crazy_einstein
```
Done.
