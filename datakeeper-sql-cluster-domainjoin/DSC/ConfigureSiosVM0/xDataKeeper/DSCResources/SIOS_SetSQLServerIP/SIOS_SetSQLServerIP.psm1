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
		InternalLoadBalancerIP = [System.String]
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
	$IPResourceName = "SQL IP Address 1 (siossqlserver)"
	Import-Module FailoverClusters
	Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address"="$InternalLoadBalancerIP";"ProbePort"="59999";SubnetMask="255.255.255.255";"Network"="$ClusterNetworkName";"OverrideAddressMatch"=1;"EnableDhcp"=0}
	Stop-ClusterResource $IPResourceName
	Start-ClusterResource $IPResourceName
	Start-ClusterGroup "Cluster Group"
	Start-ClusterGroup "SQL Server (MSSQLSERVER)"
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

