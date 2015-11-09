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

Set-StrictMode -Version 3
$datetimestr = (Get-Date).ToString("yyyyMMddHHmmssfff")        
$logFile = "$env:windir\Temp\PrepareDataKeeperNode_log-$datetimestr.txt"
$licFolder = "$env:windir\SysWOW64\LKLicense"

function TraceInfo($log)
{
    "$(Get-Date -format 'MM/dd/yyyy HH:mm:ss') $log" | Add-Content -Confirm:$false $logFile 
}

function Join-Domain {
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
}

function Initialize-DataDisks {
	TraceInfo "Starting to initialize data disk(s)"
	Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru |	New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
	TraceInfo "Finished formatting data disk(s)"
}

function Install-License {
	TraceInfo "Downloading license file."
	$licFile = ""
	$license = ""
	# check to see if the user pasted in a different license file, and preserve it's name / use it
	# this also works if the user navigated to the link first and pasted in the full file path url 
	if($LicenseKeyFtpURL.EndsWith(".lic")) {
		$licFile = $LicenseKeyFtpURL.Substring($LicenseKeyFtpURL.LastIndexOf("/"))
		$license = $LicenseKeyFtpURL
	} else { # otherwise use the standard file name
		$licFile = "/DK-W-Cluster.lic"
		$license = $LicenseKeyFtpURL+$licFile
	}
	
	$attempt = 0
	while(-Not $(Test-Path ($licFolder+$licFile)) -AND $attempt -lt 10) {
		Invoke-WebRequest $license -OutFile ($licFolder+$licFile)
		$attempt++
		Start-Sleep 10
	}
	
	if(-Not $(Test-Path ($licFolder+$licFile)) -AND $attempt -eq 10) {
		TraceInfo "Failed to download license ($license). Exiting."
		exit 1
	}

	TraceInfo "License file downloaded successfully."

	Start-Service extmirrsvc
	Start-Sleep 10	
}

function Add-InitialMirror {
	
	TraceInfo "Verifying extmirrsvc is running on sios-1"
	$attempt = 0
	$svc = $(get-service -ComputerName sios-1 extmirrsvc)
	while($svc.Status -ne "Running" -AND $attempt -lt 10) {
		$svc = $(get-service -ComputerName sios-1 extmirrsvc)
		TraceInfo "ExtMirrSvc not running. Checking again in 30 seconds."
		TraceInfo "$svc"
		$attempt++
		Start-Sleep 30
	}
	if($svc.Status -ne "Running" -AND $attempt -eq 10) {
		TraceInfo "Could not verify extmirrsvc on other node. Verify license was successfully installed. Exiting."
		exit 1
	}
		
	TraceInfo "Verifying extmirrsvc is running on local node"
	$attempt = 0
	$svc = $(Get-Service extmirrsvc)
	while($svc.Status -ne "Running" -AND $attempt -lt 10) {
		Start-Service extmirrsvc
		$svc = $(Get-Service extmirrsvc)
		$attempt++
		Start-Sleep 30
	}
	if($svc.Status -ne "Running" -AND $attempt -eq 10) {
		TraceInfo "DataKeeper Service (ExtMirrSvc) failed to start on local node! License may not be valid. Exiting."
		exit 1
	}
	
	TraceInfo "Creating initial DataKeeper job on volume F"
	$job = $Null
	$attempt = 0
	while($job -eq $NULL -AND $attempt -lt 10) {	
		$job = New-DataKeeperJob "Volume F" "initial mirror" sios-0.$DomainFQDN 10.0.0.5 F sios-1.$DomainFQDN 10.0.0.6 F Async	
		$attempt++
		Start-Sleep 30
		TraceInfo "..."
	}
	if($job -eq $NULL -AND $attempt -eq 10) {
		TraceInfo "Job creation failed. Trying with emcmd..."
		$job = (& "$env:extmirrbase\emcmd.exe" . CREATEJOB "Volume F" "Initial mirror" sios-0.$DomainFQDN F 10.0.0.5 sios-1.$DomainFQDN F 10.0.0.6 A)		
	}
	if($job.Contains("Status")) {
		TraceInfo "Job creation failed. Exiting."
		exit 1
	}
	
	TraceInfo "Job Info: $job"
	
	TraceInfo "Creating initial mirror on volume F"
	$mirrorStatus = $NULL
	$attempt = 0
	while($mirrorStatus -eq $NULL -AND $attempt -lt 10) {
		$mirrorStatus = New-DataKeeperMirror 10.0.0.5 F 10.0.0.6 F Async
		$attempt++
		Start-Sleep 30
		TraceInfo "..."
	}
	if($mirrorStatus -eq $NULL -AND $attempt -eq 10) {
		TraceInfo "Mirror creation failed. Trying with emcmd..."
		$mirrorStatus = (& "$env:extmirrbase\emcmd.exe" 10.0.0.5 CREATEMIRROR F 10.0.0.6 A)
	}
	if(-Not $mirrorStatus.Contains("Status = 0")) {
		TraceInfo "Mirror creation failed. Exiting."
		exit 1
	}
	
	TraceInfo "Mirror Status: $mirrorStatus"	
}

function Enable-WSFC {
	TraceInfo "Enabling WSFC Feature"
	Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
	Add-WindowsFeature Failover-Clustering,RSAT-Clustering-PowerShell,RSAT-Clustering-CmdInterface
}

#############################################################################
# Entry Point 
#############################################################################
Join-Domain

Initialize-DataDisks

Install-License

if($NodeIndex -eq 0) {
	# create the job + mirror with this node as source
	Add-InitialMirror	
}

Enable-WSFC

TraceInfo "Restart after 30 seconds"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"
