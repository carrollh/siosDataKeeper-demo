configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [String]$SharePath,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName cDisk, xActiveDirectory, xDisk, xNetworking, xSMBShare, PSDesiredStateConfiguration

    $domainFQDN = Add-TopLevelDomain $DomainName
	
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${domainFQDN}\$($Admincreds.UserName)", $Admincreds.Password)
	
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)	

    Node localhost
    {
		Script script1
		{
			SetScript =  { 
				Set-DnsServerDiagnostics -All $true
				Write-Verbose -Verbose "Enabling DNS client diagnostics"
			}
			GetScript =  { @{} }
			TestScript = { $false}
			DependsOn = "[WindowsFeature]DNS"
        }
	
		WindowsFeature DNS 
		{ 
			Ensure = "Present" 
			Name = "DNS"		
		}

		WindowsFeature DnsTools
		{
			Ensure = "Present"
				Name = "RSAT-DNS-Server"
		}

		xDnsServerAddress DnsServerAddress 
		{ 
			Address        = '127.0.0.1' 
			InterfaceAlias = $InterfaceAlias
			AddressFamily  = 'IPv4'
			DependsOn = "[WindowsFeature]DNS"
		}

		xWaitforDisk Disk2
		{
				DiskNumber = 2
				RetryIntervalSec =$RetryIntervalSec
				RetryCount = $RetryCount
		}
		
		cDiskNoRestart ADDataDisk
		{
			DiskNumber = 2
			DriveLetter = "F"
		}
		
		WindowsFeature ADDSInstall 
		{ 
			Ensure = "Present" 
			Name = "AD-Domain-Services"
			DependsOn="[cDiskNoRestart]ADDataDisk"
		}  

		xADDomain FirstDS 
		{
			DomainName = $domainFQDN
			DomainAdministratorCredential = $DomainCreds
			SafemodeAdministratorPassword = $DomainCreds
			DatabasePath = "F:\NTDS"
			LogPath = "F:\NTDS"
			SysvolPath = "F:\SYSVOL"
			DependsOn = "[WindowsFeature]ADDSInstall"
		} 

		File FSWFolder
		{
			DestinationPath = "F:\$($SharePath.ToUpperInvariant())"
			Type = "Directory"
			Ensure = "Present"
			DependsOn = "[xADDomain]FirstDS"
		}

		xSmbShare FSWShare
		{
			Name = $SharePath.ToUpperInvariant()
			Path = "F:\$($SharePath.ToUpperInvariant())"
			FullAccess = "BUILTIN\Administrators"
			Ensure = "Present"
			DependsOn = "[File]FSWFolder"
		}

		LocalConfigurationManager 
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
		}
	}
} 

function Add-TopLevelDomain
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        return $DomainName
    }
    else {
        return ($DomainName + ".local")
    }
}