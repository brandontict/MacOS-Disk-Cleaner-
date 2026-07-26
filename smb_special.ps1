<#
.SYNOPSIS
    Wichita Computer Solutions - SMB Diagnostics Tool
    Windows Server 2025 / Windows 11 SMB Troubleshooting

.DESCRIPTION
    Read-only diagnostic script for troubleshooting SMB share disconnections.
    Designed for Windows Server 2025's new SMB security defaults.
    Professional output suitable for client-facing TeamViewer sessions.

.NOTES
    Version:        1.0
    Author:         Wichita Computer Solutions
    Created:        2026-02-03
    Purpose:        SMB disconnect troubleshooting for Server 2025

    ALL COMMANDS ARE READ-ONLY - No system changes are made.
    Some diagnostics require Administrator elevation for full results.
#>

#Requires -Version 5.1

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

$Script:Version = "1.0"
$Script:Company = "Wichita Computer Solutions"
$Script:Colors = @{
    Primary   = "Cyan"
    Success   = "Green"
    Warning   = "Yellow"
    Error     = "Red"
    Info      = "White"
    Muted     = "DarkGray"
    Accent    = "Magenta"
    Header    = "Blue"
    Table     = "DarkCyan"
    Highlight = "White"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADMIN CHECK
# ═══════════════════════════════════════════════════════════════════════════════

$Script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ═══════════════════════════════════════════════════════════════════════════════
# UI HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Show-Banner {
    Clear-Host

    Write-Host ""
    Write-Host "    ==========================================================================" -ForegroundColor $Script:Colors.Primary
    Write-Host ""
    Write-Host "       WICHITA COMPUTER SOLUTIONS" -ForegroundColor $Script:Colors.Accent
    Write-Host "       SMB Diagnostics Tool v$Script:Version" -ForegroundColor $Script:Colors.Highlight
    Write-Host ""
    Write-Host "       Windows Server 2025 / Windows 11 - Share Troubleshooting" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
    Write-Host "    ==========================================================================" -ForegroundColor $Script:Colors.Primary
    Write-Host ""

    # Admin status
    Write-Host "       Status: " -NoNewline -ForegroundColor $Script:Colors.Info
    if ($Script:IsAdmin) {
        Write-Host "ADMINISTRATOR" -NoNewline -ForegroundColor $Script:Colors.Success
        Write-Host " - Full diagnostic access" -ForegroundColor $Script:Colors.Muted
    }
    else {
        Write-Host "STANDARD USER" -NoNewline -ForegroundColor $Script:Colors.Warning
        Write-Host " - Run as Admin for complete results" -ForegroundColor $Script:Colors.Muted
    }

    Write-Host "       Mode:   " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "READ-ONLY" -NoNewline -ForegroundColor $Script:Colors.Success
    Write-Host " - No changes will be made" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
}

function Show-SectionHeader {
    param(
        [string]$Title,
        [string]$Icon = "►"
    )

    Write-Host ""
    Write-Host "    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" -ForegroundColor $Script:Colors.Primary
    Write-Host "    ┃ " -NoNewline -ForegroundColor $Script:Colors.Primary
    Write-Host "$Icon " -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host $Title.ToUpper().PadRight(70) -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host " ┃" -ForegroundColor $Script:Colors.Primary
    Write-Host "    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" -ForegroundColor $Script:Colors.Primary
}

function Show-SubHeader {
    param([string]$Title)

    Write-Host ""
    Write-Host "    ── $Title " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$("─" * (60 - $Title.Length))" -ForegroundColor $Script:Colors.Muted
}

