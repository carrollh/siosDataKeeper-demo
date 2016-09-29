configuration ConfigureSiosVM0
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

		[Parameter(Mandatory)]
        [String]$LicenseKeyFtpURL,
				
		[Parameter(Mandatory)]
        [String]$ClusterName,

        [Parameter(Mandatory)]
        [String]$SharePath,

        [Parameter(Mandatory)]
        [String[]]$Nodes,

        [Int]$RetryCount=20,
				
        [Int]$RetryIntervalSec=30		 
    )

	$node0 = "sios-0." + $DomainName	
	$node1 = "sios-1." + $DomainName

    Import-DscResource -ModuleName cDisk, xActiveDirectory, xComputerManagement, xDataKeeper, xDisk, xFailOverCluster, xNetworking
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
    
	$AdminUser = $DomainNetbiosName + "\" + $Admincreds.UserName
	$Password = $Admincreds.GetNetworkCredential().password
	
    Node localhost
    {
        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }

        cDiskNoRestart DataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
        }

        WindowsFeature FC
        {
            Name = "Failover-Clustering"
            Ensure = "Present"
        }

		WindowsFeature FCMGMT
		{
			Name = "RSAT-Clustering-Mgmt"
			Ensure = "Present"
		}

        WindowsFeature FCPS
        {
            Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
        }

        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }
				
        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
			DependsOn = "[WindowsFeature]ADPS"
		}
				
        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
			DependsOn = "[xWaitForADDomain]DscForestWait"
        }

		InstallLicense GetDKCELic
		{
			LicenseKeyFtpURL = $LicenseKeyFtpURL 
            RetryIntervalSec = $RetryIntervalSec
			RetryCount = $RetryCount 
			DependsOn = "[xComputer]DomainJoin"
		}
		
		sService StartExtMirr
		{
			Name = "extmirrsvc"
			StartupType = "Automatic"
			State = "Running"
			DependsOn = "[InstallLicense]GetDKCELic"
		}

		CreateJob NewJob
		{
			JobName 	= "Volume F Replication"
			JobDesc 	= "Protection for File Server Role"
			SourceName 	= $node0
			SourceIP 	= "10.0.0.5"
			SourceVol 	= "F"
			TargetName 	= $node1
			TargetIP 	= "10.0.0.6"
			TargetVol 	= "F"
			SyncType	= "A"
			RetryIntervalSec = 20 
			RetryCount		 = 30 
			DependsOn = "[sService]StartExtMirr"
		}

		CreateMirror NewMirror
		{
			SourceIP 	= "10.0.0.5"
			Volume	 	= "F"
			TargetIP 	= "10.0.0.6"
			SyncType	= "S"
			RetryIntervalSec = 20 
			RetryCount		 = 30
			DependsOn = "[CreateJob]NewJob"
		}

		xCluster FailoverCluster
        {
            Name = $ClusterName
            DomainAdministratorCredential = $DomainCreds
			Nodes = $Nodes
			DependsOn="[CreateMirror]NewMirror"
        }

        xWaitForFileShareWitness WaitForFSW
        {
            SharePath = $SharePath
            DomainAdministratorCredential = $DomainCreds
        }

        xClusterQuorum FailoverClusterQuorum
        {
            Name = $ClusterName
            SharePath = $SharePath
            DomainAdministratorCredential = $DomainCreds
			DependsOn = "[xWaitForFileShareWitness]WaitForFSW", "[xCluster]FailoverCluster"
        }
		
		RegisterClusterVolume RegClusVol
		{
			Volume = "F"
			DependsOn = "[xClusterQuorum]FailoverClusterQuorum"
		}
		
		InstallClusteredSQL InstallSQL
		{
			AdminUser = $AdminUser
			Password = $Password
			DependsOn = "[RegisterClusterVolume]RegClusVol"
			PsDscRunAsCredential = $Admincreds
		}
		
		SetSQLServerIP ResetSQLIP
		{
			InternalLoadBalancerIP = "10.0.0.200"
			DependsOn = "[InstallClusteredSQL]InstallSQL"
		}
			
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }
    }
}

function Get-NetBIOSName
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}