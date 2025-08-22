# Set-GeminiApiEnv.ps1
#
# This script sets the GEMINI_API_KEY environment variable for the current PowerShell session.
# It's useful for quick testing or if you need to set the variable without modifying the .env file.
#
# Usage:
#   .\scripts\Set-GeminiApiEnv.ps1 -ApiKey "your_api_key_here"
#
# Parameters:
#   -ApiKey: The API key to use
#   -FromEnvFile: Switch to load the API key from .env file

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [switch]$FromEnvFile
)

function Get-ApiKeyFromEnvFile {
    $envPath = Join-Path -Path $PSScriptRoot -ChildPath "..\\.env"

    if (-not (Test-Path $envPath)) {
        Write-Error "No .env file found at: $envPath"
        return $null
    }

    $content = Get-Content $envPath

    foreach ($line in $content) {
        if ($line -match "^GEMINI_API_KEY=(.+)$") {
            return $matches[1]
        }
    }

    Write-Error "GEMINI_API_KEY not found in .env file"
    return $null
}

# Main script
if ($FromEnvFile) {
    $ApiKey = Get-ApiKeyFromEnvFile
    if (-not $ApiKey) {
        exit 1
    }
}

if (-not $ApiKey) {
    Write-Error "API key not provided. Use -ApiKey parameter or -FromEnvFile switch."
    exit 1
}

# Set the environment variable
$env:GEMINI_API_KEY = $ApiKey

# Verify that the environment variable is set
if ($env:GEMINI_API_KEY) {
    Write-Host "✅ GEMINI_API_KEY has been set successfully." -ForegroundColor Green
    Write-Host "   API key starts with: $($ApiKey.Substring(0, 4))$("*" * 20)"
} else {
    Write-Host "❌ Failed to set GEMINI_API_KEY environment variable." -ForegroundColor Red
}

# Print usage instructions
Write-Host ""
Write-Host "The GEMINI_API_KEY environment variable is now set for this PowerShell session."
Write-Host "To verify, you can run this command:"
Write-Host "   Write-Host `"GEMINI_API_KEY is set: `$([bool]`$env:GEMINI_API_KEY)`""
Write-Host ""
Write-Host "To use this API key with your application, launch it from this PowerShell session."
Write-Host "For example:"
Write-Host "   python launch_super_alita.py"
Write-Host ""
Write-Host "Note: This environment variable will only be available in this PowerShell session."
Write-Host "      If you open a new terminal, you'll need to run this script again."
