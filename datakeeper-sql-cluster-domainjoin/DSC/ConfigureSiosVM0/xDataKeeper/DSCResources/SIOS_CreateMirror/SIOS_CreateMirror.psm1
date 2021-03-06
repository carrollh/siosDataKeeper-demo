function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SourceIP
    )

    $returnValue = @{
    SourceIP = [System.String]
    Volume = [System.String]
    TargetIP = [System.String]
    SyncType = [System.String]
    RetryIntervalSec = [System.UInt32]
    RetryCount = [System.UInt32]
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SourceIP,

        [System.String]
        $Volume,

        [System.String]
        $TargetIP,

        [System.String]
        $SyncType,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

	Write-Verbose "In Set-TargetResource"
	
	$logfile = "$env:windir\Temp\datakeepermirror.log"
	
	"Creating Mirror" | Out-File -FilePath $logfile -Encoding "UTF8" -Force
	
	for ($count = 0; $count -lt $RetryCount; $count++)
    {
		$mirror = & "$env:extmirrbase\emcmd" $SourceIP CREATEMIRROR $Volume $TargetIP $SyncType
		
		if($mirror -eq $NULL) {
			Add-Content $logfile "Mirror creation failed with code $LastExitCode"
			Add-Content $logfile "Retrying in $RetryIntervalSec seconds ..."
			Start-Sleep -Seconds $RetryIntervalSec			
		} else {
			Add-Content $logfile "Mirror created successfully"
			$global:DSCMachineStatus = 1
			break
		}
	}
	
	if($mirror -eq $NULL) {
		Add-Content $logfile "Mirror NOT created after $RetryCount attmpts."
		throw "Mirror NOT created after $RetryCount attmpts."
	}
	
	Write-Verbose "Leaving Set-TargetResource"
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SourceIP,

        [System.String]
        $Volume,

        [System.String]
        $TargetIP,

        [System.String]
        $SyncType,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

	Write-Verbose "In Test-TargetResource"
	
	$results = & "$env:extmirrbase\emcmd" . GETMIRRORVOLINFO $Volume
	
	if($results.Contains($Volume+": 0")) {
		$false
	} else {
		# wait for mirroring state on target
		for ($count = 0; $count -lt $RetryCount; $count++)
		{
			$results = & "$env:extmirrbase\emcmd" $TargetIP GETMIRRORVOLINFO $Volume
			if($results.Contains($Volume+": 2 "+$SourceIP+" "+$TargetIP+" 1")) {
				break
			}
		}
		if($results.Contains($Volume+": 2 "+$SourceIP+" "+$TargetIP+" 1")) {
			$true
		} else {
			$false
		}
	}
}

Export-ModuleMember -Function *-TargetResource

