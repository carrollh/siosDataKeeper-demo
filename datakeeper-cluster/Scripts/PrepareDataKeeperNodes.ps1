param
(
    [Parameter(Mandatory=$true)]
    [String] $DomainFQDN, 

    [Parameter(Mandatory=$true)]
    [String] $AdminUserName,

    [Parameter(Mandatory=$true)]
    [String] $AdminBase64Password,
		
		[Parameter(Mandatory=$true)]
    [String] $LicenseKeyFtpURL,
		
		[Parameter(Mandatory=$true)]
    [int] $NodeIndex	
)

$logFile = "$env:windir\Temp\PrepareDataKeeperNode_log-$datetimestr.txt"
$licFolder = "$env:windir\SysWOW64\LKLicense"

function TraceInfo($log)
{
     "$(Get-Date -format 'MM/dd/yyyy HH:mm:ss') $log" | Add-Content -Confirm:$false $logFile 
}

function Add-InitialMirror {
	TraceInfo "MIRROR CREATED!!!"
}

Set-StrictMode -Version 3
$datetimestr = (Get-Date).ToString("yyyyMMddHHmmssfff")        

$AdminPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($AdminBase64Password))
$domainNetBios = $DomainFQDN.Split(".")[0].ToUpper()
$domainUserCred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList @("$domainNetBios\$AdminUserName", (ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force))

# 0 for Standalone Workstation, 1 for Member Workstation, 2 for Standalone Server, 3 for Member Server, 4 for Backup Domain Controller, 5 for Primary Domain Controller
$domainRole = (Get-WmiObject Win32_ComputerSystem).DomainRole
TraceInfo "Domain role $domainRole"
if($domainRole -ne 3)
{
    TraceInfo "$env:COMPUTERNAME does not join the domain, start to join domain $DomainFQDN"
    # join the domain
    while($true)
    {
        try
        {
            Add-Computer -DomainName $DomainFQDN -Credential $domainUserCred -ErrorAction Stop
            TraceInfo "Joined to the domain $DomainFQDN."
            break
        }
        catch
        {
            TraceInfo "Join domain failed, will try after 10 seconds, $_"
            # Flush the DNS cache in case the cached head node ip is wrong.
            # Do not use Clear-DnsClientCache because it is not supported in Windows Server 2008 R2
            Start-Process -FilePath ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow | Out-Null
            Start-Sleep -Seconds 10
        }
    }
}

TraceInfo "Start to set initialize data disk(s)"
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru |	New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
TraceInfo "Finished formatting data disk(s)"

TraceInfo "Downloading license file."
$licFile = ""
# check to see if the user pasted in a different license file, and preserve it's name / use it
# this also works if the user navigated to the link first and pasted in the full file path url 
if($LicenseKeyFtpURL.EndsWith(".lic"))) {
	$licFile = $LicenseKeyFtpURL.Substring($LicenseKeyFtpURL.LastIndexOf("/"))
	Invoke-WebRequest $LicenseKeyFtpURL -OutFile ($licFolder+$licFile)
} else { # otherwise use the standard file name
	$licFile = "/DK-W-Cluster.lic"
	Invoke-WebRequest ($LicenseKeyFtpURL+$licFile) -OutFile ($licFolder+$licFile)
}

if($(Test-Path ($licFolder+$licFile))) {
	TraceInfo "License file downloaded successfully."
	Restart-Service extmirrsvc
	Add-InitialMirror
} else {
	TraceInfo "Download FAILED, license not obtained."
}

TraceInfo "Enabling and Configuring WSFC"
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Import-Module FailoverClusters
# TODO: add node to cluster 
TraceInfo "Finished Configuring WSFC"

TraceInfo "Verifying ExtMirr Service is Running"
Restart-Service extmirrsvc
if(-Not $(Test-Path $env:windir\SysWOW64\LKLicense\extmirrsvc.lic)) {
	TraceInfo "ExtMirrsvc failed to start, aborting mirror creation."
	return 1
} 

TraceInfo "Enabling remote script execution between nodes."
Enable-PSRemoting -force
winrm s winrm/config/client '@{TrustedHosts="sios-0,sios-1"}'

Restart-Service winrm

if(-Not $(Get-Service extmirrsvc).Status -eq "Running") {
	TraceInfo "Remote Windows Management failed to start."
	return 1
}

if($NodeIndex -eq 0) {	
	TraceInfo "Waiting on sios-1 to start extmirrsvc"
	while($true) {
		if($(Get-Service extmirrsvc -ComputerName "sios-1").Status -eq "Running") {
			break
		} else {
			Start-Sleep 10
		}
	}

	TraceInfo "Creating mirror on volume F"
	New-DataKeeperJob "Volume F" "Initial Mirror" "sios-0" "10.0.0.5" "F" "sios-1" "10.0.0.6" "F" "Async"
	New-DataKeeperMirror "10.0.0.5" "F" "10.0.0.6" "F" "Async"
	
	# TODO: register mirror with cluster
	
	TraceInfo "Finished creating mirror. Restarting remote node (sios-1)."
	Restart-Computer sios-1 -force
	
	TraceInfo "Restarting this node (sios-0) after 30 seconds"
	Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"

} else {
	TraceInfo "Completed provisioning sios-1, sios-0 will restart this node."
}

TraceInfo "Restarting this node after 30 seconds"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"

