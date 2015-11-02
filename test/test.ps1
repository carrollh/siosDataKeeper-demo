param
(
    [Parameter(Mandatory=$true)]
    [String] $Username,

    [Parameter(Mandatory=$true)]
    [String] $Base64Password,
		
		[Parameter(Mandatory=$true)]
    [String] $LicenseKeyFtpURL
)

$logFile = "$env:windir\Temp\PrepareDataKeeperNode_log-$datetimestr.txt"
$licFile = "$env:windir\SysWOW64\LKLicense\extmirrsvc.lic"

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
Invoke-WebRequest $LicenseKeyFtpURL -OutFile $licFile

if($(Test-Path $licFile)) {
	TraceInfo "License file downloaded successfully."
	Restart-Service extmirrsvc
	Add-InitialMirror
} else {
	TraceInfo "Download FAILED, license not obtained."
}

TraceInfo "Start to set initialize data disk(s)"
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru |	New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
TraceInfo "Finished formatting data disk(s)"
	
TraceInfo "Restarting this node after 30 seconds"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c shutdown /r /t 30"
