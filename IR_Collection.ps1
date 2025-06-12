# === Integrated Incident Response Data Collection Script for Zimmerman Tools ===
# Usage: Run as Administrator for full data collection
# Collects artifacts for Eric Zimmerman's forensic tools
# Integrates features from EZ_Tools_IR_Collection.ps1 and ir_collection_withEZ.ps1
# Updated to use ComputerName_<timestamp> for output folder and enhance Event Log and MFT collection

param(
    [string]$OutputPath = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

# Start Time and Setup
$StartTime = Get-Date
$ComputerName = $env:COMPUTERNAME
$Username = $env:USERNAME
$SafeUsername = $Username -replace '\s+', '_'

# Create output directory structure
Write-Host "[+] Creating output directory structure: $OutputPath" -ForegroundColor Green
$Folders = @(
    "Registry", "EventLogs", "Prefetch", "JumpLists", "LNK", "Shimcache", "Amcache", 
    "SRUM", "USN", "MFT", "LogFiles", "BrowserData", "RecentFiles", "Shellbags", 
    "Timeline", "Memory", "VSS", "Cookies", "Defender", "PowerShell", "WindowsUpdate", 
    "Startup", "SystemInfo"
)
foreach ($Folder in $Folders) {
    New-Item -ItemType Directory -Path "$OutputPath\$Folder" -Force | Out-Null
}

# Function to safely copy files
function Copy-SafeFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    Write-Host "[+] Collecting: $Description" -ForegroundColor Cyan
    try {
        if (Test-Path $Source) {
            Copy-Item -Path $Source -Destination $Destination -Force -Recurse -ErrorAction Stop
            Write-Host "    Copied: $Source" -ForegroundColor Gray
        } else {
            Write-Host "    Not found: $Source" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        "Error copying $Description from $Source`: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
    }
}

# Function to safely execute commands and log errors
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$OutputFile,
        [string]$Description
    )
    
    Write-Host "[+] Collecting: $Description" -ForegroundColor Cyan
    try {
        $OutputFilePath = Join-Path $OutputPath $OutputFile
        $ParentDir = Split-Path $OutputFilePath -Parent
        if (-not (Test-Path $ParentDir)) {
            New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
        }
        Invoke-Expression $Command | Out-File -FilePath $OutputFilePath -Encoding UTF8 -ErrorAction Stop
        Write-Host "    Saved to: $OutputFile" -ForegroundColor Gray
    }
    catch {
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        "Error collecting $Description`: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
    }
}

Write-Host "=== Zimmerman Tools Data Collection ===" -ForegroundColor Yellow
Write-Host "Start Time: $StartTime" -ForegroundColor Yellow

# ===== REGISTRY HIVES (for Registry Explorer, RECmd) =====
Write-Host "`n[+] Collecting Registry Hives" -ForegroundColor Magenta

# System Registry Hives (using reg save for locked hives)
$RegHives = @(
    @{Key="HKLM\\SYSTEM"; Name="SYSTEM"},
    @{Key="HKLM\\SOFTWARE"; Name="SOFTWARE"},
    @{Key="HKLM\\SECURITY"; Name="SECURITY"},
    @{Key="HKLM\\SAM"; Name="SAM"},
    @{Key="HKU\\.DEFAULT"; Name="DEFAULT"}
)
$RegistryPath = "$OutputPath\Registry"
foreach ($Hive in $RegHives) {
    $dest = "$RegistryPath\$($Hive.Name).hiv"
    try {
        reg save $Hive.Key $dest /y > $null
        Write-Host "    Saved: $($Hive.Key) to $dest" -ForegroundColor Gray
    } catch {
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        "Error saving $($Hive.Key) to $dest`: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
    }
}