function Write-DiagnosticItem {
    param(
        [string]$Label,
        [string]$Value,
        [ValidateSet("OK","WARN","ERROR","INFO","SKIP")]
        [string]$Status = "INFO"
    )

    $StatusIcon = switch ($Status) {
        "OK"    { "✓"; $Color = $Script:Colors.Success }
        "WARN"  { "⚠"; $Color = $Script:Colors.Warning }
        "ERROR" { "✗"; $Color = $Script:Colors.Error }
        "INFO"  { "○"; $Color = $Script:Colors.Info }
        "SKIP"  { "–"; $Color = $Script:Colors.Muted }
    }

    Write-Host "    $StatusIcon " -NoNewline -ForegroundColor $Color
    Write-Host "$($Label.PadRight(35))" -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host " : " -NoNewline -ForegroundColor $Script:Colors.Muted
    Write-Host $Value -ForegroundColor $Color
}

function Write-ConfigItem {
    param(
        [string]$Setting,
        [string]$Value,
        [string]$Expected = "",
        [string]$Note = ""
    )

    $Status = "INFO"
    if ($Expected -ne "") {
        if ($Value -eq $Expected) { $Status = "OK" }
        else { $Status = "WARN" }
    }

    $StatusIcon = switch ($Status) {
        "OK"   { "✓"; $Color = $Script:Colors.Success }
        "WARN" { "⚠"; $Color = $Script:Colors.Warning }
        "INFO" { "○"; $Color = $Script:Colors.Info }
    }

    Write-Host "    $StatusIcon " -NoNewline -ForegroundColor $Color
    Write-Host "$($Setting.PadRight(40))" -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$Value".PadRight(15) -NoNewline -ForegroundColor $Color

    if ($Note -ne "") {
        Write-Host " $Note" -ForegroundColor $Script:Colors.Muted
    }
    else {
        Write-Host ""
    }
}

function Show-ProgressDots {
    param([string]$Message, [int]$Dots = 3)

    Write-Host "    $Message" -NoNewline -ForegroundColor $Script:Colors.Muted
    for ($i = 0; $i -lt $Dots; $i++) {
        Start-Sleep -Milliseconds 200
        Write-Host "." -NoNewline -ForegroundColor $Script:Colors.Muted
    }
    Write-Host ""
}

function Show-FindingBox {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("OK","WARN","ERROR","INFO")]
        [string]$Type = "INFO"
    )

    $BorderColor = switch ($Type) {
        "OK"    { $Script:Colors.Success }
        "WARN"  { $Script:Colors.Warning }
        "ERROR" { $Script:Colors.Error }
        "INFO"  { $Script:Colors.Info }
    }

    $Icon = switch ($Type) {
        "OK"    { "✓" }
        "WARN"  { "⚠" }
        "ERROR" { "✗" }
        "INFO"  { "ℹ" }
    }

    Write-Host ""
    Write-Host "    ╭──────────────────────────────────────────────────────────────────────────╮" -ForegroundColor $BorderColor
    Write-Host "    │ $Icon " -NoNewline -ForegroundColor $BorderColor
    Write-Host $Title.PadRight(71) -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host " │" -ForegroundColor $BorderColor
    Write-Host "    ├──────────────────────────────────────────────────────────────────────────┤" -ForegroundColor $BorderColor

    # Word wrap message
    $Words = $Message -split ' '
    $Line = ""
    foreach ($Word in $Words) {
        if (($Line + " " + $Word).Trim().Length -gt 70) {
            Write-Host "    │ " -NoNewline -ForegroundColor $BorderColor
            Write-Host $Line.PadRight(72) -NoNewline -ForegroundColor $Script:Colors.Info
            Write-Host " │" -ForegroundColor $BorderColor
            $Line = $Word
        }
        else {
            $Line = ($Line + " " + $Word).Trim()
        }
    }
    if ($Line -ne "") {
        Write-Host "    │ " -NoNewline -ForegroundColor $BorderColor
        Write-Host $Line.PadRight(72) -NoNewline -ForegroundColor $Script:Colors.Info
        Write-Host " │" -ForegroundColor $BorderColor
    }

    Write-Host "    ╰──────────────────────────────────────────────────────────────────────────╯" -ForegroundColor $BorderColor
}

