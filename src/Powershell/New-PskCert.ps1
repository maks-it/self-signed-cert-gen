# Pre-Shared Key (PSK) Generator (PowerShell Version)

# Import OpenSSL utilities module
Import-Module (Join-Path $PSScriptRoot "OpenSSLUtils\OpenSSLUtils.psd1") -Force

# Get OpenSSL path or exit if not found
$openssl = Get-OpenSSLPathOrExit -BasePath $PSScriptRoot

Write-Host ""
Write-Host "PSK Generator:" -ForegroundColor Cyan
Write-Host "  Creates a hex-encoded pre-shared key and identity." -ForegroundColor Gray
Write-Host "  Useful for TLS-PSK (e.g., agents, services, lab devices)." -ForegroundColor Gray
Write-Host ""

# PSK identity prompt
$defaultIdentity = "server01.corp.maks-it.com"
$inputIdentity = Read-Host -Prompt "PSK Identity? (default: $defaultIdentity)"
$pskIdentity = if ($inputIdentity) { $inputIdentity } else { $defaultIdentity }

# PSK length prompt (bytes, hex encoded output will be twice the length)
$defaultLengthBytes = 32  # 256-bit key
$inputLength = Read-Host -Prompt "PSK length in bytes? (default: $defaultLengthBytes)"
$parsedLength = 0
$pskLengthBytes = if ([int]::TryParse($inputLength, [ref]$parsedLength) -and $parsedLength -gt 0 -and $parsedLength -le 128) {
	$parsedLength
} else {
	$defaultLengthBytes
}

# Prepare output folders (reuse certs folder for consistency)
$pskCertsPath = Join-Path $PSScriptRoot "pskCerts"
if (-not (Test-Path $pskCertsPath)) {
	New-Item -ItemType Directory -Path $pskCertsPath | Out-Null
}

$safeName = $pskIdentity -replace '[^a-zA-Z0-9.-]', '_'
if (-not $safeName) { $safeName = "psk" }
$pskPath = Join-Path $pskCertsPath $safeName

if (Test-Path $pskPath) {
	Remove-Item -Path $pskPath -Recurse -Force
}
New-Item -ItemType Directory -Path $pskPath | Out-Null

try {
	# Generate PSK using OpenSSL (hex encoded)
	$pskHex = (& $openssl rand -hex $pskLengthBytes).Trim()

	# Save PSK and identity
	$pskFile = Join-Path $pskPath "$safeName.psk"
	Set-Content -Path $pskFile -Value $pskHex -NoNewline

	$identityFile = Join-Path $pskPath "identity.txt"
	Set-Content -Path $identityFile -Value $pskIdentity -NoNewline

	Write-Host ""
	Write-Host "PSK generated successfully in: $pskPath" -ForegroundColor Green
	Write-Host ""
	Write-Host "Identity : $pskIdentity" -ForegroundColor Cyan
	Write-Host "PSK (hex): $pskHex" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Files:" -ForegroundColor Cyan
	Write-Host "  $safeName.psk           - Pre-shared key (hex), keep it secret" -ForegroundColor Gray
	Write-Host "  identity.txt            - Identity string to pair with the PSK" -ForegroundColor Gray
	Write-Host ""
	Write-Host "Security note: store the .psk file securely and distribute only to trusted peers." -ForegroundColor Yellow
}
catch {
	Write-Error $_
	exit 1
}