# System Registry Files and Transaction Logs
Copy-SafeFile "C:\Windows\System32\config\SYSTEM" "$OutputPath\Registry\SYSTEM" "SYSTEM Registry Hive"
Copy-SafeFile "C:\Windows\System32\config\SOFTWARE" "$OutputPath\Registry\SOFTWARE" "SOFTWARE Registry Hive"
Copy-SafeFile "C:\Windows\System32\config\SECURITY" "$OutputPath\Registry\SECURITY" "SECURITY Registry Hive"
Copy-SafeFile "C:\Windows\System32\config\SAM" "$OutputPath\Registry\SAM" "SAM Registry Hive"
Copy-SafeFile "C:\Windows\System32\config\DEFAULT" "$OutputPath\Registry\DEFAULT" "DEFAULT Registry Hive"
Copy-SafeFile "C:\Windows\System32\config\SYSTEM.LOG*" "$OutputPath\Registry\" "SYSTEM Transaction Logs"
Copy-SafeFile "C:\Windows\System32\config\SOFTWARE.LOG*" "$OutputPath\Registry\" "SOFTWARE Transaction Logs"
Copy-SafeFile "C:\Windows\System32\config\SECURITY.LOG*" "$OutputPath\Registry\" "SECURITY Transaction Logs"
Copy-SafeFile "C:\Windows\System32\config\SAM.LOG*" "$OutputPath\Registry\" "SAM Transaction Logs"
Copy-SafeFile "C:\Windows\System32\config\DEFAULT.LOG*" "$OutputPath\Registry\" "DEFAULT Transaction Logs"

# User Registry Hives
$Users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        Copy-SafeFile "$($User.FullName)\NTUSER.DAT" "$OutputPath\Registry\$($User.Name)_NTUSER.DAT" "$($User.Name) NTUSER.DAT"
        Copy-SafeFile "$($User.FullName)\NTUSER.DAT.LOG*" "$OutputPath\Registry\" "$($User.Name) NTUSER Transaction Logs"
        Copy-SafeFile "$($User.FullName)\AppData\Local\Microsoft\Windows\UsrClass.dat" "$OutputPath\Registry\$($User.Name)_UsrClass.dat" "$($User.Name) UsrClass.dat"
        Copy-SafeFile "$($User.FullName)\AppData\Local\Microsoft\Windows\UsrClass.dat.LOG*" "$OutputPath\Registry\" "$($User.Name) UsrClass Transaction Logs"
    }
}

# ===== EVENT LOGS (for EvtxECmd, WxTCmd) =====
Write-Host "`n[+] Collecting Event Logs" -ForegroundColor Magenta
try {
    $EventLogPath = "$OutputPath\EventLogs"
    $LogNames = wevtutil el | ForEach-Object { $_ }
    foreach ($LogName in $LogNames) {
        $SafeLogName = $LogName -replace '[\/\\]', '_'
        $OutputFile = "$EventLogPath\$SafeLogName.evtx"
        try {
            wevtutil epl $LogName $OutputFile /ow:$true > $null
            Write-Host "    Copied: $LogName to $SafeLogName.evtx" -ForegroundColor Gray
        } catch {
            Write-Host "    Error exporting $LogName`: $($_.Exception.Message)" -ForegroundColor Red
            "Error exporting event log $LogName`: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
        }
    }
    # Fallback: Copy raw event logs if wevtutil fails
    Copy-SafeFile "C:\Windows\System32\winevt\Logs\*" "$OutputPath\EventLogs\" "All Event Logs (Fallback)"
} catch {
    Write-Host "    Error enumerating event logs: $($_.Exception.Message)" -ForegroundColor Red
    "Error enumerating event logs: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
}

# ===== PREFETCH (for PECmd) =====
Write-Host "`n[+] Collecting Prefetch Files" -ForegroundColor Magenta
Copy-SafeFile "C:\Windows\Prefetch\*" "$OutputPath\Prefetch\" "Prefetch Files"

# ===== JUMP LISTS (for JLECmd) =====
Write-Host "`n[+] Collecting Jump Lists" -ForegroundColor Magenta
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*" "$OutputPath\JumpLists\$($User.Name)_AutomaticDestinations\" "Automatic Destinations - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*" "$OutputPath\JumpLists\$($User.Name)_CustomDestinations\" "Custom Destinations - $($User.Name)"
    }
}

