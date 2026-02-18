#!/bin/bash
# Self-Signed Root Certificate Authority Generator (Bash Version)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Root CA validity in days (20 years)
ROOT_CERT_VALIDITY_DAYS=7300

# Detect OpenSSL config file (use local if available, otherwise let openssl find system default)
OPENSSL_CONF_FILE=""
if [ -f "$SCRIPT_DIR/ssl/openssl.cnf" ]; then
    OPENSSL_CONF_FILE="$SCRIPT_DIR/ssl/openssl.cnf"
    OPENSSL_CONF_ARGS="-config $OPENSSL_CONF_FILE"
else
    OPENSSL_CONF_ARGS=""
fi

# CN: CommonName
DEFAULT_COMMON_NAME="Maks-IT Root CA"
read -p "CommonName? (default: $DEFAULT_COMMON_NAME): " inputCommonName
commonName="${inputCommonName:-$DEFAULT_COMMON_NAME}"

# O: Organization
DEFAULT_ORGANIZATION="Maks-IT LLC"
read -p "Organization? (default: $DEFAULT_ORGANIZATION): " inputOrganization
organization="${inputOrganization:-$DEFAULT_ORGANIZATION}"

# OU: OrganizationalUnit
DEFAULT_ORGANIZATIONAL_UNIT="IT Security Department"
read -p "OrganizationalUnit? (default: $DEFAULT_ORGANIZATIONAL_UNIT): " inputOrganizationalUnit
organizationalUnit="${inputOrganizationalUnit:-$DEFAULT_ORGANIZATIONAL_UNIT}"

# Remove existing rootCert directory if it exists, then create new one
rootCertPath="$SCRIPT_DIR/rootCert"
[ -d "$rootCertPath" ] && rm -rf "$rootCertPath"
mkdir -p "$rootCertPath"

# Change to the rootCert directory
cd "$rootCertPath" || exit 1

##############################################
# Generate a Certificate Authority Certificate
##############################################

# Generate a CA certificate private key
openssl genrsa -out ca.key 4096

# Generate the CA certificate
openssl req $OPENSSL_CONF_ARGS -x509 -new -nodes -sha512 -days $ROOT_CERT_VALIDITY_DAYS \
    -subj "/CN=$commonName/O=$organization/OU=$organizationalUnit" \
    -key ca.key \
    -out ca.crt

# Convert to PEM format
openssl x509 -in ca.crt -out ca.pem -outform PEM

echo ""
echo -e "\033[32mRoot CA certificate generated successfully in: $rootCertPath\033[0m"
echo ""
echo -e "\033[33mSECURITY WARNING:\033[0m"
echo -e "\033[33m  - ca.key is your ROOT CA PRIVATE KEY - NEVER copy or distribute it!\033[0m"
echo -e "\033[33m  - Keep ca.key only on this CA machine with restricted access\033[0m"
echo -e "\033[33m  - Distribute only ca.crt (public certificate) to clients/servers\033[0m"
echo ""
