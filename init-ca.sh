#!/bin/bash

if [ $# -lt 1 ]
then
    echo "$0 <name-of-ca>"
    exit 1
fi

caname="$1"

mkdir -p "$caname"
cp createCerts.sh "$caname"
chmod 755 $caname/createCerts.sh
cp revokeCerts.sh "$caname"
chmod 755 $caname/revokeCerts.sh
cat openssl.config.tpl | \
    sed -e 's/__ORGUNIT__/'$caname'/' > $caname/openssl.cnf

cd $caname
mkdir private certs newcerts crl reqs

touch index.txt
echo '01' > serial
echo '01' > crlnumber

if [ -e "$(which pass)" ]
then
    pass generate cluster-ca/$caname/ca-key-pass 23
else
    echo "here is a password suggestion"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9\.\(\)\_:\?\&/%$!\{\}"' | fold -w 32 | head -n 1
    echo 
 
fi

openssl req -config openssl.cnf \
    -new -x509 -extensions v3_ca \
    -newkey rsa:4096 -nodes -keyout private/ca.key -out certs/ca.crt