# ===== LNK FILES (for LECmd) =====
Write-Host "`n[+] Collecting LNK Files" -ForegroundColor Magenta
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Recent\*" "$OutputPath\LNK\$($User.Name)_Recent\" "Recent LNK Files - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\Desktop\*.lnk" "$OutputPath\LNK\$($User.Name)_Desktop\" "Desktop LNK Files - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\*" "$OutputPath\LNK\$($User.Name)_StartMenu\" "Start Menu LNK Files - $($User.Name)"
    }
}

# ===== SHIMCACHE (for AppCompatCacheParser) =====
Write-Host "`n[+] Collecting Shimcache Data" -ForegroundColor Magenta
Write-Host "    Shimcache data is contained in the SYSTEM registry hive" -ForegroundColor Gray

# ===== AMCACHE (for AmcacheParser) =====
Write-Host "`n[+] Collecting Amcache" -ForegroundColor Magenta
Copy-SafeFile "C:\Windows\appcompat\Programs\Amcache.hve" "$OutputPath\Amcache\Amcache.hve" "Amcache.hve"
Copy-SafeFile "C:\Windows\appcompat\Programs\Amcache.hve.LOG*" "$OutputPath\Amcache\" "Amcache Transaction Logs"
Copy-SafeFile "C:\Windows\appcompat\Programs\RecentFileCache.bcf" "$OutputPath\Amcache\RecentFileCache.bcf" "RecentFileCache.bcf"

# ===== SRUM (for SrumECmd) =====
Write-Host "`n[+] Collecting SRUM Database" -ForegroundColor Magenta
Copy-SafeFile "C:\Windows\System32\sru\SRUDB.dat" "$OutputPath\SRUM\SRUDB.dat" "SRUM Database"
Copy-SafeFile "C:\Windows\System32\sru\SRUDB.dat.LOG*" "$OutputPath\SRUM\" "SRUM Transaction Logs"

# ===== USN JOURNAL (for MFTECmd) =====
Write-Host "`n[+] Collecting USN Journal" -ForegroundColor Magenta
try {
    $UsnOutput = fsutil usn readjournal C: csv 2>&1
    if ($LASTEXITCODE -eq 0) {
        $UsnOutput | Out-File -FilePath "$OutputPath\USN\USN_Journal_C.csv" -Encoding UTF8
        Write-Host "    Saved USN Journal to USN_Journal_C.csv" -ForegroundColor Gray
    }
}
catch {
    Write-Host "    Error extracting USN Journal: $($_.Exception.Message)" -ForegroundColor Red
    "Error extracting USN Journal: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
}

# ===== MFT (for MFTECmd) =====
Write-Host "`n[+] Collecting MFT" -ForegroundColor Magenta
try {
    # Attempt to copy MFT using raw disk access (requires admin privileges)
    $MFTPath = "$OutputPath\MFT\$ComputerName`_MFT"
    if (Test-Path "\\.\C:") {
        $fs = [System.IO.File]::Open("\\.\C:", 'Open', 'Read', 'Read')
        $buffer = New-Object byte[] 1048576 # 1MB buffer
        $outStream = [System.IO.File]::Create($MFTPath)
        $bytesRead = $fs.Read($buffer, 0, $buffer.Length)
        while ($bytesRead -gt 0) {
            $outStream.Write($buffer, 0, $bytesRead)
            $bytesRead = $fs.Read($buffer, 0, $buffer.Length)
        }
        $outStream.Close()
        $fs.Close()
        Write-Host "    Copied MFT to $ComputerName`_MFT" -ForegroundColor Gray
    } else {
        Write-Host "    Unable to access raw disk for MFT extraction" -ForegroundColor Yellow
        Write-Host "    Note: Use tools like FTK Imager or RawCopy for MFT extraction" -ForegroundColor Yellow
        "Unable to access raw disk for MFT extraction" | Out-File -FilePath "$OutputPath\errors.log" -Append
    }
}
catch {
    Write-Host "    Error extracting MFT: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    Note: Use tools like FTK Imager or RawCopy for MFT extraction" -ForegroundColor Yellow
    "Error extracting MFT: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
}

