# Self-Signed Certificate Generator (PowerShell Version)

# Import OpenSSL utilities module
Import-Module (Join-Path $PSScriptRoot "OpenSSLUtils\OpenSSLUtils.psd1") -Force

$certValidityDays = 7300  # Certificate validity in days (20 years)

# Get OpenSSL path or exit if not found
$openssl = Get-OpenSSLPathOrExit -BasePath $PSScriptRoot
$opensslConfig = Get-OpenSSLConfigPath -BasePath $PSScriptRoot
$configArgs = if ($opensslConfig) { @("-config", $opensslConfig) } else { @() }

# Certificate type selection
Write-Host ""
Write-Host "Certificate Type Selection:" -ForegroundColor Cyan
Write-Host "  Server - TLS Web Server Authentication (serverAuth)" -ForegroundColor Gray
Write-Host "           Use for: Web servers, Zabbix Server, API endpoints" -ForegroundColor Gray
Write-Host "  Client - TLS Web Client Authentication (clientAuth)" -ForegroundColor Gray
Write-Host "           Use for: Zabbix Agent, client applications, mutual TLS" -ForegroundColor Gray
Write-Host "  Both   - Server and Client Authentication" -ForegroundColor Gray
Write-Host "           Use for: Peer-to-peer services, bidirectional TLS" -ForegroundColor Gray
Write-Host ""
$defaultType = "Server"
$inputType = Read-Host -Prompt "Certificate Type? (Server/Client/Both, default: $defaultType)"
$certType = switch -Regex ($inputType) {
    "^[Cc]" { "Client" }
    "^[Bb]" { "Both" }
    default { "Server" }
}
$extendedKeyUsage = switch ($certType) {
    "Client" { "clientAuth" }
    "Both"   { "serverAuth, clientAuth" }
    default  { "serverAuth" }
}

$defaultOrganization = "Maks-IT LLC"
$inputOrganization = Read-Host -Prompt "Organization? (default: $defaultOrganization)"
$organization = if ($inputOrganization) { $inputOrganization } else { $defaultOrganization }

$defaultOrganizationalUnit = "IT Department"
$inputOrganizationalUnit = Read-Host -Prompt "OrganizationalUnit? (default: $defaultOrganizationalUnit)"
$organizationalUnit = if ($inputOrganizationalUnit) { $inputOrganizationalUnit } else { $defaultOrganizationalUnit }

$defaultCommonName = "server01.corp.maks-it.com"
$inputCommonName = Read-Host -Prompt "CommonName? (default: $defaultCommonName)"
$commonName = if ($inputCommonName) { $inputCommonName } else { $defaultCommonName }

# Split common name to extract hostname for DNS alt names
$DNSs = $commonName -split '\.'

# Additional Subject Alternative Names (SANs)
Write-Host ""
Write-Host "Subject Alternative Names (SANs):" -ForegroundColor Cyan
Write-Host "  You can add additional DNS names or IP addresses." -ForegroundColor Gray
Write-Host "  The CommonName and short hostname are automatically included." -ForegroundColor Gray
Write-Host "  Enter comma-separated values (e.g., 192.168.1.100,app.local,10.0.0.5)" -ForegroundColor Gray
Write-Host ""
$inputSANs = Read-Host -Prompt "Additional SANs? (leave empty to skip)"
$additionalSANs = if ($inputSANs) { 
    $inputSANs -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
} else { 
    @() 
}

# Create certs directory if it doesn't exist
$certsPath = Join-Path $PSScriptRoot "certs"
if (-not (Test-Path $certsPath)) {
    New-Item -ItemType Directory -Path $certsPath | Out-Null
}

# Remove existing directory if it exists, then create new one
$certPath = Join-Path $certsPath $commonName
if (Test-Path $certPath) {
    Remove-Item -Path $certPath -Recurse -Force
}
New-Item -ItemType Directory -Path $certPath | Out-Null

# Copy only the public CA certificate (NEVER copy ca.key!)
$rootCertPath = Join-Path $PSScriptRoot "rootCert"

# Verify root CA files exist
if (-not (Test-Path "$rootCertPath\ca.crt") -or -not (Test-Path "$rootCertPath\ca.key")) {
    Write-Host "Root CA not found. Run New-SelfSignedRootCert.ps1 first." -ForegroundColor Red
    exit 1
}

# Copy only ca.crt - the public certificate for verification
Copy-Item -Path "$rootCertPath\ca.crt" -Destination $certPath

# Change to the certificate directory
Push-Location $certPath

try {
    ###############################
    # Generate a Server Certificate
    ###############################

    # Generate a private key
    & $openssl genrsa -out "$commonName.key" 4096

    # Generate a certificate signing request (CSR)
    & $openssl req @configArgs -sha512 -new `
        -subj "/CN=$commonName/O=$organization/OU=$organizationalUnit" `
        -key "$commonName.key" `
        -out "$commonName.csr"

    # Generate an x509 v3 extension file
    # Build SAN entries - DNS.1 = Full FQDN, DNS.2 = Short hostname, then additional SANs
    $dnsIndex = 1
    $ipIndex = 1
    $sanEntries = @()
    
    # Add CommonName as DNS.1
    $sanEntries += "DNS.$dnsIndex=$($DNSs -join '.')"
    $dnsIndex++
    
    # Add short hostname as DNS.2
    $sanEntries += "DNS.$dnsIndex=$($DNSs[0])"
    $dnsIndex++
    
    # Process additional SANs - detect IP vs DNS
    foreach ($san in $additionalSANs) {
        # Check if it's an IP address (IPv4 or IPv6)
        if ($san -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' -or $san -match ':') {
            $sanEntries += "IP.$ipIndex=$san"
            $ipIndex++
        } else {
            $sanEntries += "DNS.$dnsIndex=$san"
            $dnsIndex++
        }
    }
    
    $v3ExtContent = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = $extendedKeyUsage
subjectAltName = @alt_names

[alt_names]
$($sanEntries -join "`n")
"@

    Set-Content -Path "v3.ext" -Value $v3ExtContent -NoNewline

    # Use the v3.ext file to generate a certificate for your host
    # Note: ca.key is referenced from rootCert directory, NOT copied here
    & $openssl x509 -req -sha512 -days $certValidityDays `
        -extfile "v3.ext" `
        -CA "ca.crt" -CAkey "$rootCertPath\ca.key" -CAcreateserial `
        -in "$commonName.csr" `
        -out "$commonName.crt"

    # Clean up temporary files (no longer needed after signing)
    Remove-Item -Path "v3.ext" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$commonName.csr" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "ca.srl" -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "$certType certificate generated successfully in: $certPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output files:" -ForegroundColor Cyan
    Write-Host "  ca.crt            - CA public certificate (for trust verification)" -ForegroundColor Gray
    Write-Host "  $commonName.key   - Private key (keep secure!)" -ForegroundColor Gray
    Write-Host "  $commonName.crt   - Signed certificate" -ForegroundColor Gray
    Write-Host ""
    Write-Host "SECURITY NOTE: ca.key was NOT copied here (stays only in rootCert/)" -ForegroundColor Yellow
}
finally {
    Pop-Location
}
