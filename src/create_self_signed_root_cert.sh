# CN: CommonName CN = Maks-IT
echo 'CommonName? (example Maks-IT)'
read commonName

# O: Organization O = Maks-IT
echo 'Organization? (example Maks-IT)'
read organization

# OU: OrganizationalUnit OU = Maks-IT Root CA
echo 'OrganizationalUnit? (example Maks-IT Root CA)'
read organizationalUnit

[ -d "rootCert" ] &&
rm rootCert -r

mkdir rootCert
cd rootCert

##############################################
# Generate a Certificate Authority Certificate
##############################################

# Generate a CA certificate private key.
openssl genrsa -out ca.key 4096

# Generate the CA certificate.
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/CN=$commonName/O=$organization/OU=$organizationalUnit" \
 -key ca.key \
 -out ca.crt

openssl x509 -in ca.crt -out ca.pem -outform PEM
 