# ===== BROWSER DATA (for various tools) =====
Write-Host "`n[+] Collecting Browser Data" -ForegroundColor Magenta
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        # Chrome
        Copy-SafeFile "$($User.FullName)\AppData\Local\Google\Chrome\User Data\Default\History" "$OutputPath\BrowserData\$($User.Name)_Chrome_History" "Chrome History - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cookies" "$OutputPath\Cookies\$($User.Name)_Chrome_Cookies" "Chrome Cookies - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Local\Google\Chrome\User Data\Default\Web Data" "$OutputPath\BrowserData\$($User.Name)_Chrome_WebData" "Chrome Web Data - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Local\Google\Chrome\User Data\Default\Login Data" "$OutputPath\BrowserData\$($User.Name)_Chrome_LoginData" "Chrome Login Data - $($User.Name)"
        
        # Firefox
        $FirefoxProfiles = Get-ChildItem "$($User.FullName)\AppData\Roaming\Mozilla\Firefox\Profiles\" -Directory -ErrorAction SilentlyContinue
        foreach ($Profile in $FirefoxProfiles) {
            Copy-SafeFile "$($Profile.FullName)\places.sqlite" "$OutputPath\BrowserData\$($User.Name)_Firefox_places_$($Profile.Name).sqlite" "Firefox Places - $($User.Name) ($($Profile.Name))"
            Copy-SafeFile "$($Profile.FullName)\cookies.sqlite" "$OutputPath\Cookies\$($User.Name)_Firefox_cookies_$($Profile.Name).sqlite" "Firefox Cookies - $($User.Name) ($($Profile.Name))"
            Copy-SafeFile "$($Profile.FullName)\downloads.sqlite" "$OutputPath\BrowserData\$($User.Name)_Firefox_downloads_$($Profile.Name).sqlite" "Firefox Downloads - $($User.Name) ($($Profile.Name))"
        }
        
        # Edge
        Copy-SafeFile "$($User.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\History" "$OutputPath\BrowserData\$($User.Name)_Edge_History" "Edge History - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cookies" "$OutputPath\Cookies\$($User.Name)_Edge_Cookies" "Edge Cookies - $($User.Name)"
        
        # Internet Explorer
        Copy-SafeFile "$($User.FullName)\AppData\Local\Microsoft\Windows\WebCache\WebCacheV*.dat" "$OutputPath\BrowserData\$($User.Name)_IE_WebCache\" "IE WebCache - $($User.Name)"
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Cookies\*" "$OutputPath\Cookies\$($User.Name)_IE_Cookies\" "IE Cookies - $($User.Name)"
    }
}

# ===== SHELLBAGS (for SBECmd) =====
Write-Host "`n[+] Collecting Shellbags Data" -ForegroundColor Magenta
Write-Host "    Shellbags data is contained in the registry hives already collected" -ForegroundColor Gray

# ===== TIMELINE ARTIFACTS =====
Write-Host "`n[+] Collecting Timeline Artifacts" -ForegroundColor Magenta
try {
    $TimelineFiles = Get-ChildItem -Path "C:\" -Recurse -File -Force -ErrorAction SilentlyContinue | 
                     Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-30) -or $_.CreationTime -gt (Get-Date).AddDays(-30) } |
                     Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Length |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First 10000
    $TimelineFiles | Export-Csv -Path "$OutputPath\Timeline\FileSystem_Timeline.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "    Saved filesystem timeline to FileSystem_Timeline.csv" -ForegroundColor Gray
}
catch {
    Write-Host "    Error creating filesystem timeline: $($_.Exception.Message)" -ForegroundColor Red
    "Error creating filesystem timeline: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
}

# ===== WINDOWS SEARCH INDEX (for WinSearchDBAnalyzer) =====
Write-Host "`n[+] Collecting Windows Search Index" -ForegroundColor Magenta
Copy-SafeFile "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb" "$OutputPath\LogFiles\Windows_Search.edb" "Windows Search Index"

# ===== WINDOWS ACTIVITIES DATABASE =====
Write-Host "`n[+] Collecting Windows Activities Database" -ForegroundColor Magenta
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        Copy-SafeFile "$($User.FullName)\AppData\Local\ConnectedDevicesPlatform\L.$($User.Name)\ActivitiesCache.db" "$OutputPath\LogFiles\$($User.Name)_ActivitiesCache.db" "Activities Cache - $($User.Name)"
    }
}

