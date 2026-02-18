# Self-Signed Root Certificate Authority Generator (PowerShell Version)

# Import OpenSSL utilities module
Import-Module (Join-Path $PSScriptRoot "OpenSSLUtils\OpenSSLUtils.psd1") -Force

$rootCertValidityDays = 7300  # Root CA validity in days (20 years)

# Get OpenSSL path or exit if not found
$openssl = Get-OpenSSLPathOrExit -BasePath $PSScriptRoot
$opensslConfig = Get-OpenSSLConfigPath -BasePath $PSScriptRoot
$configArgs = if ($opensslConfig) { @("-config", $opensslConfig) } else { @() }

# CN: CommonName
$defaultCommonName = "Maks-IT Root CA"
$inputCommonName = Read-Host -Prompt "CommonName? (default: $defaultCommonName)"
$commonName = if ($inputCommonName) { $inputCommonName } else { $defaultCommonName }

# O: Organization
$defaultOrganization = "Maks-IT LLC"
$inputOrganization = Read-Host -Prompt "Organization? (default: $defaultOrganization)"
$organization = if ($inputOrganization) { $inputOrganization } else { $defaultOrganization }

# OU: OrganizationalUnit
$defaultOrganizationalUnit = "IT Security Department"
$inputOrganizationalUnit = Read-Host -Prompt "OrganizationalUnit? (default: $defaultOrganizationalUnit)"
$organizationalUnit = if ($inputOrganizationalUnit) { $inputOrganizationalUnit } else { $defaultOrganizationalUnit }

# Remove existing rootCert directory if it exists, then create new one
$rootCertPath = Join-Path $PSScriptRoot "rootCert"
if (Test-Path $rootCertPath) {
    Remove-Item -Path $rootCertPath -Recurse -Force
}
New-Item -ItemType Directory -Path $rootCertPath | Out-Null

# Change to the rootCert directory
Push-Location $rootCertPath

try {
    ##############################################
    # Generate a Certificate Authority Certificate
    ##############################################

    # Generate a CA certificate private key
    & $openssl genrsa -out ca.key 4096

    # Generate the CA certificate
    & $openssl req @configArgs -x509 -new -nodes -sha512 -days $rootCertValidityDays `
        -subj "/CN=$commonName/O=$organization/OU=$organizationalUnit" `
        -key ca.key `
        -out ca.crt

    # Convert to PEM format
    & $openssl x509 -in ca.crt -out ca.pem -outform PEM

    Write-Host ""
    Write-Host "Root CA certificate generated successfully in: $rootCertPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "SECURITY WARNING:" -ForegroundColor Yellow
    Write-Host "  - ca.key is your ROOT CA PRIVATE KEY - NEVER copy or distribute it!" -ForegroundColor Yellow
    Write-Host "  - Keep ca.key only on this CA machine with restricted access" -ForegroundColor Yellow
    Write-Host "  - Distribute only ca.crt (public certificate) to clients/servers" -ForegroundColor Yellow
    Write-Host ""
}
finally {
    Pop-Location
}
