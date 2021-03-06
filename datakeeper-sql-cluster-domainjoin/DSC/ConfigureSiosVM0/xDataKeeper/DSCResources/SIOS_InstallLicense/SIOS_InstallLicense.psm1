function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LicenseKeyFtpURL
    )

	Write-Verbose "In Get-TargetResource"
	
    $returnValue = @{
			LicenseKeyFtpURL = [System.String]
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
        $LicenseKeyFtpURL,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

	Write-Verbose "In Set-TargetResource"
	
	$licFolder = "$env:windir\SysWOW64\LKLicense"
	$licFile = ""
	$license = ""
	$logfile = "$env:windir\Temp\datakeeperinstall.log"
	
	"Downloading DKCE license from '$($LicenseKeyFtpURL)'" | Out-File -FilePath $logfile -Encoding "UTF8" -Force
	
	# check to see if the user pasted in a different license file, and preserve it's name / use it
	# this also works if the user navigated to the link first and pasted in the full file path url 
	if($LicenseKeyFtpURL.EndsWith(".lic")) {
		$licFile = $LicenseKeyFtpURL.Substring($LicenseKeyFtpURL.LastIndexOf("/"))
		$license = $LicenseKeyFtpURL
	} else { # otherwise use the standard file name
		$licFile = "/DK-W-Cluster.lic"
		$license = $LicenseKeyFtpURL+$licFile
	}
	
	$licenseDLed = $false;
	for ($count = 0; $count -lt $RetryCount; $count++)
    {
		Invoke-WebRequest $license -OutFile ($licFolder+$licFile)
		
		if($(Test-Path ($licFolder+$licFile))) {
			Add-Content $logfile "License file downloaded successfully"
			$licenseDLed = $true
			break
		} else {
			Add-Content $logfile "License not obtained"
			Add-Content $logfile "Retrying in $RetryIntervalSec seconds ..."
			Start-Sleep -Seconds $RetryIntervalSec
		}
	}
		
	if(-Not $licenseDLed) {
		Add-Content $logfile "License from '$($LicenseKeyFtpURL)' NOT found after $RetryCount attmpts."
		throw "License from '$($LicenseKeyFtpURL)' NOT found after $RetryCount attmpts."
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
        $LicenseKeyFtpURL,

        [System.UInt32]
        $RetryIntervalSec = 20,

        [System.UInt32]
        $RetryCount = 30
    )

	Write-Verbose "In Test-TargetResource"
	
    $licFolder = "$env:windir\SysWOW64\LKLicense"
	$licFile = ""
	$license = ""
	$logfile = "$env:windir\Temp\datakeeperinstall.log"

	# check to see if the user pasted in a different license file, and preserve it's name / use it
	# this also works if the user navigated to the link first and pasted in the full file path url 
	if($LicenseKeyFtpURL.EndsWith(".lic")) {
		$licFile = $LicenseKeyFtpURL.Substring($LicenseKeyFtpURL.LastIndexOf("/"))
		$license = $LicenseKeyFtpURL
	} else { # otherwise use the standard file name
		$licFile = "/DK-W-Cluster.lic"
		$license = $LicenseKeyFtpURL+$licFile
	}

	Add-Content $logfile "Checking for License file ..."
	$fileExists = $(Test-Path ($licFolder+$licFile))
	
	if($fileExists) {
		Add-Content $logfile "License file found."
		$true
	} else {
		Add-Content $logfile "License NOT found!"
		$false
	}
	
	Write-Verbose "Leaving Test-TargetResource"
}

Export-ModuleMember -Function *-TargetResource

