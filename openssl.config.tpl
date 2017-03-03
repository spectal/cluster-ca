# etcd OpenSSL configuration file.
SAN = "IP:127.0.0.1"
dir = .

[ ca ]
default_ca = cluster_ca

[ cluster_ca ]
certs            = $dir/certs
certificate      = $dir/certs/ca.crt
crl              = $dir/crl.pem
crl_dir          = $dir/crl
crlnumber        = $dir/crlnumber
database         = $dir/index.txt
email_in_dn      = no
new_certs_dir    = $dir/newcerts
private_key      = $dir/private/ca.key
serial           = $dir/serial
RANDFILE         = $dir/private/.rand
name_opt         = ca_default
cert_opt         = ca_default
default_days     = 3650
default_crl_days = 30
default_md       = sha512
preserve         = no
policy           = policy_cluster

[ policy_cluster ]
organizationName = optional
commonName       = supplied

[ req ]
default_bits       = 4096
default_keyfile    = privkey.pem
distinguished_name = req_distinguished_name
attributes         = req_attributes
x509_extensions    = v3_ca
string_mask        = utf8only
req_extensions     = cluster_client

[ req_distinguished_name ]
countryName                = Country Name (2 letter code)
countryName_default        = XX
countryName_min            = 2
countryName_max            = 2
commonName                 = Common Name (FQDN) 
0.organizationName         = Organization Name (eg, company)
0.organizationName_default = __ORGUNIT__

[ req_attributes ]

[ v3_ca ]
basicConstraints       = CA:true
keyUsage               = keyCertSign,cRLSign
subjectKeyIdentifier   = hash

[ cluster_client ]
basicConstraints       = CA:FALSE
extendedKeyUsage       = clientAuth
keyUsage               = digitalSignature, keyEncipherment

[ cluster_peer ]
basicConstraints       = CA:FALSE
extendedKeyUsage       = clientAuth, serverAuth
keyUsage               = digitalSignature, keyEncipherment
subjectAltName         = ${ENV::SAN}

[ cluster_server ]
basicConstraints       = CA:FALSE
extendedKeyUsage       = clientAuth, serverAuth
keyUsage               = digitalSignature, keyEncipherment
subjectAltName         = ${ENV::SAN} 
