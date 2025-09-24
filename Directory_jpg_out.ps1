Clear-Host
Write-Output "This PowerShell script will search for all .jpg files for all users on the C drive" | Out-File jpg_list.txt
Write-Output ==================================================================================== | Out-File jpg_list.txt -Append
Get-Date | Out-File jpg_list.txt -Append
Write-Output ==================================================================================== | Out-File jpg_list.txt -Append
Get-TimeZone | Out-File jpg_list.txt -Append
Write-Output ==================================================================================== | Out-File jpg_list.txt -Append
Get-ChildItem C:\Users\*.jpg -Force -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object Mode,FullName,Length,LastAccessTime | Format-List | Out-File jpg_list.txt -Append
Write-Output ==================================================================================== | Out-File jpg_list.txt -Append
Get-Date | Out-File jpg_list.txt -Append
Write-Output ==================================================================================== | Out-File jpg_list.txt -Append
Get-TimeZone | Out-File jpg_list.txt -Append
Write-Output ==================================================================================== | Out-File jpg_list.txt -Append