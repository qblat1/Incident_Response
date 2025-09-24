Write-Output "This PowerShell script will search for all .jpg files for all users on the C drive"
Write-Output ====================================================================================
Get-Date
Write-Output ====================================================================================
Get-TimeZone
Write-Output ====================================================================================
Get-ChildItem C:\Users\*.jpg -Force -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object Mode,FullName,Length,LastAccessTime | Format-List | Out-Host -Paging
Write-Output ====================================================================================
Get-Date
Write-Output ====================================================================================
Get-TimeZone
Write-Output ====================================================================================