# ═══════════════════════════════════════════════════════════════════════════════
# DIAGNOSTIC FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Get-SystemInfo {
    Show-SectionHeader "System Information" "💻"

    Show-ProgressDots "Gathering system details"

    $OS = Get-CimInstance Win32_OperatingSystem
    $CS = Get-CimInstance Win32_ComputerSystem

    $OSName = $OS.Caption
    $OSBuild = $OS.BuildNumber
    $OSVersion = $OS.Version

    # Detect Windows Server 2025 or Windows 11 24H2
    $Is2025 = $OSName -match "2025" -or ($OSBuild -ge 26100)
    $IsServer = $OSName -match "Server"

    Write-DiagnosticItem "Computer Name" $env:COMPUTERNAME "INFO"
    Write-DiagnosticItem "Operating System" $OSName "INFO"
    Write-DiagnosticItem "Build Number" $OSBuild $(if ($Is2025) { "INFO" } else { "INFO" })
    Write-DiagnosticItem "OS Version" $OSVersion "INFO"
    Write-DiagnosticItem "Domain/Workgroup" $(if ($CS.PartOfDomain) { $CS.Domain } else { "$($CS.Workgroup) (Workgroup)" }) "INFO"
    Write-DiagnosticItem "System Role" $(if ($IsServer) { "Server" } else { "Workstation" }) "INFO"

    if ($Is2025) {
        Show-FindingBox "Windows Server 2025 / Windows 11 24H2 Detected" "This OS has NEW SMB security defaults that require signing on all connections. This is the most common cause of share disconnections when connecting from older clients." "WARN"
    }

    return @{
        IsServer = $IsServer
        Is2025 = $Is2025
        Build = $OSBuild
    }
}

function Get-SMBServerConfig {
    Show-SectionHeader "SMB Server Configuration" "⚙️"

    Show-ProgressDots "Reading SMB server settings"

    # Initialize findings tracker
    $Script:Findings = @()

    try {
        $Config = Get-SmbServerConfiguration -ErrorAction Stop

        Show-SubHeader "Security Settings"

        # RequireSecuritySignature - THE BIG ONE for Server 2025
        $SigningRequired = $Config.RequireSecuritySignature
        Write-ConfigItem "RequireSecuritySignature" $SigningRequired "False" $(if ($SigningRequired) { "← Server 2025 default - may cause disconnects!" } else { "" })

        if ($SigningRequired) {
            $Script:Findings += @{
                Type = "WARN"
                Title = "SMB Signing Required"
                Detail = "Server requires all clients to support SMB signing. Older Windows 10 builds or misconfigured clients may disconnect."
                Fix = "Set-SmbServerConfiguration -RequireSecuritySignature `$false -Confirm:`$false"
            }
        }

        Write-ConfigItem "EnableSecuritySignature" $Config.EnableSecuritySignature "" ""

        # Encryption settings
        $EncryptData = $Config.EncryptData
        Write-ConfigItem "EncryptData" $EncryptData "False" $(if ($EncryptData) { "← Forces encryption on ALL shares" } else { "" })

        if ($EncryptData) {
            $Script:Findings += @{
                Type = "WARN"
                Title = "Server-Wide Encryption Enabled"
                Detail = "All SMB traffic must be encrypted. Clients that don't support SMB 3.0+ encryption will fail."
                Fix = "Set-SmbServerConfiguration -EncryptData `$false -Confirm:`$false"
            }
        }

        $RejectUnencrypted = $Config.RejectUnencryptedAccess
        Write-ConfigItem "RejectUnencryptedAccess" $RejectUnencrypted "False" $(if ($RejectUnencrypted) { "← Blocks non-encrypted clients" } else { "" })

        if ($RejectUnencrypted) {
            $Script:Findings += @{
                Type = "WARN"
                Title = "Unencrypted Access Rejected"
                Detail = "Server will reject any client that cannot establish encrypted SMB connection."
                Fix = "Set-SmbServerConfiguration -RejectUnencryptedAccess `$false -Confirm:`$false"
            }
        }

        Show-SubHeader "Protocol Settings"

        Write-ConfigItem "EnableSMB1Protocol" $Config.EnableSMB1Protocol "False" $(if ($Config.EnableSMB1Protocol) { "← Security risk! Should be False" } else { "Good - SMB1 disabled" })
        Write-ConfigItem "EnableSMB2Protocol" $Config.EnableSMB2Protocol "True" $(if (-not $Config.EnableSMB2Protocol) { "← Required for modern clients!" } else { "" })

        Show-SubHeader "Timeout Settings"

        $AutoDisconnect = $Config.AutoDisconnectTimeout
        $AutoDisconnectStatus = if ($AutoDisconnect -eq -1 -or $AutoDisconnect -eq 0) { "OK" } elseif ($AutoDisconnect -le 15) { "WARN" } else { "INFO" }
        Write-ConfigItem "AutoDisconnectTimeout" "$AutoDisconnect min" "-1" $(
            switch ($AutoDisconnect) {
                -1 { "Disabled (never auto-disconnect)" }
                0  { "Disabled" }
                15 { "← Default - may cause disconnects!" }
                default { "" }
            }
        )

        if ($AutoDisconnect -gt 0 -and $AutoDisconnect -le 15) {
            $Script:Findings += @{
                Type = "WARN"
                Title = "Auto-Disconnect Timeout Active"
                Detail = "Server disconnects idle sessions after $AutoDisconnect minutes. Users who step away will lose their connection."
                Fix = "Set-SmbServerConfiguration -AutoDisconnectTimeout -1 -Confirm:`$false"
            }
        }

        Write-ConfigItem "DurableHandleV2TimeoutInSeconds" $Config.DurableHandleV2TimeoutInSeconds "" ""

    }
    catch {
        Write-DiagnosticItem "SMB Server Config" "Failed to read (may need Admin)" "ERROR"
    }
}

