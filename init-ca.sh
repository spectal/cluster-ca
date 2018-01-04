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
    mkdir -p intermediate
    cd intermediate
    mkdir certs reqs crl csr newcerts private
    chmod 700 private
    touch index.txt
    echo 02 > serial
    echo 02 > crlnumber
    cd ..

    echo "create intermediate openssl config"

    cat ../openssl.config.tpl | \
    sed -e "s/__ORGUNIT__/$caname/;s/dir = ./dir = .\/intermediate/;s/crl.pem/intermediate.crl.pem/;s/ca.crt/intermediate_ca.crt/;s/ca.key/intermediate_ca.key/" > "intermediate/openssl.cnf"

    echo "create intermediate key\n"

    openssl genrsa -out intermediate/private/intermediate_ca.key \
        -aes256 4096

    echo "create csr for intermediate key\n"

    openssl req -config intermediate/openssl.cnf \
        -new -key intermediate/private/intermediate_ca.key \
        -out intermediate/reqs/intermediate_ca.csr -subj '/C=DE/CN=interm/O=Denic'

    chmod 400 intermediate/private/intermediate_ca.key

    echo "sign intermediate key with CAs root key\n"

    openssl x509 -req -in intermediate/reqs/intermediate_ca.csr \
        -CA certs/ca.crt -CAkey private/ca.key -CAcreateserial \
        -extensions v3_intermediate_ca -out intermediate/certs/intermediate_ca.crt \
        -days 3650 -sha256

    echo "createCerts.sh will sign new certs with the intermediate cert"

    sed -i 's/certs\/ca.crt/intermediate\/certs\/intermediate_ca.crt/g;s/private\/ca.key/intermediate\/private\/intermediate_ca.key/g;s/openssl.cnf/intermediate\/openssl.cnf/' createCerts.sh
fi
