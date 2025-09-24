Clear-Host
$PSDefaultParameterValues['out-file:width']=2000
$compinfo = $null
$compinfo = {
Write-Output "This powershell script will collect the computerinfo data from the system" 
Write-Output ===================================================================================
Get-Date
Write-Output ===================================================================================
Get-TimeZone
Write-Output ===================================================================================
Get-ComputerInfo
Write-Output ===================================================================================
Get-Date
Write-Output ===================================================================================
Get-TimeZone
Write-Output ===================================================================================
}
& $compinfo | Out-File ./Computerinfo.txt -NoClobber