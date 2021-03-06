function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AdminUser,

        [parameter(Mandatory = $true)]
        [System.String]
        $Password
    )

    $returnValue = @{
		AdminUser = [System.String]
		Password = [System.String]
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
        $AdminUser,

        [parameter(Mandatory = $true)]
        [System.String]
        $Password
    )
	
	mkdir C:\TempDB
	
	$logfile = "C:\Windows\Temp\datakeeperSQLInstall.txt"
	"Adding this node to the clustered sql instance" > $logfile
	
	try {
		while($(Get-ClusterResource "SQL Server").State -ne "Online") {
			Start-Sleep 30
			"Cluster resource 'SQL Server' not found">>$logfile
		}

		if($(Get-Service winmgmt).Status -ne "Running") {
			Restart-Service winmgmt
		}
	
		$results = ""
		while(-Not $results.Contains("Success")) {	
			$results = C:\SQL2014\setup /ACTION="AddNode" /SkipRules=Cluster_VerifyForErrors Cluster_IsWMIServiceOperational /ENU="True" /Q /UpdateEnabled="False" /ERRORREPORTING="False" /USEMICROSOFTUPDATE="False" /UpdateSource="MU" /HELP="False" /INDICATEPROGRESS="False" /X86="False" /INSTANCENAME="MSSQLSERVER" /SQMREPORTING="False" /FAILOVERCLUSTERGROUP="SQL Server (MSSQLSERVER)" /CONFIRMIPDEPENDENCYCHANGE="False" /FAILOVERCLUSTERIPADDRESSES="IPv4;10.0.0.200;Cluster Network 1;255.255.255.0" /FAILOVERCLUSTERNETWORKNAME="siossqlserver" /AGTSVCACCOUNT=$AdminUser /SQLSVCACCOUNT=$AdminUser /FTSVCACCOUNT="NT Service\MSSQLFDLauncher" /SQLSVCPASSWORD=$Password /AGTSVCPASSWORD=$Password /IAcceptSQLServerLicenseTerms 2>>"C:\Windows\Temp\datakeeperSQLInstalFAILURE.txt"
			$results>>$logfile
		}
	} catch [Exception] {
		echo $_.Exception|format-list -force > "C:\Windows\Temp\datakeeperSQLInstalFAILURE.txt"
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
        $AdminUser,

        [parameter(Mandatory = $true)]
        [System.String]
        $Password
    )

    Test-Path "C:\Windows\Temp\datakeeperSQLInstall.txt"
}


Export-ModuleMember -Function *-TargetResource