# ===== RECYCLE BIN =====
Write-Host "`n[+] Collecting Recycle Bin Data" -ForegroundColor Magenta
Copy-SafeFile "C:\`$Recycle.Bin\*" "$OutputPath\RecentFiles\RecycleBin\" "Recycle Bin Contents"

# ===== WINDOWS DEFENDER LOGS =====
Write-Host "`n[+] Collecting Windows Defender Logs" -ForegroundColor Magenta
Copy-SafeFile "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service\*" "$OutputPath\Defender\WindowsDefender_Scans\" "Windows Defender Scan History"
Copy-SafeFile "C:\Windows\Temp\MpCmdRun.log" "$OutputPath\Defender\MpCmdRun.log" "Windows Defender Command Log"

# ===== POWERSHELL HISTORY =====
Write-Host "`n[+] Collecting PowerShell History" -ForegroundColor Magenta
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" "$OutputPath\PowerShell\$($User.Name)_ConsoleHost_history.txt" "PowerShell History - $($User.Name)"
    }
}

# ===== WINDOWS UPDATE LOGS =====
Write-Host "`n[+] Collecting Windows Update Logs" -ForegroundColor Magenta
Copy-SafeFile "C:\Windows\Logs\WindowsUpdate\*" "$OutputPath\WindowsUpdate\" "Windows Update Logs"

# ===== STARTUP FOLDERS =====
Write-Host "`n[+] Collecting Startup Folders" -ForegroundColor Magenta
Copy-SafeFile "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\*" "$OutputPath\Startup\Startup_AllUsers\" "Startup Folder - All Users"
foreach ($User in $Users) {
    if ($User.Name -notin @("Public", "Default", "All Users")) {
        Copy-SafeFile "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*" "$OutputPath\Startup\$($User.Name)_Startup\" "Startup Folder - $($User.Name)"
    }
}

# ===== SYSTEM INFORMATION =====
Write-Host "`n[+] Collecting System Information" -ForegroundColor Magenta
Invoke-SafeCommand "Get-ComputerInfo | Format-List" "SystemInfo\system_info.txt" "System Information"
Invoke-SafeCommand "Get-HotFix | Sort-Object InstalledOn -Descending" "SystemInfo\installed_patches.txt" "Installed Patches"
Invoke-SafeCommand "Get-Process | Sort-Object CPU -Descending | Format-Table -AutoSize" "SystemInfo\running_processes.txt" "Running Processes"
Invoke-SafeCommand "Get-Service | Sort-Object Status,Name" "SystemInfo\services.txt" "Services"
Invoke-SafeCommand "Get-LocalUser" "SystemInfo\local_users.txt" "Local Users"
Invoke-SafeCommand "Get-LocalGroup" "SystemInfo\local_groups.txt" "Local Groups"
Invoke-SafeCommand "Get-NetTCPConnection" "SystemInfo\network_connections.txt" "Network Connections"
Invoke-SafeCommand "netstat -ano" "SystemInfo\netstat.txt" "Network Connections (netstat)"