function Get-SMBShareConfig {
    Show-SectionHeader "SMB Shares" "📁"

    Show-ProgressDots "Enumerating shares"

    try {
        $Shares = Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -notlike "*$" -and $_.Name -ne "IPC$" }

        if ($Shares) {
            Write-Host ""
            Write-Host "    ╔═══════════════════════╦════════════════════════════════════╦═══════════╦═══════════╗" -ForegroundColor $Script:Colors.Table
            Write-Host "    ║ Share Name            ║ Path                               ║ Encrypted ║ Users     ║" -ForegroundColor $Script:Colors.Highlight
            Write-Host "    ╠═══════════════════════╬════════════════════════════════════╬═══════════╬═══════════╣" -ForegroundColor $Script:Colors.Table

            foreach ($Share in $Shares) {
                $EncColor = if ($Share.EncryptData) { $Script:Colors.Warning } else { $Script:Colors.Success }
                $EncText = if ($Share.EncryptData) { "Yes ⚠" } else { "No" }

                $ShareName = if ($Share.Name.Length -gt 21) { $Share.Name.Substring(0,18) + "..." } else { $Share.Name }
                $SharePath = if ($Share.Path.Length -gt 34) { $Share.Path.Substring(0,31) + "..." } else { $Share.Path }

                Write-Host "    ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host $ShareName.PadRight(21) -NoNewline -ForegroundColor $Script:Colors.Info
                Write-Host " ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host $SharePath.PadRight(34) -NoNewline -ForegroundColor $Script:Colors.Muted
                Write-Host " ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host $EncText.PadRight(9) -NoNewline -ForegroundColor $EncColor
                Write-Host " ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host "$($Share.CurrentUsers)".PadRight(9) -NoNewline -ForegroundColor $Script:Colors.Info
                Write-Host " ║" -ForegroundColor $Script:Colors.Table

                if ($Share.EncryptData) {
                    $Script:Findings += @{
                        Type = "WARN"
                        Title = "Share '$($Share.Name)' Requires Encryption"
                        Detail = "This share forces encryption. Clients that don't support SMB 3.0+ encryption will be rejected."
                        Fix = "Set-SmbShare -Name '$($Share.Name)' -EncryptData `$false -Force"
                    }
                }
            }

            Write-Host "    ╚═══════════════════════╩════════════════════════════════════╩═══════════╩═══════════╝" -ForegroundColor $Script:Colors.Table
        }
        else {
            Write-DiagnosticItem "Shares" "No user shares found (admin shares hidden)" "INFO"
        }
    }
    catch {
        Write-DiagnosticItem "SMB Shares" "Failed to enumerate (may need Admin)" "ERROR"
    }
}

