# Install Root CA Certificate to Windows Trusted Root Store (PowerShell Version)

# Get script directory
$scriptDir = $PSScriptRoot

# Find the CA certificate
$rootCertPath = Join-Path $scriptDir "rootCert"
$caCertFile = Join-Path $rootCertPath "ca.crt"

Write-Host ""
Write-Host "Root CA Certificate Installer:" -ForegroundColor Cyan
Write-Host "  Installs the root CA certificate to Windows Trusted Root Certification Authorities." -ForegroundColor Gray
Write-Host ""

# Check if CA certificate exists
if (-not (Test-Path $caCertFile)) {
    Write-Host "Error: Root CA certificate not found at: $caCertFile" -ForegroundColor Red
    Write-Host "Run New-SelfSignedRootCert.ps1 first to generate the root CA." -ForegroundColor Yellow
    exit 1
}

# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Error: Administrator privileges required." -ForegroundColor Red
    Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
    exit 1
}

# Store selection
Write-Host "Certificate Store Selection:" -ForegroundColor Cyan
Write-Host "  LocalMachine - Install for all users on this computer (recommended)" -ForegroundColor Gray
Write-Host "  CurrentUser  - Install only for the current user" -ForegroundColor Gray
Write-Host ""
$defaultStore = "LocalMachine"
$inputStore = Read-Host -Prompt "Store Location? (LocalMachine/CurrentUser, default: $defaultStore)"
$storeLocation = switch -Regex ($inputStore) {
    "^[Cc]" { "CurrentUser" }
    default { "LocalMachine" }
}

try {
    # Load the certificate
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($caCertFile)
    
    # Open the Trusted Root Certification Authorities store
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", $storeLocation)
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    
    # Check if certificate already exists
    $existingCert = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    
    if ($existingCert) {
        Write-Host ""
        Write-Host "Certificate already installed in the store." -ForegroundColor Yellow
        Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    }
    else {
        # Add the certificate
        $store.Add($cert)
        
        Write-Host ""
        Write-Host "Root CA certificate installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Details:" -ForegroundColor Cyan
        Write-Host "  Subject    : $($cert.Subject)" -ForegroundColor Gray
        Write-Host "  Issuer     : $($cert.Issuer)" -ForegroundColor Gray
        Write-Host "  Thumbprint : $($cert.Thumbprint)" -ForegroundColor Gray
        Write-Host "  Valid From : $($cert.NotBefore)" -ForegroundColor Gray
        Write-Host "  Valid To   : $($cert.NotAfter)" -ForegroundColor Gray
        Write-Host "  Store      : $storeLocation\Root (Trusted Root Certification Authorities)" -ForegroundColor Gray
    }
    
    $store.Close()
    
    Write-Host ""
    Write-Host "The certificate is now trusted by this system." -ForegroundColor Green
}
catch {
    Write-Host "Error installing certificate: $_" -ForegroundColor Red
    exit 1
}
