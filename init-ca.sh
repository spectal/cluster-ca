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


if [[ $2 = 'with-intermediate' ]]
then

    echo "create intermediate key\n"

    openssl genrsa -out private/intermediate_ca.key \
        -aes256 4096

    echo "create csr for intermediate key\n"

    openssl req -new -key private/intermediate_ca.key \
        -out reqs/intermediateCA.csr -subj '/C=DE/CN=interm/O=Denic'

    echo "sign intermediate key with CAs root key\n"

    openssl x509 -req -in reqs/intermediate_ca.csr -CA certs/ca.crt -CAkey private/ca.key -CAcreateserial -extensions v3_ca -out certs/intermediate_ca.crt -days 3650 -sha256

    echo "createCerts.sh will sign new certs with the intermediate cert"

    sed -i 's/ca.crt/intermediate_ca.crt/g;s/ca.key/intermediate_ca.key/g' createCerts.sh
fi