function Get-SMBSessions {
    Show-SectionHeader "Active SMB Sessions" "👥"

    if (-not $Script:IsAdmin) {
        Write-DiagnosticItem "SMB Sessions" "Requires Administrator privileges" "SKIP"
        return
    }

    Show-ProgressDots "Querying active sessions"

    try {
        $Sessions = Get-SmbSession -ErrorAction Stop

        if ($Sessions) {
            Write-Host ""
            Write-Host "    ╔═══════════════════════╦═══════════════════════════════╦══════════╦═══════════╗" -ForegroundColor $Script:Colors.Table
            Write-Host "    ║ Client Computer       ║ User                          ║ Dialect  ║ Opens     ║" -ForegroundColor $Script:Colors.Highlight
            Write-Host "    ╠═══════════════════════╬═══════════════════════════════╬══════════╬═══════════╣" -ForegroundColor $Script:Colors.Table

            foreach ($Session in $Sessions) {
                $Client = if ($Session.ClientComputerName.Length -gt 21) { $Session.ClientComputerName.Substring(0,18) + "..." } else { $Session.ClientComputerName }
                $User = if ($Session.ClientUserName.Length -gt 29) { $Session.ClientUserName.Substring(0,26) + "..." } else { $Session.ClientUserName }

                # Dialect color coding
                $DialectColor = switch -Regex ($Session.Dialect) {
                    "3\.1\.1" { $Script:Colors.Success }
                    "3\.0"    { $Script:Colors.Success }
                    "2\.1"    { $Script:Colors.Warning }
                    "2\.0"    { $Script:Colors.Warning }
                    default   { $Script:Colors.Error }
                }

                Write-Host "    ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host $Client.PadRight(21) -NoNewline -ForegroundColor $Script:Colors.Info
                Write-Host " ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host $User.PadRight(29) -NoNewline -ForegroundColor $Script:Colors.Muted
                Write-Host " ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host "$($Session.Dialect)".PadRight(8) -NoNewline -ForegroundColor $DialectColor
                Write-Host " ║ " -NoNewline -ForegroundColor $Script:Colors.Table
                Write-Host "$($Session.NumOpens)".PadRight(9) -NoNewline -ForegroundColor $Script:Colors.Info
                Write-Host " ║" -ForegroundColor $Script:Colors.Table
            }

            Write-Host "    ╚═══════════════════════╩═══════════════════════════════╩══════════╩═══════════╝" -ForegroundColor $Script:Colors.Table

            Write-Host ""
            Write-Host "    Dialect Legend: " -NoNewline -ForegroundColor $Script:Colors.Muted
            Write-Host "3.1.1/3.0" -NoNewline -ForegroundColor $Script:Colors.Success
            Write-Host " = Modern  " -NoNewline -ForegroundColor $Script:Colors.Muted
            Write-Host "2.x" -NoNewline -ForegroundColor $Script:Colors.Warning
            Write-Host " = Legacy (may have issues)  " -NoNewline -ForegroundColor $Script:Colors.Muted
            Write-Host "1.x" -NoNewline -ForegroundColor $Script:Colors.Error
            Write-Host " = Obsolete" -ForegroundColor $Script:Colors.Muted
        }
        else {
            Write-DiagnosticItem "Active Sessions" "None currently connected" "INFO"
        }
    }
    catch {
        Write-DiagnosticItem "SMB Sessions" "Failed to query: $_" "ERROR"
    }
}

