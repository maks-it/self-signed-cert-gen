#!/bin/bash
# Self-Signed Certificate Generator (Bash Version)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Certificate validity in days (20 years)
CERT_VALIDITY_DAYS=7300

# Detect OpenSSL config file (use local if available, otherwise let openssl find system default)
OPENSSL_CONF_FILE=""
if [ -f "$SCRIPT_DIR/ssl/openssl.cnf" ]; then
    OPENSSL_CONF_FILE="$SCRIPT_DIR/ssl/openssl.cnf"
    OPENSSL_CONF_ARGS="-config $OPENSSL_CONF_FILE"
else
    OPENSSL_CONF_ARGS=""
fi

# Certificate type selection
echo ""
echo -e "\033[36mCertificate Type Selection:\033[0m"
echo -e "\033[90m  Server - TLS Web Server Authentication (serverAuth)\033[0m"
echo -e "\033[90m           Use for: Web servers, Zabbix Server, API endpoints\033[0m"
echo -e "\033[90m  Client - TLS Web Client Authentication (clientAuth)\033[0m"
echo -e "\033[90m           Use for: Zabbix Agent, client applications, mutual TLS\033[0m"
echo -e "\033[90m  Both   - Server and Client Authentication\033[0m"
echo -e "\033[90m           Use for: Peer-to-peer services, bidirectional TLS\033[0m"
echo ""
DEFAULT_TYPE="Server"
read -p "Certificate Type? (Server/Client/Both, default: $DEFAULT_TYPE): " inputType
if [[ "$inputType" =~ ^[Cc] ]]; then
    certType="Client"
    extendedKeyUsage="clientAuth"
elif [[ "$inputType" =~ ^[Bb] ]]; then
    certType="Both"
    extendedKeyUsage="serverAuth, clientAuth"
else
    certType="Server"
    extendedKeyUsage="serverAuth"
fi

# O: Organization
DEFAULT_ORGANIZATION="Maks-IT LLC"
read -p "Organization? (default: $DEFAULT_ORGANIZATION): " inputOrganization
organization="${inputOrganization:-$DEFAULT_ORGANIZATION}"

# OU: OrganizationalUnit
DEFAULT_ORGANIZATIONAL_UNIT="IT Department"
read -p "OrganizationalUnit? (default: $DEFAULT_ORGANIZATIONAL_UNIT): " inputOrganizationalUnit
organizationalUnit="${inputOrganizationalUnit:-$DEFAULT_ORGANIZATIONAL_UNIT}"

# CN: CommonName
DEFAULT_COMMON_NAME="server01.corp.maks-it.com"
read -p "CommonName? (default: $DEFAULT_COMMON_NAME): " inputCommonName
commonName="${inputCommonName:-$DEFAULT_COMMON_NAME}"

# Split common name to extract hostname for DNS alt names
IFS="." read -ra DNSs <<< "$commonName"

# Additional Subject Alternative Names (SANs)
echo ""
echo -e "\033[36mSubject Alternative Names (SANs):\033[0m"
echo -e "\033[90m  You can add additional DNS names or IP addresses.\033[0m"
echo -e "\033[90m  The CommonName and short hostname are automatically included.\033[0m"
echo -e "\033[90m  Enter comma-separated values (e.g., 192.168.1.100,app.local,10.0.0.5)\033[0m"
echo ""
read -p "Additional SANs? (leave empty to skip): " inputSANs
additionalSANs=()
if [ -n "$inputSANs" ]; then
    IFS=',' read -ra rawSANs <<< "$inputSANs"
    for san in "${rawSANs[@]}"; do
        trimmed=$(echo "$san" | xargs)
        [ -n "$trimmed" ] && additionalSANs+=("$trimmed")
    done
fi

# Create certs directory if it doesn't exist
certsPath="$SCRIPT_DIR/certs"
mkdir -p "$certsPath"

# Remove existing directory if it exists, then create new one
certPath="$certsPath/$commonName"
[ -d "$certPath" ] && rm -rf "$certPath"
mkdir -p "$certPath"

# Copy only the public CA certificate (NEVER copy ca.key!)
rootCertPath="$SCRIPT_DIR/rootCert"

# Verify root CA files exist
if [ ! -f "$rootCertPath/ca.crt" ] || [ ! -f "$rootCertPath/ca.key" ]; then
    echo -e "\033[31mRoot CA not found. Run create_self_signed_root_cert.sh first.\033[0m"
    exit 1
fi

# Copy only ca.crt - the public certificate for verification
cp "$rootCertPath/ca.crt" "$certPath/"

# Change to the certificate directory
cd "$certPath" || exit 1

###############################
# Generate a Server Certificate
###############################

# Generate a private key
openssl genrsa -out "$commonName.key" 4096

# Generate a certificate signing request (CSR)
openssl req $OPENSSL_CONF_ARGS -sha512 -new \
    -subj "/CN=$commonName/O=$organization/OU=$organizationalUnit" \
    -key "$commonName.key" \
    -out "$commonName.csr"

# Generate an x509 v3 extension file
# Build SAN entries - DNS.1 = Full FQDN, DNS.2 = Short hostname, then additional SANs
dnsIndex=1
ipIndex=1
sanEntries=""

# Add CommonName as DNS.1
sanEntries+="DNS.$dnsIndex=$commonName"$'\n'
((dnsIndex++))

# Add short hostname as DNS.2
sanEntries+="DNS.$dnsIndex=${DNSs[0]}"$'\n'
((dnsIndex++))

# Process additional SANs - detect IP vs DNS
for san in "${additionalSANs[@]}"; do
    # Check if it's an IP address (IPv4 or IPv6)
    if [[ "$san" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ "$san" =~ : ]]; then
        sanEntries+="IP.$ipIndex=$san"$'\n'
        ((ipIndex++))
    else
        sanEntries+="DNS.$dnsIndex=$san"$'\n'
        ((dnsIndex++))
    fi
done

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = $extendedKeyUsage
subjectAltName = @alt_names

[alt_names]
${sanEntries}EOF

# Use the v3.ext file to generate a certificate for your host
# Note: ca.key is referenced from rootCert directory, NOT copied here
openssl x509 -req -sha512 -days $CERT_VALIDITY_DAYS \
    -extfile v3.ext \
    -CA "ca.crt" -CAkey "$rootCertPath/ca.key" -CAcreateserial \
    -in "$commonName.csr" \
    -out "$commonName.crt"

# Clean up temporary files (no longer needed after signing)
rm -f v3.ext "$commonName.csr" ca.srl 2>/dev/null

echo ""
echo -e "\033[32m$certType certificate generated successfully in: $certPath\033[0m"
echo ""
echo -e "\033[36mOutput files:\033[0m"
echo -e "\033[90m  ca.crt            - CA public certificate (for trust verification)\033[0m"
echo -e "\033[90m  $commonName.key   - Private key (keep secure!)\033[0m"
echo -e "\033[90m  $commonName.crt   - Signed certificate\033[0m"
echo ""
echo -e "\033[33mSECURITY NOTE: ca.key was NOT copied here (stays only in rootCert/)\033[0m"
