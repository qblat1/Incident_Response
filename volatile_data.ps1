Clear-Host
Write-Output "This PowerShell script will collect volatile data"
Write-Output ==================================================================================== 
Get-Date 
Write-Output ==================================================================================== 
Get-TimeZone 
Write-Output ==================================================================================== 
Write-Output "The command Get-ChildItem env: was used to get system information"
Get-ChildItem env:
Write-Output ==================================================================================== 
Write-Output "The command Get-computerinfo was used to get the following computer information"
Get-ComputerInfo 
Write-Output ====================================================================================
Write-Output "The command Get-NetIPAddress was used to get network information"
Get-NetIPAddress | Format-Table
Write-Output ====================================================================================
Write-Output "The command Get-NetIPInterface was used to get network information"
Get-NetIPInterface
Write-Output ====================================================================================
Write-Output "The command Get-NetIPConfiguration was used to get network information"
Get-NetIPConfiguration -all
Write-Output ====================================================================================
Write-Output "The command Get-NetFirewallProfile was used to get firewall information"
Get-NetFirewallProfile 
Write-Output ====================================================================================
Write-Output "The command Get-Service was used to list running processes and status of defender and event logging"
Get-Service | Where-Object status -EQ running | Format-Table -AutoSize
Get-Service -DisplayName *Firewall*
Get-Service -DisplayName "Windows Event Log"
Write-Output ====================================================================================
Write-Output "The command Get-Service was used to locate stopped processes"
Get-Service | Where-Object status -EQ stopped | Format-Table -AutoSize
Write-Output ====================================================================================
Write-Output "The command Get-Process was used to get running process information"
Get-Process
Write-Output ====================================================================================
Write-Output "The command Get-NetTCPConnection was used to get TCP connections sorted by state and owning process"
Get-NetTCPConnection | sort State
Get-NetTCPConnection -State Established | sort OwningProcess
Write-Output ====================================================================================
Get-Date 
Write-Output ==================================================================================== 
Get-TimeZone 
Write-Output ==================================================================================== 