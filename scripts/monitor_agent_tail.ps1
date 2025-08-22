#!/usr/bin/env pwsh
<#
.SYNOPSIS
    PowerShell helper for tailing Super Alita agent event logs

.DESCRIPTION
    Provides real-time monitoring of agent events with filtering and formatting options.
    Works with both the detailed monitor logs and JSONL telemetry streams.

.PARAMETER LogType
    Type of log to tail: 'detailed', 'jsonl', or 'both' (default: both)

.PARAMETER Filter
    Regex pattern to filter events (case-insensitive)

.PARAMETER Follow
    Whether to follow new entries (default: true)

.PARAMETER Lines
    Number of initial lines to show (default: 50)

.EXAMPLE
    .\monitor_agent_tail.ps1
    # Tail both log types with default settings

.EXAMPLE
    .\monitor_agent_tail.ps1 -LogType jsonl -Filter "tool_call|tool_result"
    # Tail only JSONL logs, filter for tool events

.EXAMPLE
    .\monitor_agent_tail.ps1 -Filter "ERROR|FATAL" -Lines 100
    # Show last 100 lines and filter for errors
#>

param(
    [ValidateSet('detailed', 'jsonl', 'both')]
    [string]$LogType = 'both',
    
    [ValidateSet('debug', 'info', 'warning', 'error', 'fatal', 'all')]
    [string]$Level = 'all',
    
    [string]$Filter = '',
    
    [bool]$Follow = $true,
    
    [int]$Lines = 50,
    
    [int]$Tail = 50
)

# Set UTF-8 encoding for console output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Define log file paths
$LogDir = Join-Path $PSScriptRoot ".." "logs"
$DetailedLog = Join-Path $LogDir "agent_detailed_monitor.log"
$JsonlLog = Join-Path $LogDir "telemetry.jsonl"

# Colors for different event types (ASCII-safe)
$Colors = @{
    'INFO'    = 'Green'
    'DEBUG'   = 'Cyan'
    'WARNING' = 'Yellow'
    'ERROR'   = 'Red'
    'FATAL'   = 'Magenta'
    'DEFAULT' = 'White'
}

function Format-LogEntry {
    param([string]$Line, [string]$LogType)
    
    # Apply color coding based on log level
    $color = 'White'
    foreach ($level in $Colors.Keys) {
        if ($Line -match "\b$level\b") {
            $color = $Colors[$level]
            break
        }
    }
    
    # Add prefix for log type when showing both
    if ($LogType -eq 'both') {
        $prefix = if ($Line.StartsWith('{')) { '[JSONL]' } else { '[LOG] ' }
        Write-Host "$prefix " -NoNewline -ForegroundColor Gray
    }
    
    Write-Host $Line -ForegroundColor $color
}

function Test-LogFiles {
    $issues = @()
    
    if (-not (Test-Path $LogDir)) {
        $issues += "Log directory not found: $LogDir"
    }
    
    if ($LogType -in @('detailed', 'both') -and -not (Test-Path $DetailedLog)) {
        $issues += "Detailed log not found: $DetailedLog"
    }
    
    if ($LogType -in @('jsonl', 'both') -and -not (Test-Path $JsonlLog)) {
        $issues += "JSONL log not found: $JsonlLog"
    }
    
    return $issues
}

