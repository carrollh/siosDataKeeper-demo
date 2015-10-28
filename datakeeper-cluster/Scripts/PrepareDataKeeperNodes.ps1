param
(
    [Parameter(Mandatory=$true)]
    [String] $DomainFQDN, 

    [Parameter(Mandatory=$true)]
    [String] $AdminUserName,

    [Parameter(Mandatory=$true)]
    [String] $AdminBase64Password,
		
		[Parameter(Mandatory=$true)]
    [String] $TempLicense,
		
		[Parameter(Mandatory=$true)]
    [int] $NodeIndex	
)

function TraceInfo($log)
{
    if ($script:LogFile -ne $null)
    {
        "$(Get-Date -format 'MM/dd/yyyy HH:mm:ss') $log" | Out-File -Confirm:$false -FilePath $script:LogFile -Append
    }    
}

Set-StrictMode -Version 3
$datetimestr = (Get-Date).ToString("yyyyMMddHHmmssfff")        
$script:LogFile = "$env:windir\Temp\HpcPrepareCNLog-$datetimestr.txt"

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

TraceInfo "Installing DataKeeper license"
Add-Content $env:windir\SysWOW64\LKLicense\extmirrsvc.lic $TempLicense
TraceInfo "Finished installing DataKeeper license"

TraceInfo "Enabling and Configuring WSFC"
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Import-Module FailoverClusters
# TODO: add node to cluster 
TraceInfo "Finished Configuring WSFC"

TraceInfo "Verifying ExtMirr Service is Running"
while(-Not $(Test-Path $env:windir\SysWOW64\LKLicense\extmirrsvc.lic)) {
		Start-Sleep -Seconds 5
}
Restart-Service extmirrsvc
Start-Sleep -Seconds 10
if(-Not $(Get-Service extmirrsvc).Status -eq "Running") {
	TraceInfo "ExtMirr Service failed to start. Mirror not created."
	return 1
}

TraceInfo "Enabling remote script execution between nodes."
Enable-PSRemoting -force
winrm s winrm/config/client '@{TrustedHosts="sios-0,sios-1"}'

Restart-Service winrm
Start-Sleep -Seconds 10

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
	TraceInfo "Completed provisioning sios-1, waiting on sios-0 to restart this node."
}
