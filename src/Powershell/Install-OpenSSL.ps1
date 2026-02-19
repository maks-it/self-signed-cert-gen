# OpenSSL Portable Installer for Windows
# Downloads OpenSSL binaries to utils folder

# Import OpenSSL utilities module
Import-Module (Join-Path $PSScriptRoot "OpenSSLUtils\OpenSSLUtils.psd1") -Force

$utilsPath = Join-Path $PSScriptRoot "utils"

# Create utils directory if it doesn't exist
if (-not (Test-Path $utilsPath)) {
    New-Item -ItemType Directory -Path $utilsPath | Out-Null
}

# Check if OpenSSL is already installed
$archFolder = Get-SystemArchitectureFolder
$openSSLExtractPath = Join-Path $utilsPath "openssl"
$localOpenSSL = Join-Path $openSSLExtractPath (Join-Path $archFolder "bin/openssl.exe")
if (Test-Path $localOpenSSL) {
    Write-Host "OpenSSL is already installed at: $localOpenSSL" -ForegroundColor Green
    & $localOpenSSL version
    exit 0
}

Write-Host "Downloading OpenSSL..." -ForegroundColor Cyan

# Using FireDaemon's latest OpenSSL builds (reliable, regularly updated)
# https://kb.firedaemon.com/support/solutions/articles/4000121705-openssl-binary-distributions-for-microsoft-windows
$downloadUrl = "https://download.firedaemon.com/FireDaemon-OpenSSL/openssl-3.6.1.zip"
$zipPath = Join-Path $utilsPath "openssl.zip"

try {
    # Download OpenSSL
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting OpenSSL..." -ForegroundColor Cyan

    # Extract to utils folder
    
    Expand-Archive -Path $zipPath -DestinationPath $openSSLExtractPath -Force

    # FireDaemon package extracts to openssl-3.x.x folder, rename to openssl
    $extractedFolder = Get-ChildItem -Path $openSSLExtractPath -Directory | Where-Object { $_.Name -like "openssl-*" } | Select-Object -First 1
    if ($extractedFolder) {
        # Get architecture folder from module
        $archFolder = Get-SystemArchitectureFolder
        $sourceBinPath = Join-Path $extractedFolder.FullName "$archFolder\bin"
        $targetBinPath = Join-Path $openSSLExtractPath (Join-Path $archFolder "bin")
        
        if (Test-Path $sourceBinPath) {
            # Create target architecture folder if needed
            $targetArchFolder = Join-Path $openSSLExtractPath $archFolder
            if (-not (Test-Path $targetArchFolder)) {
                New-Item -ItemType Directory -Path $targetArchFolder | Out-Null
            }
            # Remove existing bin folder if present
            if (Test-Path $targetBinPath) {
                Remove-Item -Path $targetBinPath -Recurse -Force
            }
            # Move bin folder to target location
            Move-Item -Path $sourceBinPath -Destination $targetBinPath
        } else {
            Write-Host "Could not find OpenSSL binaries for architecture: $archFolder" -ForegroundColor Red
            Remove-Item -Path $extractedFolder.FullName -Recurse -Force
            exit 1
        }
        # Clean up extracted folder
        Remove-Item -Path $extractedFolder.FullName -Recurse -Force
    }

    # Clean up zip file
    Remove-Item -Path $zipPath -Force

    # Add bin folder to PATH for this session
    $binFolder = Join-Path $openSSLExtractPath (Join-Path $archFolder "bin")
    $env:PATH = "$binFolder;$env:PATH"
    # Update $localOpenSSL to point to the new bin location
    $localOpenSSL = Join-Path $binFolder "openssl.exe"

    # Verify installation
    if (Test-Path $localOpenSSL) {
        Write-Host "OpenSSL installed successfully!" -ForegroundColor Green
        & $localOpenSSL version
    } elseif (Get-Command openssl -ErrorAction SilentlyContinue) {
        Write-Host "OpenSSL installed and available in PATH!" -ForegroundColor Green
        & openssl version
    } else {
        Write-Host "Installation failed - openssl.exe not found" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Error downloading/installing OpenSSL: $_" -ForegroundColor Red
    exit 1
}
