# Set-ExecutionPolicyUnrestricted.ps1

[CmdletBinding()]
Param(
    [string] $adminUsername,
    [securestring] $adminPassword
)

$creds = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

Invoke-Command -ComputerName "localhost" -Credential $creds -ScriptBlock { Set-ExecutionPolicy Unrestricted }
