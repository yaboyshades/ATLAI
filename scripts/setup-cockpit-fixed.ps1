#!/usr/bin/env pwsh
# 🚀 Ultimate Terminal Cockpit Setup Script for Super Alita

param(
    [switch]$All,
    [switch]$InstallTools,
    [switch]$ConfigureProfile,
    [switch]$SetupDocker,
    [switch]$Verbose
)

if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "🚀 ULTIMATE TERMINAL COCKPIT SETUP" -ForegroundColor Cyan
Write-Host "Setting up Super Alita development environment..." -ForegroundColor Yellow
Write-Host ""

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "🔧 $Message" -ForegroundColor Cyan
}

function Install-Tools {
    Write-Info "Installing core development tools..."
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing tools via winget..."
        
        try {
            winget install --id Starship.Starship -e --accept-source-agreements --accept-package-agreements
            Write-Success "Starship prompt installed"
        }
        catch {
            Write-Warning "Starship installation failed or already installed"
        }
        
        try {
            if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
                winget install --id Docker.DockerDesktop -e --accept-source-agreements --accept-package-agreements
                Write-Success "Docker Desktop installed"
            }
            else {
                Write-Success "Docker Desktop already available"
            }
        }
        catch {
            Write-Warning "Docker Desktop installation failed or already installed"
        }
    }
    else {
        Write-Warning "winget not available. Please install tools manually"
    }
    
    Write-Info "Installing Python development tools..."
    try {
        pip install ptpython ipython jupyter glances --upgrade --quiet
        Write-Success "Python tools installed"
    }
    catch {
        Write-Warning "Some Python tools may have failed to install"
    }
}

function Setup-StarshipConfig {
    Write-Info "Configuring Starship prompt..."
    
    $starshipConfigDir = "$env:USERPROFILE\.config"
    $starshipConfigPath = "$starshipConfigDir\starship.toml"
    $sourceConfigPath = "config\starship\starship.toml"
    
    if (-not (Test-Path $starshipConfigDir)) {
        New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
        Write-Success "Created Starship config directory"
    }
    
    if (Test-Path $sourceConfigPath) {
        Copy-Item $sourceConfigPath $starshipConfigPath -Force
        Write-Success "Starship configuration copied to user profile"
    }
    else {
        Write-Warning "Starship config file not found at $sourceConfigPath"
    }
}

function Setup-PowerShellProfile {
    Write-Info "Configuring PowerShell profile..."
    
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    $profileContent = @"
# Super Alita Ultimate Terminal Cockpit Profile
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

if (Test-Path "`$PWD\scripts\dev-aliases.ps1") {
    . "`$PWD\scripts\dev-aliases.ps1"
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Write-Host "Super Alita: Ready for Development" -ForegroundColor Green
Write-Host "Enhanced with Copilot Integration" -ForegroundColor Cyan
"@

    if (Test-Path $PROFILE) {
        $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $PROFILE $backupPath
        Write-Success "Existing profile backed up to $backupPath"
    }
    
    $profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force
    Write-Success "PowerShell profile configured"
}

function Setup-Secrets {
    Write-Info "Setting up secrets management..."
    
    $secretsTemplate = ".env.secrets.template"
    $secretsFile = ".env.secrets"
    
    if (-not (Test-Path $secretsTemplate)) {
        $templateContent = @"
# Super Alita Secrets Configuration
GEMINI_API_KEY=your_gemini_api_key_here
GITHUB_TOKEN=your_github_token_here
OPENAI_API_KEY=your_openai_api_key_here
REDIS_URL=redis://localhost:6379
MONGODB_URL=mongodb://localhost:27017/super_alita
NEO4J_URL=bolt://localhost:7687
POSTGRES_URL=postgresql://postgres:agent-dev@localhost:5432/super_alita
GRAFANA_ADMIN_PASSWORD=admin123
PROMETHEUS_CONFIG_PATH=./config/prometheus/prometheus.yml
ALITA_LOG_LEVEL=DEBUG
ALITA_ENV=development
JUPYTER_TOKEN=agent-dev-token
"@
        $templateContent | Out-File -FilePath $secretsTemplate -Encoding UTF8
        Write-Success "Secrets template created: $secretsTemplate"
    }
    
    if (-not (Test-Path $secretsFile)) {
        Copy-Item $secretsTemplate $secretsFile
        Write-Success "Secrets file created: $secretsFile"
    }
    else {
        Write-Success "Secrets file already exists: $secretsFile"
    }
}

function Setup-Docker {
    Write-Info "Configuring Docker development stack..."
    
    try {
        docker version | Out-Null
        Write-Success "Docker is running and accessible"
    }
    catch {
        Write-Warning "Docker is not running or not installed"
        return
    }
    
    if (Test-Path "docker-compose.yml") {
        try {
            docker-compose config | Out-Null
            Write-Success "Docker Compose configuration is valid"
        }
        catch {
            Write-Warning "Docker Compose configuration has issues"
        }
    }
    else {
        Write-Warning "docker-compose.yml not found"
    }
    
    try {
        docker network create super-alita-network 2>$null
        Write-Success "Docker network ready"
    }
    catch {
        Write-Success "Docker network already exists"
    }
}

function Test-Installation {
    Write-Info "Testing installation..."
    
    $tests = @(
        @{ Name = "PowerShell Profile"; Test = { Test-Path $PROFILE } },
        @{ Name = "Starship Config"; Test = { Test-Path "$env:USERPROFILE\.config\starship.toml" } },
        @{ Name = "Secrets Template"; Test = { Test-Path ".env.secrets.template" } },
        @{ Name = "Docker Access"; Test = { try { docker version >$null; $true } catch { $false } } }
    )
    
    Write-Host ""
    Write-Host "🧪 Installation Test Results:" -ForegroundColor Cyan
    
    foreach ($test in $tests) {
        $result = & $test.Test
        if ($result) {
            Write-Success $test.Name
        }
        else {
            Write-Warning "$($test.Name) - Needs attention"
        }
    }
}

# Main execution
Write-Host "📋 Setup Options Selected:" -ForegroundColor Cyan
if ($All) { Write-Host "  ✅ Complete setup (all components)" -ForegroundColor Green }
if ($InstallTools -or $All) { Write-Host "  🔧 Install development tools" -ForegroundColor Yellow }
if ($ConfigureProfile -or $All) { Write-Host "  ⚙️  Configure PowerShell profile" -ForegroundColor Yellow }
if ($SetupDocker -or $All) { Write-Host "  🐳 Setup Docker environment" -ForegroundColor Yellow }

Write-Host ""

try {
    if ($InstallTools -or $All) {
        Install-Tools
        Write-Host ""
    }
    
    if ($ConfigureProfile -or $All) {
        Setup-StarshipConfig
        Setup-PowerShellProfile
        Setup-Secrets
        Write-Host ""
    }
    
    if ($SetupDocker -or $All) {
        Setup-Docker
        Write-Host ""
    }
    
    Test-Installation
    
    Write-Host ""
    Write-Host "🎉 ULTIMATE TERMINAL COCKPIT SETUP COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart PowerShell to activate the new profile" -ForegroundColor Yellow
    Write-Host "  2. Run 'docker-compose up -d' to start services" -ForegroundColor Yellow
    Write-Host "  3. Edit '.env.secrets' with your actual API keys" -ForegroundColor Yellow
    Write-Host "  4. Run 'alita-validate' to test the system" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🚀 Ready to develop with Super Alita!" -ForegroundColor Green
    
}
catch {
    Write-Host "❌ Setup failed with error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check the error and try again." -ForegroundColor Red
    exit 1
}
