Clear-Host
$PSDefaultParameterValues['out-file:width']=2000
$locuser = $null
$locuser = {
Write-Output "This powershell script will collect the localuser data from the system"  
Write-Output ===================================================================================  
Get-Date  
Write-Output ===================================================================================  
Get-TimeZone  
Write-Output ===================================================================================  
Get-LocalUser | Format-Table -AutoSize
Write-Output ===================================================================================  
Get-Date  
Write-Output ===================================================================================  
Get-TimeZone  
Write-Output =================================================================================== 
}
& $locuser | Out-File ./users.txt -NoClobber 