function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Volume
    )
	
    $returnValue = @{
		Volume = [System.String]
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
        $Volume
    )
	
	$logfile = "C:\Windows\Temp\datakeeperRegisterClusterVolume.log"
	
	$count = 0
	while($true)
	{
		$results = & "$env:extmirrbase\emcmd" . REGISTERCLUSTERVOLUME $Volume
		if($results.Contains("Status = 0")) {
			"Volume $Volume registered with the cluster" | Out-File -FilePath $logfile -Encoding "UTF8" -Force
			break			
		} else {
			Start-Sleep -Seconds 30
		}
	}		
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Volume
    )
	
	$result = & "$env:extmirrbase\emcmd.exe" . GETCONFIGURATION $Volume
	if($result[0] -eq 128) {
		return $True
	} else {
		return $False
	}
}


Export-ModuleMember -Function *-TargetResource

