# PowerShell Script: test-pipeline.ps1
# Runs the Super Alita pipeline test and displays results

param(
    [switch]$HealthOnly,
    [switch]$PipelineOnly,
    [switch]$Detailed
)

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColoredOutput {
    param($Message, $Color = $Reset)
    Write-Host "$Color$Message$Reset"
}

function Show-Header {
    param($Title)
    Write-Host ""
    Write-ColoredOutput "=" * 60 $Blue
    Write-ColoredOutput "🚀 $Title" $Blue
    Write-ColoredOutput "=" * 60 $Blue
    Write-Host ""
}

function Show-Result {
    param($TestName, $Success, $Details = "")
    $Icon = if ($Success) { "✅" } else { "❌" }
    $Color = if ($Success) { $Green } else { $Red }
    Write-ColoredOutput "$Icon $TestName" $Color
    if ($Details) {
        Write-Host "   $Details"
    }
}

# Change to the correct directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Push-Location $ProjectRoot

try {
    Show-Header "Super Alita Diagnostic Test Suite"
    
    # Test 1: Process Health Check
    if (-not $PipelineOnly) {
        Show-Header "Process Health Check"
        Write-ColoredOutput "🩺 Running process health diagnostics..." $Yellow
        
        $HealthResult = & python diagnostics/process_health_check.py
        $HealthExitCode = $LASTEXITCODE
        
        switch ($HealthExitCode) {
            0 { Show-Result "Process Health Check" $true "All systems healthy" }
            1 { Show-Result "Process Health Check" $false "System degraded - some issues found" }
            2 { Show-Result "Process Health Check" $false "System unhealthy - major issues" }
            3 { Show-Result "Process Health Check" $false "Health check failed to run" }
            default { Show-Result "Process Health Check" $false "Unknown exit code: $HealthExitCode" }
        }
        
        if ($Detailed -and (Test-Path "super_alita_health_report.json")) {
            Write-ColoredOutput "`n📄 Health Report Summary:" $Blue
            $HealthReport = Get-Content "super_alita_health_report.json" | ConvertFrom-Json
            Write-Host "   Overall Status: $($HealthReport.overall_status)"
            Write-Host "   Agent Running: $($HealthReport.checks.processes.agent_running)"
            Write-Host "   Redis Available: $($HealthReport.checks.redis.redis_available)"
            Write-Host "   Channels Subscribed: $($HealthReport.checks.channels.subscribed_channels)/$($HealthReport.checks.channels.critical_channels_count)"
        }
        
        Write-Host ""
    }
    
    # Test 2: Cognitive Pipeline Test
    if (-not $HealthOnly) {
        Show-Header "Cognitive Pipeline Test"
        Write-ColoredOutput "🔬 Running cognitive pipeline diagnostics..." $Yellow
        
        $PipelineResult = & python diagnostics/agent_pipeline_test.py
        $PipelineExitCode = $LASTEXITCODE
        
        Show-Result "Cognitive Pipeline Test" ($PipelineExitCode -eq 0) $(
            if ($PipelineExitCode -eq 0) { "Pipeline fully operational" } 
            else { "Pipeline issues detected" }
        )
        
        Write-Host ""
    }
    
    # Overall Assessment
    Show-Header "Overall Assessment"
    
    $OverallSuccess = $true
    
    if (-not $PipelineOnly -and $HealthExitCode -gt 1) {
        $OverallSuccess = $false
        Write-ColoredOutput "⚠️ Critical health issues detected" $Red
    }
    
    if (-not $HealthOnly -and $PipelineExitCode -ne 0) {
        $OverallSuccess = $false
        Write-ColoredOutput "⚠️ Cognitive pipeline issues detected" $Red
    }
    
    if ($OverallSuccess) {
        Write-ColoredOutput "🎉 Super Alita is functioning correctly!" $Green
        Write-Host "   - All diagnostic tests passed"
        Write-Host "   - System is ready for operation"
    }
    else {
        Write-ColoredOutput "💥 Issues detected with Super Alita" $Red
        Write-Host ""
        Write-ColoredOutput "💡 Troubleshooting recommendations:" $Yellow
        Write-Host "   1. Ensure Redis/Memurai is running: memurai-server --port 6379"
        Write-Host "   2. Start the Super Alita agent: python launch_super_alita.py"
        Write-Host "   3. Check logs for detailed error information"
        Write-Host "   4. Run: python comprehensive_validation_suite.py"
    }
    
    Write-Host ""
    Write-ColoredOutput "📊 Test Summary:" $Blue
    if (-not $PipelineOnly) {
        Write-Host "   Health Check: $(if ($HealthExitCode -le 1) { '✅ PASS' } else { '❌ FAIL' })"
    }
    if (-not $HealthOnly) {
        Write-Host "   Pipeline Test: $(if ($PipelineExitCode -eq 0) { '✅ PASS' } else { '❌ FAIL' })"
    }
    
    Write-Host ""
    Write-ColoredOutput "For more detailed information, check the generated report files." $Blue
    
}
catch {
    Write-ColoredOutput "❌ Error running diagnostic tests: $_" $Red
    exit 1
}
finally {
    Pop-Location
}

