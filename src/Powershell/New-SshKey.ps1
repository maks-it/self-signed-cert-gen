<# 
    SSH Key Pair Generator (PowerShell Version)

    This script is a lightweight wrapper around ssh-keygen to create SSH key pairs
    with sensible defaults and a similar UX to the other tools in this repo.
#>

Write-Host ""
Write-Host "SSH Key Generator:" -ForegroundColor Cyan
Write-Host "  Creates an SSH key pair using ssh-keygen." -ForegroundColor Gray
Write-Host "  Supports ed25519 (default) and RSA keys." -ForegroundColor Gray
Write-Host "  Can output private key in OpenSSH or PEM format." -ForegroundColor Gray
Write-Host ""

# Ensure ssh-keygen is available
$sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if (-not $sshKeygen) {
    Write-Host "Error: ssh-keygen not found on PATH." -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "On Windows 10/11 you can enable the OpenSSH Client feature:" -ForegroundColor Yellow
    Write-Host "  Settings -> Apps -> Optional features -> Add a feature -> OpenSSH Client" -ForegroundColor Gray
    Write-Host "or install Git for Windows and ensure its ssh tools are on PATH." -ForegroundColor Gray
    exit 1
}

$scriptDir = $PSScriptRoot

# Prepare output folder
$sshKeysPath = Join-Path $scriptDir "sshKeys"
if (-not (Test-Path $sshKeysPath)) {
    New-Item -ItemType Directory -Path $sshKeysPath | Out-Null
}

# Key type
$defaultType = "ed25519"
Write-Host "Key Type:" -ForegroundColor Cyan
Write-Host "  ed25519 - Modern, recommended (default)" -ForegroundColor Gray
Write-Host "  rsa     - Legacy/interoperability" -ForegroundColor Gray
Write-Host ""
$inputType = Read-Host -Prompt "Key type? (ed25519/rsa, default: $defaultType)"
$keyType = if ($inputType -match '^(rsa|ed25519)$') { $inputType.ToLower() } else { $defaultType }

# RSA key size (ed25519 ignores -b)
$bits = $null
if ($keyType -eq "rsa") {
    $defaultBits = 4096
    $inputBits = Read-Host -Prompt "RSA key size in bits? (default: $defaultBits)"
    $parsedBits = 0
    # Allow 1024-bit for legacy devices (e.g., Cisco SG500), though it is not recommended for new systems
    $bits = if ([int]::TryParse($inputBits, [ref]$parsedBits) -and $parsedBits -ge 1024) {
        $parsedBits
    } else {
        $defaultBits
    }
}

# Private key format
$defaultFormat = "OpenSSH"
Write-Host ""
Write-Host "Private Key Format:" -ForegroundColor Cyan
Write-Host "  OpenSSH - Default ssh-keygen format (recommended for SSH)" -ForegroundColor Gray
Write-Host "  PEM     - PEM-encoded private key (useful for some tools/APIs)" -ForegroundColor Gray
Write-Host ""
$inputFormat = Read-Host -Prompt "Private key format? (OpenSSH/PEM, default: $defaultFormat)"
$format = if ($inputFormat -match '^(pem|openssh)$') { 
    $inputFormat.ToUpper() 
} else { 
    $defaultFormat 
}

# File name (within sshKeys folder)
$defaultFileName = if ($keyType -eq "rsa") { "id_rsa" } else { "id_ed25519" }
$inputFileName = Read-Host -Prompt "Key file name (without path, default: $defaultFileName)"
$fileName = if ($inputFileName) { $inputFileName } else { $defaultFileName }
$fileName = $fileName.Trim()
if (-not $fileName) { $fileName = $defaultFileName }

$keyFile = Join-Path $sshKeysPath $fileName

# Check if file exists
if ((Test-Path $keyFile) -or (Test-Path "$keyFile.pub")) {
    Write-Host ""
    Write-Host "Warning: Key file already exists at:" -ForegroundColor Yellow
    Write-Host "  $keyFile" -ForegroundColor Gray
    Write-Host ""
    $overwrite = Read-Host -Prompt "Overwrite existing key? (y/N)"
    if ($overwrite -notmatch '^(y|yes)$') {
        Write-Host "Aborted by user. No keys were created." -ForegroundColor Yellow
        exit 1
    }
}