# ===== VOLUME SHADOW COPIES =====
Write-Host "`n[+] Collecting Volume Shadow Copy Information" -ForegroundColor Magenta
try {
    vssadmin list shadows | Out-File -FilePath "$OutputPath\VSS\vssadmin_shadows.txt" -Encoding UTF8
    Write-Host "    Saved: Volume Shadow Copy list (vssadmin)" -ForegroundColor Gray
} catch {
    Write-Host "    Error collecting vssadmin list: $($_.Exception.Message)" -ForegroundColor Red
    "Error collecting vssadmin list: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
}
try {
    $VSS = Get-WmiObject -Class Win32_ShadowCopy -ErrorAction SilentlyContinue
    if ($VSS) {
        $VSS | Select-Object DeviceObject, VolumeName, InstallDate, ID | 
        Out-File -FilePath "$OutputPath\VSS\shadow_copies.txt" -Encoding UTF8
        Write-Host "    Found $($VSS.Count) shadow copies (wmic)" -ForegroundColor Gray
        Write-Host "    Note: Use VSS tools to mount and extract files from shadow copies" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "    Error collecting wmic shadowcopy: $($_.Exception.Message)" -ForegroundColor Red
    "Error collecting wmic shadowcopy: $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\errors.log" -Append
}

# ===== MEMORY DUMP PREPARATION =====
Write-Host "`n[+] Memory Dump Preparation" -ForegroundColor Magenta
Write-Host "    Note: Use tools like DumpIt, WinPmem, or FTK Imager to create memory dumps" -ForegroundColor Yellow
Write-Host "    Memory dumps should be placed in the Memory folder for analysis" -ForegroundColor Yellow

# ===== COLLECTION SUMMARY =====
$EndTime = Get-Date
Write-Host "`n=== Collection Complete ===" -ForegroundColor Yellow
Write-Host "End Time: $EndTime" -ForegroundColor Yellow
Write-Host "Output Directory: $OutputPath" -ForegroundColor Green

# Count collected files
$CollectedFiles = Get-ChildItem -Path $OutputPath -Recurse -File | Measure-Object
Write-Host "Total Files Collected: $($CollectedFiles.Count)" -ForegroundColor Green

# Create detailed summary
$Summary = @"
Zimmerman Tools Data Collection Summary
=====================================
Collection Start: $StartTime
Collection End: $EndTime
Output Directory: $OutputPath
Script Version: 3.1 - Integrated Zimmerman Tools Edition
Computer: $ComputerName
User: $Username
Total Files Collected: $($CollectedFiles.Count)

Artifacts Collected:
===================
- Registry Hives (SYSTEM, SOFTWARE, SECURITY, SAM, DEFAULT, NTUSER.DAT, UsrClass.dat)
- Event Logs (All .evtx files via wevtutil)
- Prefetch Files (.pf files)
- Jump Lists (Automatic and Custom Destinations)
- LNK Files (Recent, Desktop, Start Menu)
- Amcache.hve and RecentFileCache.bcf
- SRUM Database (SRUDB.dat)
- USN Journal (CSV export)
- MFT (raw disk copy, if accessible)
- Browser Data (Chrome, Firefox, Edge, IE - History, Cookies, Web Data, Login Data)
- Windows Search Index (Windows.edb)
- Windows Activities Database (ActivitiesCache.db)
- Recycle Bin Contents
- Windows Defender Logs
- PowerShell History
- Windows Update Logs
- Startup Folders
- System Information (Computer Info, HotFixes, Processes, Services, Users, Groups, Network)
- Volume Shadow Copy Information (vssadmin, wmic)

Recommended Zimmerman Tools for Analysis:
=======================================
- Registry Explorer / RECmd (Registry analysis)
- EvtxECmd (Event log analysis)
- PECmd (Prefetch analysis)
- JLECmd (Jump list analysis)
- LECmd (LNK file analysis)
- AppCompatCacheParser (Shimcache analysis)
- AmcacheParser (Amcache analysis)
- SrumECmd (SRUM analysis)
- MFTECmd (MFT analysis)
- Timeline Explorer (Timeline analysis)
- WxTCmd (Windows 10 Timeline analysis)
- SBECmd (Shellbags analysis)
- WinSearchDBAnalyzer (Windows Search Index analysis)

Notes:
======
- MFT extraction may require tools like FTK Imager or RawCopy if raw disk access fails
- Memory dumps should be collected separately using DumpIt, WinPmem, or FTK Imager
- Volume Shadow Copies may require additional tools for mounting and extraction
- Some artifacts (e.g., NTUSER.DAT, Amcache.hve) may require VSS or running as a different account
- Transaction logs (.LOG files) are included for registry hives when available
- Run as Administrator for complete access to system files

Collection completed at: $EndTime
"@
$Summary | Out-File -FilePath "$OutputPath\ZIMMERMAN_TOOLS_COLLECTION_SUMMARY.txt" -Encoding UTF8
Write-Host "`nDetailed collection summary saved to: ZIMMERMAN_TOOLS_COLLECTION_SUMMARY.txt" -ForegroundColor Green
Write-Host "`nReady for analysis with Zimmerman Tools!" -ForegroundColor Green