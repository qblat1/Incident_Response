Clear-Host
$PSDefaultParameterValues['out-file:width']=2000
$EnvVar = $null
$ENVVar = {
Write-Output "This powershell script will collect the environmental variable data from the system"  
Write-Output ===================================================================================  
Get-Date  
Write-Output ===================================================================================  
Get-TimeZone  
Write-Output ===================================================================================  
Get-ChildItem env: | Format-Table -AutoSize
Write-Output ===================================================================================  
Get-Date  
Write-Output ===================================================================================  
Get-TimeZone  
Write-Output ===================================================================================
}
& $EnvVar | Out-File ./EnvVariables.txt -NoClobber   