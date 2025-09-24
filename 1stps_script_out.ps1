Clear-Host
$PSDefaultParameterValues['out-file:width'] = 2000
Write-Host This is my first powershell script | Out-File .\1stps_out.txt
Write-Output ========================================== | Out-File .\1stps_out.txt -Append
Get-Date | Out-File .\1stps_out.txt -Append
Write-Output ========================================== | Out-File .\1stps_out.txt -Append
Get-TimeZone | Out-File .\1stps_out.txt -Append
Write-Output ========================================== | Out-File .\1stps_out.txt -Append
Write-Host Most computer problems are due to a loose nut between the computer and the chair!!! | Out-File .\1stps_out.txt -Append
Write-Output ========================================== | Out-File .\1stps_out.txt -Append
Get-Date | Out-File .\1stps_out.txt -Append
Write-Output ========================================== | Out-File .\1stps_out.txt -Append
Get-TimeZone | Out-File .\1stps_out.txt -Append
Write-Output ========================================== | Out-File .\1stps_out.txt -Append
Exit-PSHostProcess