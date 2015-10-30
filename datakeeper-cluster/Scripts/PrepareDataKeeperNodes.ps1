param
(
    [Parameter(Mandatory=$true)]
    [String] $DomainFQDN, 

    [Parameter(Mandatory=$true)]
    [String] $AdminUserName,

    [Parameter(Mandatory=$true)]
    [String] $AdminBase64Password,
		
		[Parameter(Mandatory=$true)]
    [String] $TempLicense
)

function TraceInfo($log)
{
     "$(Get-Date -format 'MM/dd/yyyy HH:mm:ss') $log" | Add-Content -Confirm:$false $logFile 
}

Set-StrictMode -Version 3
$datetimestr = (Get-Date).ToString("yyyyMMddHHmmssfff")        
$logFile = "$env:windir\Temp\PrepareDataKeeperNode_log-$datetimestr.txt"

$license = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($TempLicense))
TraceInfo "PrepareDataKeeperNodes script called with TempLicense:"
TraceInfo $TempLicense
TraceInfo "TempLicense converted to: "
TraceInfo $license

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
$licfile = $env:windir\SysWOW64\LKLicense\extmirrsvc.lic
Add-Content $licfile $license
TraceInfo "Finished installing DataKeeper license"

TraceInfo "Enabling and Configuring WSFC"
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Import-Module FailoverClusters
# TODO: add node to cluster 
TraceInfo "Finished Configuring WSFC"

	
TraceInfo "Restarting this node (sios-0) after 30 seconds"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"
