#!/bin/bash

if [ $# -lt 1 ]
then
    echo "$0 <name-of-ca>"
    exit 1
fi

if [ "$CAPASSWORD" != "true" ]
then
    echo "Variable CAPASSWORD is not set. CA key will NOT be password protected."
    echo "If you want to protect you CA key, set CAPASSWORD to 'true'."
    read -p "Ctrl-C to abort." abort
    USEPASSWORD="-nodes"
else
    USEPASSWORD=""
fi


caname="$1"

mkdir -p "$caname"
cp createCerts.sh "$caname"
chmod 755 "$caname/createCerts.sh"
cp revokeCerts.sh "$caname"
chmod 755 "$caname/revokeCerts.sh"
cat openssl.config.tpl | \
    sed -e "s/__ORGUNIT__/$caname/" > "$caname/openssl.cnf"

cd "$caname"
mkdir private certs newcerts crl reqs

touch index.txt
echo "unique_subject = yes" > index.txt.attr
echo '01' > serial
echo '01' > crlnumber

openssl req -config openssl.cnf \
    -new -x509 -extensions v3_ca -days 3650 \
    -newkey rsa:4096 $USEPASSWORD -keyout private/ca.key -out certs/ca.crt

