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
	TraceInfo "Creating initial DataKeeper mirror on volume F"
	$jobInfo = New-DataKeeperJob "Volume F" "initial mirror" sios-0.$DomainFQDN 10.0.0.5 F sios-1.$DomainFQDN 10.0.0.6 F Async
	TraceInfo "Job Info: $jobInfo"
	$mirrorStatus = New-DataKeeperMirror 10.0.0.5 F 10.0.0.6 F Async
	TraceInfo "Mirror Status: $mirrorStatus"
	
	& "$env:extmirrbase\emcmd.exe" . REGISTERCLUSTERVOLUME F
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
    TraceInfo "$env:COMPUTERNAME is not in a domain. Joining domain $DomainFQDN"
    # join the domain
    while($true)
    {
        try
        {
            Add-Computer -DomainName $DomainFQDN -Credential $domainUserCred -ErrorAction Stop
            TraceInfo "Joined to the domain $DomainFQDN"
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

TraceInfo "Starting to initialize data disk(s)"
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru |	New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
TraceInfo "Finished formatting data disk(s)"

TraceInfo "Downloading license file."
$licFile = ""
# check to see if the user pasted in a different license file, and preserve it's name / use it
# this also works if the user navigated to the link first and pasted in the full file path url 
if($LicenseKeyFtpURL.EndsWith(".lic")) {
	$licFile = $LicenseKeyFtpURL.Substring($LicenseKeyFtpURL.LastIndexOf("/"))
	Invoke-WebRequest $LicenseKeyFtpURL -OutFile ($licFolder+$licFile)
} else { # otherwise use the standard file name
	$licFile = "/DK-W-Cluster.lic"
	Invoke-WebRequest ($LicenseKeyFtpURL+$licFile) -OutFile ($licFolder+$licFile)
}

TraceInfo "Enabling WSFC Feature"
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Add-WindowsFeature Failover-Clustering,RSAT-Clustering-PowerShell,RSAT-Clustering-CmdInterface

if($(Test-Path ($licFolder+$licFile))) {
	TraceInfo "License file downloaded successfully."
	Restart-Service extmirrsvc
	
	Start-Sleep 5
	if($(Get-Service extmirrsvc).Status -ne "Running") {
			TraceInfo "DataKeeper Service (ExtMirrSvc) failed to start! License may not be valid. Exiting."
			exit 1
	}
	
	if($NodeIndex -eq 0) {
		while($(get-service -ComputerName sios-1 extmirrsvc).Status -ne "Running") {
			Start-Sleep 10
		}
		
		Add-InitialMirror
		
		# verify mirror exists and retry once if not, incase timing issues prevented it from creating
		if($(get-datakeepervolumeinfo . F) -eq $NULL) {
			TraceInfo "Mirror failed to create, trying again..."
			Add-InitialMirror
		} 
	}
	
	# check if the job + mirror created successfully or not
	if($(get-datakeepervolumeinfo . F) -ne $NULL) {
		TraceInfo "Mirror creation SUCCESS."
	} else {
		TraceInfo "Mirror Creation FAILED."
	}
} else {
	TraceInfo "Download FAILED, license not obtained."
}

TraceInfo "Restart after 30 seconds"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"
