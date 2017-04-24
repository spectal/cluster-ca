#!/bin/bash

if [ $# -lt 1 ]; then
    echo "$0 <certfile>"
    exit 1
fi

for i in "$@"; do
    if [ ! -f $i ]; then
        echo "Certificate file $i not found."
        continue
    fi
    openssl ca -config openssl.cnf -revoke $i
done

echo "Certificate(s) revoked."
echo
echo "-------------------------"
echo "Generating new CRL and check revocation."
openssl ca -config openssl.cnf -gencrl -out crl.list.pem
cat certs/ca.crt crl.list.pem > crl_chain.pem
echo
for i in "$@"; do
    echo "Verifing $i"
    openssl verify -crl_check -CAfile crl_chain.pem $i 
    echo 
done
