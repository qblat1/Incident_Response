#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Linux Incident Response Artifact Collection Script
.DESCRIPTION
    Collects key forensic artifacts from Linux systems for incident response investigations.
    Runs non-interactively and outputs structured data to specified directory.
.PARAMETER OutputPath
    Directory to store collected artifacts (default: ./IR_Collection_[timestamp])
#>

param(
    [string]$OutputPath = "./IR_Collection_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

# Create output directory
$null = New-Item -ItemType Directory -Path $OutputPath -Force
Write-Host "[+] Created output directory: $OutputPath" -ForegroundColor Green

# Function to safely execute commands and capture output
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$OutputFile,
        [string]$Description
    )
    
    try {
        Write-Host "[*] Collecting: $Description" -ForegroundColor Yellow
        
        # Execute command through bash to ensure proper Linux command execution
        $bashCommand = "bash -c `"$Command`""
        $result = Invoke-Expression $bashCommand 2>&1
        
        # Handle cases where command doesn't exist or fails
        if ($LASTEXITCODE -ne 0 -and $result -match "command not found|not recognized") {
            $result = "Command not available: $Command"
        }
        
        $result | Out-File -FilePath "$OutputPath/$OutputFile" -Encoding UTF8
        Write-Host "[+] Saved: $OutputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Error collecting $Description : $_" -ForegroundColor Red
        "Error: $_" | Out-File -FilePath "$OutputPath/$OutputFile" -Encoding UTF8
    }
}

# System Information
Write-Host "`n=== SYSTEM INFORMATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "uname -a" "system_info.txt" "System information"
Invoke-SafeCommand "hostname" "hostname.txt" "Hostname"
Invoke-SafeCommand "uptime" "uptime.txt" "System uptime"
Invoke-SafeCommand "cat /etc/os-release" "os_release.txt" "OS release information"
Invoke-SafeCommand "lscpu" "cpu_info.txt" "CPU information"
Invoke-SafeCommand "free -h" "memory_info.txt" "Memory information"
Invoke-SafeCommand "df -h" "disk_usage.txt" "Disk usage"
Invoke-SafeCommand "mount" "mounted_filesystems.txt" "Mounted filesystems"

# Network Information
Write-Host "`n=== NETWORK INFORMATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "ip addr show" "network_interfaces.txt" "Network interfaces"
Invoke-SafeCommand "ip route show" "routing_table.txt" "Routing table"
Invoke-SafeCommand "netstat -tuln" "listening_ports.txt" "Listening ports"
Invoke-SafeCommand "netstat -tupln" "network_connections.txt" "Network connections"
Invoke-SafeCommand "ss -tuln" "socket_stats.txt" "Socket statistics"
Invoke-SafeCommand "arp -a" "arp_table.txt" "ARP table"

# Process Information
Write-Host "`n=== PROCESS INFORMATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "ps auxf" "process_tree.txt" "Process tree"
Invoke-SafeCommand "ps -eo pid,ppid,user,comm,args --sort=-pcpu" "processes_by_cpu.txt" "Processes by CPU usage"
Invoke-SafeCommand "ps -eo pid,ppid,user,comm,args --sort=-pmem" "processes_by_memory.txt" "Processes by memory usage"
Invoke-SafeCommand "pstree -p" "process_tree_pstree.txt" "Process tree (pstree)"

# User and Authentication Information
Write-Host "`n=== USER AND AUTHENTICATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "whoami" "current_user.txt" "Current user"
Invoke-SafeCommand "id" "user_id.txt" "User ID information"
Invoke-SafeCommand "w" "logged_in_users.txt" "Currently logged in users"
Invoke-SafeCommand "last -n 50" "last_logins.txt" "Last 50 login records"
Invoke-SafeCommand "lastb -n 20 2>/dev/null || echo 'lastb command not available'" "failed_logins.txt" "Last 20 failed login attempts"
Invoke-SafeCommand "cat /etc/passwd" "passwd_file.txt" "User accounts"
Invoke-SafeCommand "cat /etc/group" "group_file.txt" "Group information"

# File System and File Information
Write-Host "`n=== FILE SYSTEM INFORMATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "lsof +L1" "deleted_files.txt" "Deleted files still open"
Invoke-SafeCommand "find /tmp -type f -exec ls -la {} \;" "tmp_files.txt" "Files in /tmp"
Invoke-SafeCommand "find /var/tmp -type f -exec ls -la {} \;" "var_tmp_files.txt" "Files in /var/tmp"
Invoke-SafeCommand "find /dev/shm -type f -exec ls -la {} \;" "shm_files.txt" "Files in /dev/shm"
Invoke-SafeCommand "ls -la /home" "home_directories.txt" "Home directories"
Invoke-SafeCommand "find / -type f -perm -4000 2>/dev/null" "suid_files.txt" "SUID files"
Invoke-SafeCommand "find / -type f -perm -2000 2>/dev/null" "sgid_files.txt" "SGID files"

# Services and Startup
Write-Host "`n=== SERVICES AND STARTUP ===" -ForegroundColor Cyan
Invoke-SafeCommand "systemctl list-units --type=service" "systemd_services.txt" "Systemd services"
Invoke-SafeCommand "systemctl list-unit-files --type=service" "systemd_service_files.txt" "Systemd service files"
Invoke-SafeCommand "which chkconfig >/dev/null 2>&1 && chkconfig --list || echo 'chkconfig not available'" "chkconfig_services.txt" "Chkconfig services"
Invoke-SafeCommand "ls -la /etc/init.d/" "init_scripts.txt" "Init scripts"
Invoke-SafeCommand "crontab -l 2>/dev/null || echo 'No crontab'" "user_crontab.txt" "User crontab"
Invoke-SafeCommand "cat /etc/crontab 2>/dev/null || echo 'No system crontab'" "system_crontab.txt" "System crontab"
Invoke-SafeCommand "ls -la /etc/cron.*/" "cron_directories.txt" "Cron directories"

# Loaded Modules and Kernel Information
Write-Host "`n=== KERNEL AND MODULES ===" -ForegroundColor Cyan
Invoke-SafeCommand "lsmod" "loaded_modules.txt" "Loaded kernel modules"
Invoke-SafeCommand "cat /proc/version" "kernel_version.txt" "Kernel version"
Invoke-SafeCommand "cat /proc/cmdline" "kernel_cmdline.txt" "Kernel command line"
Invoke-SafeCommand "dmesg | tail -100" "dmesg_recent.txt" "Recent kernel messages"

# Environment and Configuration
Write-Host "`n=== ENVIRONMENT AND CONFIGURATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "env" "environment_variables.txt" "Environment variables"
Invoke-SafeCommand "cat /etc/hosts" "hosts_file.txt" "Hosts file"
Invoke-SafeCommand "cat /etc/resolv.conf" "dns_config.txt" "DNS configuration"
Invoke-SafeCommand "iptables -L -n -v 2>/dev/null || echo 'iptables not accessible'" "iptables_rules.txt" "Iptables rules"

# Log File Locations (just list them, don't copy content due to size)
Write-Host "`n=== LOG FILE INFORMATION ===" -ForegroundColor Cyan
Invoke-SafeCommand "ls -la /var/log/" "log_files.txt" "Log files in /var/log"
Invoke-SafeCommand "find /var/log -name '*.log' -exec ls -la {} \;" "detailed_log_files.txt" "Detailed log file listing"

# Hash Information for Key System Files
Write-Host "`n=== SYSTEM FILE HASHES ===" -ForegroundColor Cyan
$systemFiles = @(
    "/bin/bash",
    "/bin/sh",
    "/usr/bin/ssh",
    "/usr/sbin/sshd",
    "/bin/ps",
    "/bin/netstat",
    "/usr/bin/find",
    "/bin/ls"
)

$hashOutput = @()
foreach ($file in $systemFiles) {
    try {
        $bashCommand = "bash -c `"sha256sum $file 2>/dev/null`""
        $hash = Invoke-Expression $bashCommand 2>$null
        if ($hash -and $LASTEXITCODE -eq 0) {
            $hashOutput += $hash
        } else {
            $hashOutput += "File not found or inaccessible: $file"
        }
    }
    catch {
        $hashOutput += "Error hashing $file : $_"
    }
}
$hashOutput | Out-File -FilePath "$OutputPath/system_file_hashes.txt" -Encoding UTF8

# Recently Modified Files
Write-Host "`n=== RECENT FILE MODIFICATIONS ===" -ForegroundColor Cyan
Invoke-SafeCommand "find /etc -type f -mtime -7 -exec ls -la {} \;" "recent_etc_changes.txt" "Recent changes in /etc (last 7 days)"
Invoke-SafeCommand "find /bin /usr/bin /sbin /usr/sbin -type f -mtime -30 -exec ls -la {} \;" "recent_binary_changes.txt" "Recent binary changes (last 30 days)"

# Collection Summary
Write-Host "`n=== COLLECTION SUMMARY ===" -ForegroundColor Cyan
$summary = @"
Linux IR Artifact Collection Summary
====================================
Collection Time: $(Get-Date)
Output Directory: $OutputPath
System: $(try { $bashCmd = "bash -c `"uname -a`""; Invoke-Expression $bashCmd } catch { "Unknown" })
Collector: PowerShell $($PSVersionTable.PSVersion)

Files Collected:
$(Get-ChildItem $OutputPath | ForEach-Object { "- $($_.Name) ($($_.Length) bytes)" })

Total Files: $(Get-ChildItem $OutputPath | Measure-Object | Select-Object -ExpandProperty Count)
Total Size: $((Get-ChildItem $OutputPath | Measure-Object -Property Length -Sum).Sum) bytes
"@

$summary | Out-File -FilePath "$OutputPath/collection_summary.txt" -Encoding UTF8

Write-Host "`n[+] IR artifact collection completed!" -ForegroundColor Green
Write-Host "[+] Output saved to: $OutputPath" -ForegroundColor Green
Write-Host "[+] Summary saved to: $OutputPath/collection_summary.txt" -ForegroundColor Green

# Create a compressed archive of all collected data
if (Get-Command tar -ErrorAction SilentlyContinue) {
    $archiveName = "$OutputPath.tar.gz"
    Write-Host "[*] Creating compressed archive: $archiveName" -ForegroundColor Yellow
    try {
        Invoke-Expression "tar -czf '$archiveName' -C '$(Split-Path $OutputPath)' '$(Split-Path $OutputPath -Leaf)'"
        Write-Host "[+] Compressed archive created: $archiveName" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Failed to create archive: $_" -ForegroundColor Red
    }
}
