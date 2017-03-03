#!/bin/bash
set -x
caname="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

print_help(){
    echo "./createCerts.sh <server> <srv1-fqdn> <srv2-fqdn> ..."
    echo "./createCerts.sh <client> <client-name>"
}

createServer(){

    if [ -x "$(which pass)" ]
    then
        echo "getting key from password-store"
        pass -c cluster-ca/$caname/ca-key-pass
    fi
    for server in "$@"
    do
        if [ -x "$(which dig)" ]
        then
            IP=$(dig +short $server)
        else
            IP=""
        fi

        if [ -z "$IP" ]
        then
            export SAN="DNS:$server"
        else
            export SAN="DNS:$server, IP:$IP"
        fi

        openssl req -config openssl.cnf -new -nodes \
          -keyout private/$server.key -out $server.csr

        openssl ca -config openssl.cnf -extensions cluster_server \
          -keyfile private/ca.key \
          -cert certs/ca.crt \
          -out certs/$server.crt -infiles $server.csr

    done
}

createClient(){

    unset SAN
    client="$1"
    openssl req -config openssl.cnf -new -nodes \
        -keyout private/client-$client.key -out client-$client.csr

    openssl ca -config openssl.cnf -extensions cluster_client \
        -keyfile private/ca.key \
        -cert certs/ca.crt \
        -out certs/client-$client.crt -infiles client-$client.csr
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
    
         *) print_help
            exit 1
            ;;
esac


