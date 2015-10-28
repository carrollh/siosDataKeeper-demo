
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

TraceInfo "Verifying ExtMirr Service is Running"
while(-Not $(Test-Path $env:windir\SysWOW64\LKLicense\extmirrsvc.lic)) {
		Start-Sleep -Seconds 5
}
Restart-Service extmirrsvc
Start-Sleep -Seconds 10
if($(Get-Service extmirrsvc).Status -eq "Running") {
		TraceInfo "Creating mirror on volume F"
		New-DataKeeperJob "Volume F" "Initial Mirror" "sios-0" "10.0.0.5" "F" "sios-1" "10.0.0.6" "F" "Async"
		New-DataKeeperMirror "10.0.0.5" "F" "10.0.0.6" "F" "Async"
		TraceInfo "Finished creating mirror"
} else {
		TraceInfo "ExtMirr Service failed to start. Mirror not created."
}