# Comment for the key (shows up in authorized_keys)
$defaultComment = "$env:USERNAME@$(hostname)"
$inputComment = Read-Host -Prompt "Key comment? (default: $defaultComment)"
$comment = if ($inputComment) { $inputComment } else { $defaultComment }

Write-Host ""
Write-Host "Invoking ssh-keygen..." -ForegroundColor Cyan
Write-Host "  Type   : $keyType" -ForegroundColor Gray
if ($bits) {
    Write-Host "  Bits   : $bits" -ForegroundColor Gray
}
Write-Host "  Format : $format" -ForegroundColor Gray
Write-Host "  Output : $keyFile" -ForegroundColor Gray
Write-Host "  Comment: $comment" -ForegroundColor Gray
Write-Host ""
Write-Host "You will now be prompted for an optional passphrase by ssh-keygen." -ForegroundColor Yellow
Write-Host ""

try {
    $args = @("-t", $keyType, "-f", $keyFile, "-C", $comment)
    if ($bits) {
        $args += @("-b", $bits)
    }

    if ($format -eq "PEM") {
        $args += @("-m", "PEM")
    }

    & $sshKeygen @args
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ssh-keygen exited with code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # Optional: export public key in PEM (PKCS8) format
    Write-Host ""
    $exportPem = Read-Host -Prompt "Also export PUBLIC key in PEM format (-----BEGIN PUBLIC KEY-----)? (y/N)"
    $pemPubFile = Join-Path $sshKeysPath ($fileName + ".pub.pem")
    if ($exportPem -match '^(y|yes)$') {
        try {
            # Export in PKCS8 PEM format; preserve original newlines
            & $sshKeygen -e -m PKCS8 -f $keyFile | Set-Content -Path $pemPubFile
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: ssh-keygen -e returned code $LASTEXITCODE, PEM public key may not have been created." -ForegroundColor Yellow
            }
            else {
                Write-Host "PEM public key exported to: $pemPubFile" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error exporting PEM public key: $_" -ForegroundColor Yellow
        }
    }

    # Optional: export public key in SSH2 (RFC4716) format for legacy Cisco devices
    Write-Host ""
    $exportSsh2 = Read-Host -Prompt "Also export PUBLIC key in SSH2 format (---- BEGIN SSH2 PUBLIC KEY ----)? (y/N)"
    $ssh2PubFile = Join-Path $sshKeysPath ($fileName + ".ssh2.pub")
    if ($exportSsh2 -match '^(y|yes)$') {
        try {
            & $sshKeygen -e -m RFC4716 -f $keyFile | Set-Content -Path $ssh2PubFile
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: ssh-keygen -e returned code $LASTEXITCODE, SSH2 public key may not have been created." -ForegroundColor Yellow
            }
            else {
                Write-Host "SSH2 public key exported to: $ssh2PubFile" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error exporting SSH2 public key: $_" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "SSH key pair generated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files:" -ForegroundColor Cyan
    Write-Host "  $fileName       - Private key (keep this secret!)" -ForegroundColor Gray
    Write-Host "  $fileName.pub   - Public key (OpenSSH, share with servers/services)" -ForegroundColor Gray
    if (Test-Path $pemPubFile) {
        Write-Host "  $($fileName).pub.pem - Public key (PEM, -----BEGIN PUBLIC KEY-----)" -ForegroundColor Gray
    }
    if (Test-Path $ssh2PubFile) {
        Write-Host "  $($fileName).ssh2.pub - Public key (SSH2/RFC4716, ---- BEGIN SSH2 PUBLIC KEY ----)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Private key format:" -ForegroundColor Cyan
    Write-Host "  $format" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Location:" -ForegroundColor Cyan
    Write-Host "  $sshKeysPath" -ForegroundColor Gray
}
catch {
    Write-Host "Error running ssh-keygen: $_" -ForegroundColor Red
    exit 1
}

