#!/bin/bash
#set -x
caname="$(realpath "$(dirname ${BASH_SOURCE[0]})" )"
echo "Working in $caname"
print_help(){
    echo "./createCerts.sh server <with-intermediate <intermediate_cert_name> <srv1-fqdn> <srv2-fqdn> ..."
    echo "./createCerts.sh multi  <with-intermediate <intermediate_cert_name> <certname> <srv1-fqdn> <srv2-fqdn> ..."
    echo "./createCerts.sh client <with-intermediate <intermediate_cert_name> <client-name>"
    echo "./createCerts.sh intermediate <nopass> <certname>"
}

getSubject(){
    read -p "Country: " country
    read -p "State: " state
    read -p "Location/City: " location
    read -p "Organisation: " org
    read -p "Org Unit: " orgUnit

    if [ -n "$country" ];  then subj="/C=$country";         fi
    if [ -n "$state" ];    then subj="${subj}/ST=$state";   fi
    if [ -n "$location" ]; then subj="${subj}/L=$location"; fi
    if [ -n "$org" ];      then subj="${subj}/O=$org";      fi
    if [ -n "$orgUnit" ];  then subj="${subj}/OU=$orgUnit"; fi

    echo "$subj"
}

createServer(){

    signing_cert_name="ca"

    if [[ "$1" = "with-intermediate" ]]; then
        signing_cert_name=$2
        shift 2
    fi


    subj="$(getSubject)"
    for server in "$@"
    do
        if [ -x "$(which dig)" ]
        then
            IP=$(dig +nocookie +short $server)
            if [ -z "$IP" ]; then
                IP="127.0.0.1"
            fi
            read -p "SAN [DNS:$server, IP:$IP]: " san
            export SAN="${san:-DNS:$server,IP:$IP}"
        else
            read -p "SAN [DNS:$server]: " san
            export SAN="${san:-DNS:$server}"
        fi

        openssl req -config openssl.cnf -new -nodes \
          -subj "$subj/CN=$server" \
          -keyout private/$server.key -out reqs/$server.csr

        openssl ca -batch -config openssl.cnf -extensions cluster_server \
          -keyfile private/$signing_cert_name.key \
          -cert certs/$signing_cert_name.crt \
          -out certs/$server.crt -infiles reqs/$server.csr
    done
}

createMultiServer() {

    signing_cert_name="ca"

    if [[ "$1" = "with-intermediate" ]]; then
        signing_cert_name=$2
        shift 2
    fi

    certname=$1
    shift
    subj="$(getSubject)"
    names="DNS:localhost"
    ips="IP:127.0.0.1"

    for server in "$@"
    do
        IP=$(dig +nocookie +short $server)
        if [ -n "$IP" ]; then
            ips="$ips,IP:$IP"
        fi
        names="$names,DNS:$server"
    done

    read -p "SAN [$names,$ips]: " san
    export SAN="${san:-$names,$ips}"

    openssl req -config openssl.cnf -new -nodes \
      -subj "$subj/CN=$certname" \
      -keyout private/$certname.key -out reqs/$certname.csr

    openssl ca -batch -config openssl.cnf -extensions cluster_server \
      -keyfile private/$signing_cert_name.key \
      -cert certs/$signing_cert_name.crt \
      -out certs/$certname.crt -infiles reqs/$certname.csr
}

createClient(){

    signing_cert_name="ca"

    if [[ "$1" = "with-intermediate" ]]; then
        signing_cert_name=$2
        shift 2
    fi

    unset SAN
    client="$1"
    openssl req -config openssl.cnf -new -nodes \
        -keyout private/client-$client.key -out reqs/client-$client.csr

    openssl ca -config openssl.cnf -extensions cluster_client \
        -keyfile private/ca.key \
        -cert certs/ca.crt \
        -out certs/client-$client.crt -infiles reqs/client-$client.csr
}

createIntermediate(){
    subj="$(getSubject)"

    if [[ "$1" = "nopass" ]]; then
        nopass=true
        shift
    fi

    intermediate_cert_name="$1"

    if [[ $nopass = true ]]; then
     echo "you decided to create passphraseless intermediate cert/s"
     openssl req -config openssl.cnf \
      -new -newkey rsa:4096 -nodes \
      -out reqs/$intermediate_cert_name.csr -keyout private/$intermediate_cert_name.key \
      -subj "$subj/CN=$intermediate_cert_name"
    else
      openssl req -config openssl.cnf \
        -new -newkey rsa:4096 \
                    -out reqs/$intermediate_cert_name.csr -keyout private/$intermediate_cert_name.key \
        -subj "$subj/CN=$intermediate_cert_name"
    fi

    openssl x509 -req -in reqs/$intermediate_cert_name.csr \
        -CA certs/ca.crt -CAkey private/ca.key -CAcreateserial \
        -extensions v3_intermediate_ca -out certs/$intermediate_cert_name.crt \
        -days 3650 -sha256
}

case "$1" in
    client) echo "create client."
            shift
            createClient $@
            ;;

    server) echo "create server."
            shift
            createServer $@
            ;;

    multi) echo "create server."
            shift
            createMultiServer $@
            ;;

    intermediate) echo "create intermediate."
            shift
            createIntermediate $@
            ;;

         *) print_help
            exit 1
            ;;
esac
