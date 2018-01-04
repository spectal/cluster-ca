# cluster-ca OpenSSL configuration.
SAN = "IP:127.0.0.1"
dir = .

[ ca ]
default_ca = cluster_ca
crlDistributionPoints = URI:https://testserver.foo/crl.pem

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
default_days     = 730
default_crl_days = 30
default_md       = sha512
preserve         = no
policy           = policy_cluster

[ crl_ext  ]
authorityKeyIdentifier = keyid:always,issuer:always

[ policy_cluster ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied

[ req ]
default_bits       = 4096
default_keyfile    = privkey.pem
distinguished_name = req_distinguished_name
attributes         = req_attributes
x509_extensions    = v3_ca
string_mask        = utf8only

[ req_distinguished_name ]
countryName                = Country Name (2 letter code)
countryName_default        = XX
countryName_min            = 2
countryName_max            = 2
commonName                 = Common Name (e.g. FQDN) 
stateOrProvinceName        = State or Province Name (full name)
localityName               = Locality Name (eg, city)
organizationName           = Organization Name (e.g. company)
organizationName_default   = __ORGUNIT__
organizationalUnitName     = purpose for this cert (e.g. admin-rpc)

[ req_attributes ]

[ v3_ca ]
basicConstraints       = CA:true
keyUsage               = keyCertSign,cRLSign
subjectKeyIdentifier   = hash

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ cluster_client ]
basicConstraints       = CA:FALSE
extendedKeyUsage       = clientAuth
keyUsage               = digitalSignature, keyEncipherment
subjectKeyIdentifier   = hash
authorityKeyIdentifier=keyid:always,issuer

[ cluster_peer ]
basicConstraints       = CA:FALSE
extendedKeyUsage       = clientAuth, serverAuth
keyUsage               = digitalSignature, keyEncipherment
subjectKeyIdentifier   = hash
authorityKeyIdentifier=keyid:always,issuer
subjectAltName         = ${ENV::SAN}

[ cluster_server ]
basicConstraints       = CA:FALSE
extendedKeyUsage       = clientAuth, serverAuth
keyUsage               = digitalSignature, keyEncipherment
subjectKeyIdentifier   = hash
authorityKeyIdentifier=keyid:always,issuer
subjectAltName         = ${ENV::SAN} 