function Get-NetworkAdapterPower {
    Show-SectionHeader "Network Adapter Power Management" "🔌"

    Show-ProgressDots "Checking NIC power settings"

    try {
        $Adapters = Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq "Up" }

        foreach ($Adapter in $Adapters) {
            try {
                $Power = Get-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction Stop
                $AllowSleep = $Power.AllowComputerToTurnOffDevice

                $Status = if ($AllowSleep -eq "Enabled" -or $AllowSleep -eq $true) { "WARN" } else { "OK" }
                $StatusText = if ($AllowSleep -eq "Enabled" -or $AllowSleep -eq $true) { "Enabled ← Can cause disconnects!" } else { "Disabled" }

                Write-DiagnosticItem $Adapter.Name "Power Save: $StatusText" $Status

                if ($AllowSleep -eq "Enabled" -or $AllowSleep -eq $true) {
                    $Script:Findings += @{
                        Type = "WARN"
                        Title = "NIC Power Management Enabled: $($Adapter.Name)"
                        Detail = "Windows can turn off this adapter to save power, which drops all network connections."
                        Fix = "Disable-NetAdapterPowerManagement -Name '$($Adapter.Name)'"
                    }
                }
            }
            catch {
                Write-DiagnosticItem $Adapter.Name "Power settings not available" "INFO"
            }
        }
    }
    catch {
        Write-DiagnosticItem "Network Adapters" "Failed to query" "ERROR"
    }
}

function Get-SMBEventLogs {
    Show-SectionHeader "SMB Event Logs (Recent Errors)" "📋"

    if (-not $Script:IsAdmin) {
        Write-DiagnosticItem "Event Logs" "Requires Administrator privileges" "SKIP"
        return
    }

    Show-ProgressDots "Scanning event logs"

    # SMB Server events
    Show-SubHeader "SMB Server Events (Last 24 Hours)"

    try {
        $ServerEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-SMBServer/Operational'
            Level = 2,3  # Error and Warning
            StartTime = (Get-Date).AddHours(-24)
        } -MaxEvents 10 -ErrorAction SilentlyContinue

        if ($ServerEvents) {
            foreach ($Event in $ServerEvents) {
                $TimeStr = $Event.TimeCreated.ToString("MM/dd HH:mm")
                $MsgShort = if ($Event.Message.Length -gt 55) { $Event.Message.Substring(0,52) + "..." } else { $Event.Message }
                $MsgShort = $MsgShort -replace "`r`n", " " -replace "`n", " "

                $Level = if ($Event.Level -eq 2) { "ERROR" } else { "WARN" }
                Write-DiagnosticItem $TimeStr $MsgShort $Level
            }
        }
        else {
            Write-DiagnosticItem "SMB Server Log" "No errors in last 24 hours" "OK"
        }
    }
    catch {
        Write-DiagnosticItem "SMB Server Log" "Log not available or empty" "INFO"
    }

    # SMB Client Security events (signing/encryption failures)
    Show-SubHeader "SMB Client Security Events (Signing/Encryption)"

    try {
        $ClientSecEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-SMBClient/Security'
            StartTime = (Get-Date).AddHours(-24)
        } -MaxEvents 10 -ErrorAction SilentlyContinue

        if ($ClientSecEvents) {
            foreach ($Event in $ClientSecEvents) {
                $TimeStr = $Event.TimeCreated.ToString("MM/dd HH:mm")
                $MsgShort = if ($Event.Message.Length -gt 55) { $Event.Message.Substring(0,52) + "..." } else { $Event.Message }
                $MsgShort = $MsgShort -replace "`r`n", " " -replace "`n", " "

                Write-DiagnosticItem $TimeStr $MsgShort "WARN"
            }

            $Script:Findings += @{
                Type = "WARN"
                Title = "SMB Client Security Events Detected"
                Detail = "There are signing or encryption negotiation failures. This often indicates client/server security mismatch."
                Fix = "Review events above - typically caused by RequireSecuritySignature mismatch"
            }
        }
        else {
            Write-DiagnosticItem "SMB Client Security" "No security events in last 24 hours" "OK"
        }
    }
    catch {
        Write-DiagnosticItem "SMB Client Security" "Log not available" "INFO"
    }
}

