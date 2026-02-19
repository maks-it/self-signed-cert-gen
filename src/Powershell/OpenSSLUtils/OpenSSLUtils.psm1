# OpenSSL Utilities Module

function Get-SystemArchitectureFolder {
    <#
    .SYNOPSIS
        Returns the architecture folder name based on the current system.
    #>
    $arch = $env:PROCESSOR_ARCHITECTURE
    switch ($arch) {
        "AMD64" { return "x64" }
        "x86"   { return "x86" }
        "ARM64" { return "arm64" }
        default { return "x64" }
    }
}

function Get-OpenSSLPath {
    <#
    .SYNOPSIS
        Returns the path to the OpenSSL executable.
    .DESCRIPTION
        Checks for a local OpenSSL installation in the utils folder (architecture-specific),
        falls back to system PATH, or returns $null if not found.
    .PARAMETER BasePath
        The base path where the utils folder is located. Defaults to the script root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )

    $archFolder = Get-SystemArchitectureFolder
    $localOpenSSL = Join-Path $BasePath (Join-Path "utils/openssl" (Join-Path $archFolder "bin/openssl.exe"))
    
    if (Test-Path $localOpenSSL) {
        return $localOpenSSL
    } elseif (Get-Command openssl -ErrorAction SilentlyContinue) {
        return "openssl"
    } else {
        return $null
    }
}

function Get-OpenSSLPathOrExit {
    <#
    .SYNOPSIS
        Returns the path to the OpenSSL executable or exits with an error.
    .PARAMETER BasePath
        The base path where the utils folder is located.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )

    $opensslPath = Get-OpenSSLPath -BasePath $BasePath
    if (-not $opensslPath) {
        Write-Host "OpenSSL not found. Run Install-OpenSSL.ps1 first or install OpenSSL to PATH." -ForegroundColor Red
        exit 1
    }
    return $opensslPath
}

function Get-OpenSSLConfigPath {
    <#
    .SYNOPSIS
        Returns the path to the OpenSSL config file.
    .PARAMETER BasePath
        The base path where the utils folder is located.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )

    $localConfig = Join-Path $BasePath "utils\ssl\openssl.cnf"
    if (Test-Path $localConfig) {
        return $localConfig
    }
    return $null
}

Export-ModuleMember -Function Get-SystemArchitectureFolder, Get-OpenSSLPath, Get-OpenSSLPathOrExit, Get-OpenSSLConfigPath
