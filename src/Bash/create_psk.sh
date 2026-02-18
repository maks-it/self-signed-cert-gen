#!/bin/bash
# Pre-Shared Key (PSK) Generator (Bash Version)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "\033[36mPSK Generator:\033[0m"
echo -e "\033[90m  Creates a hex-encoded pre-shared key and identity.\033[0m"
echo -e "\033[90m  Useful for TLS-PSK (e.g., agents, services, lab devices).\033[0m"
echo ""

# PSK identity prompt
DEFAULT_IDENTITY="server01.corp.maks-it.com"
read -p "PSK Identity? (default: $DEFAULT_IDENTITY): " inputIdentity
pskIdentity="${inputIdentity:-$DEFAULT_IDENTITY}"

# PSK length prompt (bytes, hex encoded output will be twice the length)
DEFAULT_LENGTH_BYTES=32  # 256-bit key
read -p "PSK length in bytes? (default: $DEFAULT_LENGTH_BYTES): " inputLength
if [[ "$inputLength" =~ ^[0-9]+$ ]] && [ "$inputLength" -gt 0 ] && [ "$inputLength" -le 128 ]; then
    pskLengthBytes="$inputLength"
else
    pskLengthBytes="$DEFAULT_LENGTH_BYTES"
fi

# Prepare output folders
pskCertsPath="$SCRIPT_DIR/pskCerts"
mkdir -p "$pskCertsPath"

# Sanitize identity for folder/file name
safeName=$(echo "$pskIdentity" | sed 's/[^a-zA-Z0-9.-]/_/g')
[ -z "$safeName" ] && safeName="psk"
pskPath="$pskCertsPath/$safeName"

# Remove existing directory if it exists, then create new one
[ -d "$pskPath" ] && rm -rf "$pskPath"
mkdir -p "$pskPath"

# Generate PSK using OpenSSL (hex encoded)
pskHex=$(openssl rand -hex "$pskLengthBytes")

if [ -z "$pskHex" ]; then
    echo -e "\033[31mError generating PSK. Is OpenSSL installed?\033[0m"
    exit 1
fi

# Save PSK and identity
pskFile="$pskPath/$safeName.psk"
echo -n "$pskHex" > "$pskFile"
chmod 600 "$pskFile"

identityFile="$pskPath/identity.txt"
echo -n "$pskIdentity" > "$identityFile"

echo ""
echo -e "\033[32mPSK generated successfully in: $pskPath\033[0m"
echo ""
echo -e "\033[36mIdentity : $pskIdentity\033[0m"
echo -e "\033[33mPSK (hex): $pskHex\033[0m"
echo ""
echo -e "\033[36mFiles:\033[0m"
echo -e "\033[90m  $safeName.psk           - Pre-shared key (hex), keep it secret\033[0m"
echo -e "\033[90m  identity.txt            - Identity string to pair with the PSK\033[0m"
echo ""
echo -e "\033[33mSecurity note: store the .psk file securely and distribute only to trusted peers.\033[0m"
