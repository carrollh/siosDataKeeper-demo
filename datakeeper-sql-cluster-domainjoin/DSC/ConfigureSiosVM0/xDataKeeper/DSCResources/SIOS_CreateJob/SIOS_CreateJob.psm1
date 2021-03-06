function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $JobName
    )

    Write-Verbose "In Get-TargetResource"

    $returnValue = @{
    JobName = [System.String]
    JobDesc = [System.String]
    SourceName = [System.String]
    SourceIP = [System.String]
    SourceVol = [System.String]
    TargetName = [System.String]
    TargetIP = [System.String]
    TargetVol = [System.String]
    SyncType = [System.String]
    RetryIntervalSec = [System.UInt32]
    RetryCount = [System.UInt32]
    }

	Write-Verbose "Leaving Get-TargetResource"
	
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $JobName,

        [System.String]
        $JobDesc,

        [System.String]
        $SourceName,

        [System.String]
        $SourceIP,

        [System.String]
        $SourceVol,

        [System.String]
        $TargetName,

        [System.String]
        $TargetIP,

        [System.String]
        $TargetVol,

        [System.String]
        $SyncType,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

	Write-Verbose "In Set-TargetResource"
	
	$logfile = "$env:windir\Temp\datakeeperjob.log"
	
	"Creating Job from $SourceName to $TargetName" | Out-File -FilePath $logfile -Encoding "UTF8" -Force
	
	for ($count = 0; $count -lt $RetryCount; $count++)
    {
	
		$job = & "$env:extmirrbase\emcmd" . CREATEJOB $JobName $JobDesc $SourceName $SourceVol $SourceIP $TargetName $TargetVol $TargetIP $SyncType
		
		# normally createjob returns the job info on success, otherwise it gives 'Status = X'
		if($job.Contains("Status")) {
			Add-Content $logfile "Job creation failed with code $LastExitCode"
			Add-Content $logfile "Retrying in $RetryIntervalSec seconds ..."
			Start-Sleep -Seconds $RetryIntervalSec			
		} else {
			Add-Content $logfile "Job created successfully"
			break
		}
	}
	
	if($job -eq $NULL) {
		Add-Content $logfile "Job NOT created after $RetryCount attmpts."
		throw "Job NOT created after $RetryCount attmpts."
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
        $JobName,

        [System.String]
        $JobDesc,

        [System.String]
        $SourceName,

        [System.String]
        $SourceIP,

        [System.String]
        $SourceVol,

        [System.String]
        $TargetName,

        [System.String]
        $TargetIP,

        [System.String]
        $TargetVol,

        [System.String]
        $SyncType,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

    Write-Verbose "In Test-TargetResource"
	
	$results = & "$env:extmirrbase\emcmd" . GETJOBINFOFORVOL $SourceVol
	
	if($results -eq $NULL) {
		$false
	} else {
		$true
	}
	
	Write-Verbose "Leaving Test-TargetResource"
}

Export-ModuleMember -Function *-TargetResource

