param
(
    [Parameter(Mandatory=$true)]
    [String] $Username,

    [Parameter(Mandatory=$true)]
    [String] $Base64Password,
		
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

if($(Test-Path ($licFolder+$licFile))) {
	TraceInfo "License file downloaded successfully."
	Restart-Service extmirrsvc
	Add-InitialMirror
} else {
	TraceInfo "Download FAILED, license not obtained."
}

TraceInfo "Start to set initialize data disk(s)"
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru |	New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
TraceInfo "Finished formatting data disk(s)"

TraceInfo "Enabling and Configuring WSFC"
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Import-Module FailoverClusters
# TODO: add node to cluster 
TraceInfo "Finished Configuring WSFC"

if(-Not $(Get-Service extmirrsvc).Status -eq "Running") {
	TraceInfo "ExtMirr Service failed to start. Mirror not created."
	return 1
}

if($NodeIndex -eq 0) {	
	TraceInfo "NodeIndex passed SUCCESSFULLY"
} else {
	TraceInfo "NodeIndex FAILURE"
}
	
TraceInfo "Restarting this node after 30 seconds"
#Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"
