Clear-Host
$PSDefaultParameterValues['out-file:width']=2000
$services = $null
$services = {
Write-Output "This powershell script will collect the services data from the system"
Write-Output =================================================================================== 
Get-Date 
Write-Output =================================================================================== 
Get-TimeZone 
Write-Output =================================================================================== 
Get-Service | Format-Table -AutoSize
Write-Output =================================================================================== 
Get-Date 
Write-Output =================================================================================== 
Get-TimeZone 
Write-Output =================================================================================== 
}
& $services | Out-File ./services.txt -NoClobber