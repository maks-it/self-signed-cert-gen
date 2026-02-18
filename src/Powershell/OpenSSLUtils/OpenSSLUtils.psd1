@{
    RootModule = 'OpenSSLUtils.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Maks-IT'
    Description = 'Utility functions for OpenSSL path detection and architecture handling'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-SystemArchitectureFolder',
        'Get-OpenSSLPath',
        'Get-OpenSSLPathOrExit',
        'Get-OpenSSLConfigPath'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