function Get-FirewallConfig {
    Show-SectionHeader "Firewall SMB Rules" "🛡️"

    Show-ProgressDots "Checking firewall configuration"

    try {
        # Check SMB inbound rules
        $SMBRules = Get-NetFirewallRule -DisplayName "*SMB*" -ErrorAction SilentlyContinue |
            Where-Object { $_.Direction -eq "Inbound" }

        if ($SMBRules) {
            foreach ($Rule in $SMBRules | Select-Object -First 5) {
                $Status = if ($Rule.Enabled -eq "True") { "OK" } else { "WARN" }
                $EnabledText = if ($Rule.Enabled -eq "True") { "Enabled" } else { "Disabled" }

                $RuleName = if ($Rule.DisplayName.Length -gt 40) { $Rule.DisplayName.Substring(0,37) + "..." } else { $Rule.DisplayName }
                Write-DiagnosticItem $RuleName $EnabledText $Status
            }
        }

        # Check File and Printer Sharing
        $FPSRules = Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue |
            Where-Object { $_.Direction -eq "Inbound" -and $_.Profile -match "Domain|Private" }

        $FPSEnabled = ($FPSRules | Where-Object { $_.Enabled -eq "True" }).Count
        $FPSTotal = $FPSRules.Count

        Write-Host ""
        Write-DiagnosticItem "File & Printer Sharing Rules" "$FPSEnabled of $FPSTotal enabled" $(if ($FPSEnabled -gt 0) { "OK" } else { "ERROR" })
    }
    catch {
        Write-DiagnosticItem "Firewall Rules" "Failed to query" "ERROR"
    }
}

function Get-DNSConfig {
    Show-SectionHeader "DNS Configuration" "🌐"

    Show-ProgressDots "Checking DNS settings"

    try {
        $DNSServers = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.ServerAddresses.Count -gt 0 } |
            Select-Object -First 3

        foreach ($DNS in $DNSServers) {
            $Servers = $DNS.ServerAddresses -join ", "
            $AdapterName = if ($DNS.InterfaceAlias.Length -gt 20) { $DNS.InterfaceAlias.Substring(0,17) + "..." } else { $DNS.InterfaceAlias }
            Write-DiagnosticItem $AdapterName $Servers "INFO"
        }

        # Test DNS resolution of local hostname
        Write-Host ""
        try {
            $LocalResolve = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME)
            Write-DiagnosticItem "Local hostname resolves" "$($LocalResolve.AddressList[0])" "OK"
        }
        catch {
            Write-DiagnosticItem "Local hostname resolution" "Failed!" "ERROR"
            $Script:Findings += @{
                Type = "ERROR"
                Title = "DNS Resolution Failure"
                Detail = "This computer's hostname does not resolve via DNS. Clients may fail to connect."
                Fix = "Check DNS registration and ensure A record exists for this server"
            }
        }
    }
    catch {
        Write-DiagnosticItem "DNS Configuration" "Failed to query" "ERROR"
    }
}

