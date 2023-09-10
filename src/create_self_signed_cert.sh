joinByChar() {
  local IFS="$1"
  shift
  echo "$*"
}

echo 'Organization? (example Maks-IT)'
read organization

echo 'OrganizationalUnit? (example Maks-IT)'
read organizationalUnit

echo 'CommonName? (example hcrsrv0001.corp.maks-it.com)'
read commonName

IFS="." read -ra DNSs <<< "$commonName"
LEN=${#DNSs[@]}

mkdir certs
cd certs

[ -d "$commonName" ] &&
rm $commonName -r

mkdir $commonName
cd $commonName

cp "../../rootCert/." . -r

###############################
# Generate a Server Certificate
###############################

# Generate a private key.
openssl genrsa -out "$commonName.key" 4096

# Generate a certificate signing request (CSR).
openssl req -sha512 -new \
 -subj "/CN=$commonName/O=$organization/OU=$organizationalUnit" \
 -key "$commonName.key" \
 -out "$commonName.csr"

# Generate an x509 v3 extension file.
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
EOF

echo "DNS.1=$(joinByChar . ${DNSs[@]:0:$LEN})" >> v3.ext
echo "DNS.2=$(joinByChar . ${DNSs[@]:0:1})" >> v3.ext

# for i in `seq 1 $LEN`
# do
#   echo "DNS.$i=$(joinByChar . ${DNSs[@]:0:$(expr $LEN-$i+1)})" >> v3.ext
# done

# Use the v3.ext file to generate a certificate for your host.
openssl x509 -req -sha512 -days 3650 \
 -extfile v3.ext \
 -CA "ca.crt" -CAkey "ca.key" -CAcreateserial \
 -in "$commonName.csr" \
 -out "$commonName.crt"
