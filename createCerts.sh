#!/bin/bash
#set -x
caname="$(realpath "$(dirname ${BASH_SOURCE[0]})" )"
echo "Working in $caname"
print_help(){
    echo "./createCerts.sh server <srv1-fqdn> <srv2-fqdn> ..."
    echo "./createCerts.sh multi  <certname> <srv1-fqdn> <srv2-fqdn> ..."
    echo "./createCerts.sh client <client-name>"
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
          -keyfile private/ca.key \
          -cert certs/ca.crt \
          -out certs/$server.crt -infiles reqs/$server.csr
    done
}

createMultiServer() {

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
      -keyfile private/ca.key \
      -cert certs/ca.crt \
      -out certs/$certname.crt -infiles reqs/$certname.csr
}

createClient(){

    unset SAN
    client="$1"
    openssl req -config openssl.cnf -new -nodes \
        -keyout private/client-$client.key -out reqs/client-$client.csr

    openssl ca -config openssl.cnf -extensions cluster_client \
        -keyfile private/ca.key \
        -cert certs/ca.crt \
        -out certs/client-$client.crt -infiles reqs/client-$client.csr
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
    
         *) print_help
            exit 1
            ;;
esac
