Clear-Host
Write-Output "This PowerShell script will collect volatile data" | Out-File Volatile_data.txt
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Get-Date | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Get-TimeZone | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "Local User information" | Out-File Volatile_data.txt -Append
Get-LocalUser | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-ChildItem env: was used to get system information" | Out-File Volatile_data.txt -Append
Get-ChildItem env: | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-computerinfo was used to get the following computer information" | Out-File Volatile_data.txt -Append
Get-ComputerInfo | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-NetIPAddress was used to get network information" | Out-File Volatile_data.txt -Append
Get-NetIPAddress | Format-Table | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-NetIPInterface was used to get network information" | Out-File Volatile_data.txt -Append
Get-NetIPInterface | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-NetIPConfiguration was used to get network information" | Out-File Volatile_data.txt -Append
Get-NetIPConfiguration -all | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-NetFirewallProfile was used to get firewall information" | Out-File Volatile_data.txt -Append
Get-NetFirewallProfile | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-Service was used to list running processes and status of defender and event logging" | Out-File Volatile_data.txt -Append
Get-Service | Where-Object status -EQ running | Format-Table -AutoSize | Out-File Volatile_data.txt -Append
Get-Service -DisplayName *Firewall* | Out-File Volatile_data.txt -Append
Get-Service -DisplayName "Windows Event Log" | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-Service was used to locate stopped processes" | Out-File Volatile_data.txt -Append
Get-Service | Where-Object status -EQ stopped | Format-Table -AutoSize | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-Process was used to get running process information" | Out-File Volatile_data.txt -Append
Get-Process | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Write-Output "The command Get-NetTCPConnection was used to get TCP connections sorted by state and owning process" | Out-File Volatile_data.txt -Append
Get-NetTCPConnection | sort State | Out-File Volatile_data.txt -Append
Get-NetTCPConnection -State Established | sort OwningProcess | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Get-Date | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append
Get-TimeZone | Out-File Volatile_data.txt -Append
Write-Output ==================================================================================== | Out-File Volatile_data.txt -Append