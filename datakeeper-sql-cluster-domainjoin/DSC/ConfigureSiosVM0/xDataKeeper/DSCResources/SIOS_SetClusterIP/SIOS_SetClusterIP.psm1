function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InternalLoadBalancerIP
    )
	
    $returnValue = @{
		ClusterIP = [System.String]
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
        $InternalLoadBalancerIP
    )

	$ClusterNetworkName = "Cluster Network 1" 
	$IPResourceName = "Cluster IP Address" 
	Import-Module FailoverClusters
	Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address"="$InternalLoadBalancerIP";"ProbePort"="59999";SubnetMask="255.255.255.255";"Network"="$ClusterNetworkName";"OverrideAddressMatch"=1;"EnableDhcp"=0}
	Stop-ClusterResource $IPResourceName
	Start-ClusterResource $IPResourceName
	Start-ClusterResource "Cluster Name"
	
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InternalLoadBalancerIP
    )
	
	Import-Module FailoverClusters
    $result = $(Get-ClusterResource "Cluster Name").Status -eq "Online"
	
	$result
}


Export-ModuleMember -Function *-TargetResource