function Show-FindingsSummary {
    Show-SectionHeader "Findings Summary" "📊"

    if (-not $Script:Findings -or $Script:Findings.Count -eq 0) {
        Show-FindingBox "No Issues Detected" "SMB configuration appears healthy. If disconnections persist, check client-side settings and network infrastructure (switches, firewalls)." "OK"
        return
    }

    $ErrorCount = ($Script:Findings | Where-Object { $_.Type -eq "ERROR" }).Count
    $WarnCount = ($Script:Findings | Where-Object { $_.Type -eq "WARN" }).Count

    Write-Host ""
    Write-Host "    Found " -NoNewline -ForegroundColor $Script:Colors.Info
    if ($ErrorCount -gt 0) {
        Write-Host "$ErrorCount error(s)" -NoNewline -ForegroundColor $Script:Colors.Error
        Write-Host " and " -NoNewline -ForegroundColor $Script:Colors.Info
    }
    Write-Host "$WarnCount warning(s)" -NoNewline -ForegroundColor $Script:Colors.Warning
    Write-Host " that may cause share disconnections:" -ForegroundColor $Script:Colors.Info

    $i = 1
    foreach ($Finding in $Script:Findings) {
        Write-Host ""
        Write-Host "    ┌─ Finding #$i " -NoNewline -ForegroundColor $(if ($Finding.Type -eq "ERROR") { $Script:Colors.Error } else { $Script:Colors.Warning })
        Write-Host "$("─" * 60)" -ForegroundColor $Script:Colors.Muted
        Write-Host "    │ " -NoNewline -ForegroundColor $Script:Colors.Muted
        Write-Host $Finding.Title -ForegroundColor $Script:Colors.Highlight
        Write-Host "    │ " -NoNewline -ForegroundColor $Script:Colors.Muted
        Write-Host $Finding.Detail -ForegroundColor $Script:Colors.Info
        Write-Host "    │" -ForegroundColor $Script:Colors.Muted
        Write-Host "    │ " -NoNewline -ForegroundColor $Script:Colors.Muted
        Write-Host "FIX: " -NoNewline -ForegroundColor $Script:Colors.Success
        Write-Host $Finding.Fix -ForegroundColor $Script:Colors.Accent
        Write-Host "    └$("─" * 72)" -ForegroundColor $Script:Colors.Muted

        $i++
    }
}

function Show-RecommendedActions {
    Show-SectionHeader "Recommended Actions" "🔧"

    Write-Host ""
    Write-Host "    If share disconnections continue after applying fixes above:" -ForegroundColor $Script:Colors.Info
    Write-Host ""
    Write-Host "    1. " -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host "Run this diagnostic on a WORKSTATION that's disconnecting" -ForegroundColor $Script:Colors.Info
    Write-Host "       " -NoNewline
    Write-Host "The SMB Client Security log shows exactly why connections fail" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
    Write-Host "    2. " -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host "Test mapping by IP address instead of hostname" -ForegroundColor $Script:Colors.Info
    Write-Host "       " -NoNewline
    Write-Host "net use Z: \\192.168.x.x\ShareName" -ForegroundColor $Script:Colors.Muted
    Write-Host "       " -NoNewline
    Write-Host "If this works, DNS is the problem" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
    Write-Host "    3. " -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host "Check network infrastructure" -ForegroundColor $Script:Colors.Info
    Write-Host "       " -NoNewline
    Write-Host "Switch port power saving, spanning tree, VLAN configuration" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
    Write-Host "    4. " -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host "Disable Offline Files (CSC) on workstations" -ForegroundColor $Script:Colors.Info
    Write-Host "       " -NoNewline
    Write-Host "Control Panel → Sync Center → Manage Offline Files" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
}

function Show-Footer {
    Write-Host ""
    Write-Host "    ══════════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Muted
    Write-Host "    " -NoNewline
    Write-Host "$Script:Company" -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host " │ " -NoNewline -ForegroundColor $Script:Colors.Muted
    Write-Host "SMB Diagnostics v$Script:Version" -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host " │ " -NoNewline -ForegroundColor $Script:Colors.Muted
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Script:Colors.Muted
    Write-Host "    ══════════════════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Muted
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize findings array
$Script:Findings = @()

# Show banner
Show-Banner

# Run diagnostics
$SysInfo = Get-SystemInfo
Get-SMBServerConfig
Get-SMBShareConfig
Get-SMBSessions
Get-NetworkAdapterPower
Get-SMBEventLogs
Get-FirewallConfig
Get-DNSConfig

# Show summary
Show-FindingsSummary
Show-RecommendedActions

# Footer
Show-Footer

Write-Host "    Press any key to exit..." -ForegroundColor $Script:Colors.Muted
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