function Start-TailMonitoring {
    Write-Host "=== Super Alita Agent Log Tail ===" -ForegroundColor Cyan
    Write-Host "Log Type: $LogType" -ForegroundColor Gray
    Write-Host "Level Filter: $Level" -ForegroundColor Gray
    Write-Host "Regex Filter: $(if ($Filter) { $Filter } else { '(none)' })" -ForegroundColor Gray
    Write-Host "Follow: $Follow" -ForegroundColor Gray
    Write-Host "Initial Lines: $(if ($Tail -gt 0) { $Tail } else { $Lines })" -ForegroundColor Gray
    Write-Host ""
    
    # Check for log files
    $issues = Test-LogFiles
    if ($issues) {
        Write-Host "Issues found:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Make sure the detailed monitor is running:" -ForegroundColor Yellow
        Write-Host "  python monitor_agent_detailed.py" -ForegroundColor Cyan
        return
    }
    
    # PowerShell Get-Content with -Tail and -Wait
    $tailLines = if ($Tail -gt 0) { $Tail } else { $Lines }
    $tailArgs = @{
        'Tail' = $tailLines
    }
    
    if ($Follow) {
        $tailArgs['Wait'] = $true
    }
    
    try {
        if ($LogType -eq 'detailed') {
            Write-Host "Tailing detailed log: $DetailedLog" -ForegroundColor Green
            $stream = Get-Content $DetailedLog @tailArgs
        }
        elseif ($LogType -eq 'jsonl') {
            Write-Host "Tailing JSONL log: $JsonlLog" -ForegroundColor Green
            $stream = Get-Content $JsonlLog @tailArgs
        }
        elseif ($LogType -eq 'both') {
            Write-Host "Tailing both logs (detailed + JSONL)" -ForegroundColor Green
            # For 'both', we'll alternate between files or use a more complex approach
            # For simplicity, let's tail the detailed log and note JSONL availability
            Write-Host "Note: Use -LogType jsonl to specifically tail the JSONL stream" -ForegroundColor Yellow
            $stream = Get-Content $DetailedLog @tailArgs
        }
        
        # Process the stream
        $stream | ForEach-Object {
            $line = $_
            
            # Apply level filter if specified (not 'all')
            if ($Level -ne 'all') {
                $levelPattern = switch ($Level) {
                    'debug'   { '\bDEBUG\b' }
                    'info'    { '\bINFO\b' }
                    'warning' { '\bWARNING\b' }
                    'error'   { '\bERROR\b' }
                    'fatal'   { '\bFATAL\b' }
                }
                if ($line -notmatch $levelPattern) {
                    return
                }
            }
            
            # Apply regex filter if specified
            if ($Filter -and $line -notmatch $Filter) {
                return
            }
            
            # Format and display
            Format-LogEntry $line $LogType
        }
        
    } catch {
        Write-Host "Error during log tailing: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Help {
    Write-Host "Super Alita Agent Log Tail Helper" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\monitor_agent_tail.ps1 [-LogType <type>] [-Level <level>] [-Filter <pattern>] [-Follow <bool>] [-Tail <count>]"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\monitor_agent_tail.ps1                                    # Tail both logs, all levels"
    Write-Host "  .\monitor_agent_tail.ps1 -Level debug -Tail 50              # Only DEBUG events, last 50 lines"
    Write-Host "  .\monitor_agent_tail.ps1 -LogType jsonl                     # JSONL only"
    Write-Host "  .\monitor_agent_tail.ps1 -Filter 'tool_call|ERROR'          # Filter events"
    Write-Host "  .\monitor_agent_tail.ps1 -Follow $false -Tail 100           # Show last 100, don't follow"
    Write-Host ""
    Write-Host "Log Types:" -ForegroundColor Yellow
    Write-Host "  detailed  - Human-readable log with formatting"
    Write-Host "  jsonl     - Structured JSON Lines for analysis"
    Write-Host "  both      - Both logs (defaults to detailed display)"
    Write-Host ""
    Write-Host "Log Levels:" -ForegroundColor Yellow
    Write-Host "  debug     - Show only DEBUG events (full JSON payloads)"
    Write-Host "  info      - Show only INFO events"
    Write-Host "  warning   - Show only WARNING events"
    Write-Host "  error     - Show only ERROR events"
    Write-Host "  fatal     - Show only FATAL events"
    Write-Host "  all       - Show all levels (default)"
    Write-Host ""
    Write-Host "Common Filters:" -ForegroundColor Yellow
    Write-Host "  'ERROR|FATAL'           - Show only errors"
    Write-Host "  'tool_call|tool_result' - Show tool events"
    Write-Host "  'conversation_message'  - Show user interactions"
    Write-Host "  'CREATOR|GAP'          - Show tool creation events"
}

# Main execution
if ($args -contains '-h' -or $args -contains '--help' -or $args -contains '/help') {
    Show-Help
    exit 0
}

Write-Host "Starting Super Alita agent log tail..." -ForegroundColor Cyan
Start-TailMonitoring

# Cleanup message
Write-Host ""
Write-Host "Log tailing stopped." -ForegroundColor Yellow

# SIG # Begin signature block
# MIIaSQYJKoZIhvcNAQcCoIIaOjCCGjYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAONw+afxctzgZ2
# lgBp802bOp+EoinSRlNdZ08neQLVL6CCFRswggHdMIIBRqADAgECAhB1LVe8LkJa
# nkn+CcMy/7DwMA0GCSqGSIb3DQEBBQUAMBUxEzARBgNVBAMTCkF1dG9Ib3RrZXkw
# IBcNMjUwMzEwMTkzNDMyWhgPOTk5OTAxMDExMjAwMDBaMBUxEzARBgNVBAMTCkF1
# dG9Ib3RrZXkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAKkvQYONqskINI1i
# BBkYCk9PniXin9+yMrpQAml4pZED9brGePZd+51f5FsTrNpeMRnRV7NNyJEDOLFR
# IhkBPDvwNciJEFuNLCbUkt9O6o3uT858uvn5PJ1HHq4yrtW7OQYkA9c69Pfh+xIv
# t9P8wBgkrs4XnFAi4cvLMWE/P2ydAgMBAAGjLDAqMBAGA1UdBAEB/wQGMAQDAgSQ
# MBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMDMA0GCSqGSIb3DQEBBQUAA4GBADXNo2wn
# fDUdgw3T5iYLJ+pix6VKMDc4OltoD2eZ1dW1C3LMdUyenLliTS+sd+e1uaHwf2iD
# VpKpLLiWMXKyxlvqg09K5Ajz1yIt3POxQ7VYXazT+xbbC1JTD0rXiD6M847uWTSq
# PwR9+nIwhhtUpMksc07Zifqd4V4w3MSdM+DuMIIFjTCCBHWgAwIBAgIQDpsYjvnQ
# Lefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAw
# WhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QN
# xDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DC
# srp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTr
# BcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17l
# Necxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WC
# QTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1
# EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KS
# Op493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAs
# QWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUO
# UlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtv
# sauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCC
# ATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQD
# AgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9D
# XFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6
# Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuW
# cqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLih
# Vo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBj
# xZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02f
# c7cBqZ9Xql4o4rmUMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMiDDpJhjANBgkq
# hkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBU
# cnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcNMzgwMTE0MjM1OTU5WjBp
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMT
# OERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2
# IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtHgx0wqY
# QXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oRjzUXMmxCqvkbsDpz4aH+
# qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+QdSKWM06qchUP+AbdJgMQB
# 3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRuQL37QXbDhAktVJMQbzIB
# HYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0Xm+nt5pnYJU3Gmq6bNMI
# 1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQVESYOszFI2Wv82wnJRfN2
# 0VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2qHxJ0ucS638ZxqU14lDn
# ki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF0LJAQQZxst7VvwDDjAmS
# FTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgxCZSKi17yVp2NL+cnT6To
# y+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9Xr/u6bDTnYCTKIsDq1Btm
# XUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7OgWmnhFr4yUozZtqgPrHR
# VHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOCAV0wggFZMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esrikFb2L9RJ7MtOMB8GA1Ud
# IwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0f
# BDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcB
# MA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEwvb4LyLU0pn/N0IfFiBow
# f0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8G0iP5kvN2n7Jd2E4/iEI
# UBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40y8S4F3/a+Z1jEMK/DMm/
# axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCDA/JYsq7pGdogP8HRtrYf
# ctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADVZKON/gnZruMvNYY2o1f4
# MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4EWj7PtspIHBldNE2K9i69
# 7cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpVfHIqQ6Ku/qjTY6hc3hsX
# MrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0c1ugMZyZZd/BdHLiRu7h
# AWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7OigizwJWeukcyIPbAvjSab
# nf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2rtY/9TCA6TD8dC3JE3rY
# krhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz0scmbKvFoW2jNrbM1pD2
# T7m3XDCCBu0wggTVoAMCAQICEAqA7xhLjfEFgtHEdqeVdGgwDQYJKoZIhvcNAQEL
# BQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYD
# VQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNI
# QTI1NiAyMDI1IENBMTAeFw0yNTA2MDQwMDAwMDBaFw0zNjA5MDMyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgU0hBMjU2IFJTQTQwOTYgVGltZXN0YW1wIFJlc3BvbmRlciAyMDI1
# IDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDQRqwtEsae0OquYFaz
# K1e6b1H/hnAKAd/KN8wZQjBjMqiZ3xTWcfsLwOvRxUwXcGx8AUjni6bz52fGTfr6
# PHRNv6T7zsf1Y/E3IU8kgNkeECqVQ+3bzWYesFtkepErvUSbf+EIYLkrLKd6qJnu
# zK8Vcn0DvbDMemQFoxQ2Dsw4vEjoT1FpS54dNApZfKY61HAldytxNM89PZXUP/5w
# WWURK+IfxiOg8W9lKMqzdIo7VA1R0V3Zp3DjjANwqAf4lEkTlCDQ0/fKJLKLkzGB
# Tpx6EYevvOi7XOc4zyh1uSqgr6UnbksIcFJqLbkIXIPbcNmA98Oskkkrvt6lPAw/
# p4oDSRZreiwB7x9ykrjS6GS3NR39iTTFS+ENTqW8m6THuOmHHjQNC3zbJ6nJ6SXi
# LSvw4Smz8U07hqF+8CTXaETkVWz0dVVZw7knh1WZXOLHgDvundrAtuvz0D3T+dYa
# NcwafsVCGZKUhQPL1naFKBy1p6llN3QgshRta6Eq4B40h5avMcpi54wm0i2ePZD5
# pPIssoszQyF4//3DoK2O65Uck5Wggn8O2klETsJ7u8xEehGifgJYi+6I03UuT1j7
# FnrqVrOzaQoVJOeeStPeldYRNMmSF3voIgMFtNGh86w3ISHNm0IaadCKCkUe2Lnw
# JKa8TIlwCUNVwppwn4D3/Pt5pwIDAQABo4IBlTCCAZEwDAYDVR0TAQH/BAIwADAd
# BgNVHQ4EFgQU5Dv88jHt/f3X85FxYxlQQ89hjOgwHwYDVR0jBBgwFoAU729TSunk
# Bnx6yuKQVvYv1Ensy04wDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMIGVBggrBgEFBQcBAQSBiDCBhTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMF0GCCsGAQUFBzAChlFodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hB
# MjU2MjAyNUNBMS5jcnQwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNI
# QTI1NjIwMjVDQTEuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwH
# ATANBgkqhkiG9w0BAQsFAAOCAgEAZSqt8RwnBLmuYEHs0QhEnmNAciH45PYiT9s1
# i6UKtW+FERp8FgXRGQ/YAavXzWjZhY+hIfP2JkQ38U+wtJPBVBajYfrbIYG+Dui4
# I4PCvHpQuPqFgqp1PzC/ZRX4pvP/ciZmUnthfAEP1HShTrY+2DE5qjzvZs7JIIgt
# 0GCFD9ktx0LxxtRQ7vllKluHWiKk6FxRPyUPxAAYH2Vy1lNM4kzekd8oEARzFAWg
# eW3az2xejEWLNN4eKGxDJ8WDl/FQUSntbjZ80FU3i54tpx5F/0Kr15zW/mJAxZMV
# BrTE2oi0fcI8VMbtoRAmaaslNXdCG1+lqvP4FbrQ6IwSBXkZagHLhFU9HCrG/syT
# RLLhAezu/3Lr00GrJzPQFnCEH1Y58678IgmfORBPC1JKkYaEt2OdDh4GmO0/5cHe
# lAK2/gTlQJINqDr6JfwyYHXSd+V08X1JUPvB4ILfJdmL+66Gp3CSBXG6IwXMZUXB
# htCyIaehr0XkBoDIGMUG1dUtwq1qmcwbdUfcSYCn+OwncVUXf53VJUNOaMWMts0V
# lRYxe5nK+At+DI96HAlXHAL5SlfYxJ7La54i71McVWRP66bW+yERNpbJCjyCYG2j
# +bdpxo/1Cy4uPcU3AWVPGrbn5PhDBf3Froguzzhk++ami+r3Qrx5bIbY3TVzgiFI
# 7Gq3zWcxggSEMIIEgAIBATApMBUxEzARBgNVBAMTCkF1dG9Ib3RrZXkCEHUtV7wu
# QlqeSf4JwzL/sPAwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgifd/0HT1H0ynid9ssLGn
# bwe6rYyQH+6vVh4SYb2YQk8wDQYJKoZIhvcNAQEBBQAEgYB0ZxdmC/z4BJXfzrpU
# mMreLUu5s4fUZyVKWTsnycCNlMKhYCCTAq/jZX1JOLyn0Vyww6mQoMdXrcaw3IQ2
# K7WQoND/hc/R5soH64AD2vF4FWQqXxdea6KShpyEDZoqDWnTZlx9ObNFiU34XeS7
# tw0mBysos4OUnZF7mpioCEJedaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA4
# MTMwODU3NTVaMC8GCSqGSIb3DQEJBDEiBCDalo0+YDxYvN2Gb5m+q606yoNF7jXY
# jXIH+OOyiUKc/jANBgkqhkiG9w0BAQEFAASCAgABn/g0nO4Rd5PRkfrH9Y23EpDQ
# YFL5uZsW5YRdEuxSwaFgAVHA7Bs1sH1RwjgFL4vvDlioPYeRE75xiunuv4ipRkZr
# oM1xKTWvXY3wY6GSeNGcJ3W0BH6xswKsHw2Of+HTEV05M5yVlZfiOQx+NJGCsZIt
# 8dvR/Yjxn8sQdwzBQgoqe0ONW6EpkYh4Dnja+MgfbMeGyk1ndcRicJgM61vBQfzj
# Tj+ODFAz0Kf1Ary1N3C3wN6tqZg2FePqNNCBXfytddFJubxgd0k22cxc5TkQgE7W
# mEczJZoh/9NOS8uyyzn+BTuCpBzspg1e0ac9C7zRzn8S+amgxItHOKvv04QQ89s3
# hsr6PqFtX5hp/NBlk1YgCX7LUO9JykSdezx337XNEYuuxGDwzrpzqqvJFhEwJ9BE
# 6VxVV9ICyqAlcWbXmyNSBKhhy57bN5WMiS7AGpcdzxLZYt0HkvmGCd1i72WFWg1a
# NFVIVOfiZ/DUHg+8GbVFIN3jBCT+8VZAWyrdqe2Su9Zs3WdP3TF69ZMvRCYFh1Xn
# uDwu1KBawtit+u+IzXHSjndhbhTPvUya/t/78guK9P8N6BYeEROQeIb0C/jkU+9H
# o4wHsTel7ns20SzvLF3eO2getGHTSJ3eV+F3iCtqyPKydA3Mv9POavtyXSpaHjcP
# oHdNHjEau7AiHkaRNg==
# SIG # End signature block
