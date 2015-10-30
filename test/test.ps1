param
(
    [Parameter(Mandatory=$true)]
    [String] $Username,

    [Parameter(Mandatory=$true)]
    [String] $Base64Password,
		
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

	
TraceInfo "Restarting this node after 30 seconds"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"