# Exit with appropriate code
if ($OverallSuccess) {
    exit 0
}
else {
    exit 1
}
# SIG # Begin signature block
# MIIaSQYJKoZIhvcNAQcCoIIaOjCCGjYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCegmXaXIVlzcpJ
# 71hdDUfRb3PbxbmMJDzs9RH8Dh507KCCFRswggHdMIIBRqADAgECAhB1LVe8LkJa
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgdYnJ+NIQNL+SwadHdoUB
# Ap+Vpu1mchnXJkrkAP3W8LkwDQYJKoZIhvcNAQEBBQAEgYCfpx6ohsKHAStfza+K
# kdjE23qUYpK7WmTAb0X3d1Mak6QbC1XRElugw7wNywRqBUW+BUhOuw46RMFGN8e8
# pFAOuLccJMYfgiNdcBNUYP2hmp9yDUPBiyzHpOT77nXufBgAI32H6EWrnDvqRAc9
# RmheUyr2G2qfAdgIiixYBcz2D6GCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA4
# MTYyMzM5MThaMC8GCSqGSIb3DQEJBDEiBCCSnYRgDK9pAvLcQ4ArHEQJ/BKzvuaF
# mItXU6CmbJPxczANBgkqhkiG9w0BAQEFAASCAgC06AhSxwyHcOoK/bOIpOuQPl2c
# ea4Hs01p+FxmUKFX7yZAvAXMhJtwalEl5bzoUjJ8/6kbCyzWBcfPFYM/GPssCXDY
# C0Bb4gCj2IWp+GPcD/JFgOnRov/I24m2ugAwb2Zhx04xBsAd9FKtbMbylMLHv3+2
# dlR4AcaAHPX8JY/PDYIXZsqLG6fG0sFAnXFVFWfYAHHvkcbF3gPotnLGlg2BGoIN
# r1vnNCmxcbTyDQCg6td12hOgfKT6ZuAL6Fig0Vvbcl1t3+UJRRuiRKqxEO15oQbR
# rNVzloHJ6VD/v530bNHs/p2swfVeq75j3iEASUeKTLeCYsBAYJK5g4v19DahEAN3
# jGFDcYT+LtMkAHGz15C82sQGet2w42+romuhj/cRgXGcNSwTlnArFkAw7R4RY3Dx
# QN3waUJVaSVWE2hQm7k2sfw9MtTGh6JNJfjgM1wXEXNt+hvGnEVcmQYfBGfZGQks
# G2FyKE00EvooJd0kigqGj5Cjyz+pqoQc8/QVREyp1tNQO78ylMJ5zI/vVt8bimLR
# PBc85+lJRqM9GllI9ZDKBP8v0CUvsGDwLq1YQcT6zryX0Qf8BWViE+lUKzzTkq4R
# y66vzBGtZTofGNv6oHxOjQFRyMUm41wc2TGLtRFhLLfFn1h4N2fkaxSKxhFEwP7b
# TBPw/xzcdWrp38Z02A==
# SIG # End signature block
