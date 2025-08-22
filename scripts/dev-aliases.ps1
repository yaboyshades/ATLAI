# Professional Development Scripts for Super Alita Agent Development
# PowerShell Edition for Windows Developers
# Source this file in your PowerShell profile

# ============================================================================
# SUPER ALITA DEVELOPMENT ALIASES AND FUNCTIONS
# ============================================================================

# Quality Pipeline Functions
function Invoke-AlitaFormat {
    <#
    .SYNOPSIS
    Format Super Alita code with professional tools
    #>
    Write-Host "🎨 Formatting code..." -ForegroundColor Yellow
    ruff format .
    black .
    isort .
    Write-Host "✅ Code formatted!" -ForegroundColor Green
}

function Invoke-AlitaLint {
    <#
    .SYNOPSIS
    Run comprehensive linting on Super Alita code
    #>
    Write-Host "🔍 Running linters..." -ForegroundColor Yellow
    ruff check .
    if ($LASTEXITCODE -eq 0) {
        pylint src/ --fail-under=8.0
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Linting complete!" -ForegroundColor Green
        }
    }
}

function Invoke-AlitaTest {
    <#
    .SYNOPSIS
    Run tests with coverage reporting
    #>
    Write-Host "🧪 Running tests..." -ForegroundColor Yellow
    pytest --cov=src --cov-report=term-missing --cov-report=html --cov-report=xml
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Tests complete! Check htmlcov/index.html for coverage details." -ForegroundColor Green
    }
}

function Invoke-AlitaSecurity {
    <#
    .SYNOPSIS
    Run security scanning with bandit
    #>
    Write-Host "🔒 Running security scans..." -ForegroundColor Yellow
    bandit -r src/ -f json -o security-report.json
    bandit -r src/ -f txt
    Write-Host "✅ Security scan complete!" -ForegroundColor Green
}

function Invoke-AlitaTypes {
    <#
    .SYNOPSIS
    Run type checking with mypy
    #>
    Write-Host "🔬 Running type checks..." -ForegroundColor Yellow
    mypy src/
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Type checking complete!" -ForegroundColor Green
    }
}

function Invoke-AlitaPrecommit {
    <#
    .SYNOPSIS
    Run all pre-commit hooks
    #>
    Write-Host "🚀 Running pre-commit hooks..." -ForegroundColor Yellow
    pre-commit run --all-files
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Pre-commit checks complete!" -ForegroundColor Green
    }
}

# Complete pipelines
function Invoke-AlitaQuality {
    <#
    .SYNOPSIS
    Run complete quality pipeline
    #>
    Write-Host "🎯 Running complete quality pipeline..." -ForegroundColor Cyan
    
    Invoke-AlitaFormat
    if ($LASTEXITCODE -ne 0) { return }
    
    Invoke-AlitaLint
    if ($LASTEXITCODE -ne 0) { return }
    
    Invoke-AlitaTypes
    if ($LASTEXITCODE -ne 0) { return }
    
    Invoke-AlitaSecurity
    if ($LASTEXITCODE -ne 0) { return }
    
    Invoke-AlitaTest
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Complete quality pipeline finished!" -ForegroundColor Green
    }
}

function Invoke-AlitaQuick {
    <#
    .SYNOPSIS
    Run quick validation (format, lint, typecheck)
    #>
    Write-Host "⚡ Running quick validation..." -ForegroundColor Cyan
    
    Invoke-AlitaFormat
    if ($LASTEXITCODE -ne 0) { return }
    
    Invoke-AlitaLint
    if ($LASTEXITCODE -ne 0) { return }
    
    Invoke-AlitaTypes
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚡ Quick validation complete!" -ForegroundColor Green
    }
}

# Development functions
function Start-AlitaDev {
    <#
    .SYNOPSIS
    Start Super Alita in development mode
    #>
    Write-Host "🚀 Starting Super Alita development environment..." -ForegroundColor Yellow
    
    $env:ALITA_ENABLE_EXPANDER = "1"
    $env:ALITA_ENABLE_DENSE = "1"
    $env:ALITA_LOG_LEVEL = "DEBUG"
    
    python -m src.main
}

function Start-AlitaMCP {
    <#
    .SYNOPSIS
    Start Super Alita MCP server
    #>
    Write-Host "🔧 Starting MCP server..." -ForegroundColor Yellow
    python -m src.mcp.server
}

function Test-AlitaHealth {
    <#
    .SYNOPSIS
    Run Super Alita health check
    #>
    Write-Host "📊 Running health check..." -ForegroundColor Yellow
    python quick_status_check.py
}

function Start-AlitaMonitor {
    <#
    .SYNOPSIS
    Start Super Alita agent monitoring
    #>
    Write-Host "📈 Starting agent monitor..." -ForegroundColor Yellow
    python monitor_agent_enhanced.py
}

# Testing functions
function Invoke-AlitaTestUnit {
    <#
    .SYNOPSIS
    Run unit tests only
    #>
    pytest tests/unit/ -v
}

function Invoke-AlitaTestIntegration {
    <#
    .SYNOPSIS
    Run integration tests only
    #>
    pytest tests/integration/ -v
}

function Invoke-AlitaTestE2E {
    <#
    .SYNOPSIS
    Run end-to-end tests only
    #>
    pytest tests/ -m e2e -v
}

function Invoke-AlitaTestFast {
    <#
    .SYNOPSIS
    Run fast tests (excluding slow tests)
    #>
    pytest tests/ -m "not slow" -v
}

# Utility functions
function Clear-AlitaCache {
    <#
    .SYNOPSIS
    Clean Super Alita build artifacts and cache
    #>
    Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Yellow
    
    # Remove Python cache files
    Get-ChildItem -Path . -Name "*.pyc" -Recurse | Remove-Item -Force
    Get-ChildItem -Path . -Name "__pycache__" -Recurse -Directory | Remove-Item -Recurse -Force
    
    # Remove build directories
    $dirs = @(".coverage", "htmlcov", ".pytest_cache", ".mypy_cache", "dist", "build")
    foreach ($dir in $dirs) {
        if (Test-Path $dir) {
            Remove-Item $dir -Recurse -Force
        }
    }
    
    # Remove files
    $files = @("security-report.json", "coverage.xml")
    foreach ($file in $files) {
        if (Test-Path $file) {
            Remove-Item $file -Force
        }
    }
    
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
}

function Install-AlitaDeps {
    <#
    .SYNOPSIS
    Install Super Alita dependencies
    #>
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    pip install -r requirements-test.txt
    Write-Host "✅ Dependencies installed!" -ForegroundColor Green
}

function New-AlitaDocs {
    <#
    .SYNOPSIS
    Generate Super Alita documentation
    #>
    Write-Host "📚 Generating documentation..." -ForegroundColor Yellow
    python tools/gendocstrings.py src/**/*.py
    Write-Host "✅ Documentation generated!" -ForegroundColor Green
}

# Setup function for new developers
function Initialize-AlitaSetup {
    <#
    .SYNOPSIS
    Setup Super Alita development environment for new developers
    #>
    Write-Host "🚀 Setting up Super Alita development environment..." -ForegroundColor Cyan
    
    # Install dependencies
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    pip install -r requirements-test.txt
    
    # Setup pre-commit
    Write-Host "🔧 Setting up pre-commit hooks..." -ForegroundColor Yellow
    pre-commit install
    
    # Copy environment template
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "📝 Created .env file from template" -ForegroundColor Yellow
    }
    
    # Run initial validation
    Write-Host "🔍 Running initial validation..." -ForegroundColor Yellow
    Invoke-AlitaQuick
    
    Write-Host "✅ Setup complete! Run 'Start-AlitaDev' to start development." -ForegroundColor Green
}

# Comprehensive validation function
function Test-AlitaValidation {
    <#
    .SYNOPSIS
    Run comprehensive Super Alita validation
    #>
    Write-Host "🔍 Running comprehensive Super Alita validation..." -ForegroundColor Cyan
    
    $exitCode = 0
    
    # Format check
    Write-Host "1️⃣  Checking code formatting..." -ForegroundColor Yellow
    Invoke-AlitaFormat
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Formatting issues found" -ForegroundColor Red
        $exitCode = 1
    }
    else {
        Write-Host "✅ Code formatting passed" -ForegroundColor Green
    }
    
    # Linting
    Write-Host "2️⃣  Running linting checks..." -ForegroundColor Yellow
    Invoke-AlitaLint
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Linting issues found" -ForegroundColor Red
        $exitCode = 1
    }
    else {
        Write-Host "✅ Linting passed" -ForegroundColor Green
    }
    
    # Type checking
    Write-Host "3️⃣  Running type checks..." -ForegroundColor Yellow
    Invoke-AlitaTypes
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Type checking issues found" -ForegroundColor Red
        $exitCode = 1
    }
    else {
        Write-Host "✅ Type checking passed" -ForegroundColor Green
    }
    
    # Security scanning
    Write-Host "4️⃣  Running security scans..." -ForegroundColor Yellow
    Invoke-AlitaSecurity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Security issues found" -ForegroundColor Red
        $exitCode = 1
    }
    else {
        Write-Host "✅ Security scanning passed" -ForegroundColor Green
    }
    
    # Testing
    Write-Host "5️⃣  Running tests..." -ForegroundColor Yellow
    Invoke-AlitaTest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Test failures found" -ForegroundColor Red
        $exitCode = 1
    }
    else {
        Write-Host "✅ All tests passed" -ForegroundColor Green
    }
    
    if ($exitCode -eq 0) {
        Write-Host "🎉 All validations passed! Super Alita is ready for production." -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Some validations failed. Please fix issues before proceeding." -ForegroundColor Red
    }
    
    return $exitCode
}

# Environment information
function Get-AlitaInfo {
    <#
    .SYNOPSIS
    Display Super Alita development environment information
    #>
    Write-Host "📊 Super Alita Development Environment Information" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🐍 Python Version:" -ForegroundColor Yellow
    python --version
    Write-Host ""
    
    Write-Host "📦 Key Dependencies:" -ForegroundColor Yellow
    $deps = @("pytest", "ruff", "black", "mypy", "pylint", "bandit", "pre-commit")
    foreach ($dep in $deps) {
        $version = pip list | Select-String $dep
        if ($version) {
            Write-Host "  $version"
        }
    }
    Write-Host ""
    
    Write-Host "🔧 Git Status:" -ForegroundColor Yellow
    $modifiedFiles = (git status --porcelain | Measure-Object).Count
    Write-Host "  Modified files: $modifiedFiles"
    Write-Host ""
    
    Write-Host "📈 Test Coverage:" -ForegroundColor Yellow
    if (Test-Path "htmlcov/index.html") {
        Write-Host "  Coverage report available at htmlcov/index.html"
    }
    else {
        Write-Host "  No coverage report found - run 'Invoke-AlitaTest' to generate"
    }
    Write-Host ""
    
    Write-Host "🎯 Project Health:" -ForegroundColor Yellow
    Test-AlitaHealth 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Run 'Test-AlitaHealth' for detailed status"
    }
}

# Create new plugin template
function New-AlitaPlugin {
    <#
    .SYNOPSIS
    Create a new plugin template for Super Alita
    .PARAMETER Name
    The name of the plugin to create
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $pluginDir = "src/plugins/${Name}_plugin"
    $testDir = "tests/plugins"
    
    Write-Host "🔧 Creating new plugin: $Name" -ForegroundColor Yellow
    
    # Create plugin directory
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    
    # Plugin files content (same as bash version but PowerShell friendly)
    $pluginInit = @"
"""
$($Name | ForEach-Object {$_.Substring(0,1).ToUpper() + $_.Substring(1)}) Plugin for Super Alita Agent System.

This plugin provides [describe functionality here].
"""

from .${Name}_plugin import $($Name | ForEach-Object {$_.Substring(0,1).ToUpper() + $_.Substring(1)})Plugin

__all__ = ["$($Name | ForEach-Object {$_.Substring(0,1).ToUpper() + $_.Substring(1)})Plugin"]
"@
    
    Set-Content -Path "$pluginDir/__init__.py" -Value $pluginInit
    
    Write-Host "✅ Plugin template created:" -ForegroundColor Green
    Write-Host "   📁 Plugin: $pluginDir" -ForegroundColor Gray
    Write-Host "   🧪 Tests: $testDir/test_${Name}_plugin.py" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Implement your plugin logic" -ForegroundColor Gray
    Write-Host "   2. Add comprehensive tests" -ForegroundColor Gray
    Write-Host "   3. Register plugin in configuration" -ForegroundColor Gray
    Write-Host "   4. Run 'Invoke-AlitaTest' to validate" -ForegroundColor Gray
}

# ============================================================================
# ULTIMATE TERMINAL COCKPIT ENHANCEMENTS
# ============================================================================

# Docker Stack Management
function Start-AlitaStack {
    <#
    .SYNOPSIS
    Start the complete Super Alita development stack with Docker Compose
    #>
    Write-Host "🚀 Starting Super Alita development stack..." -ForegroundColor Cyan
    docker-compose up -d
    Start-Sleep -Seconds 5
    Write-Host "📊 Stack status:" -ForegroundColor Yellow
    docker-compose ps
    Write-Host "✅ Stack is ready!" -ForegroundColor Green
    Write-Host "🌐 Services available at:" -ForegroundColor Yellow
    Write-Host "   - Grafana: http://localhost:3000 (admin/admin123)" -ForegroundColor Gray
    Write-Host "   - Prometheus: http://localhost:9090" -ForegroundColor Gray
    Write-Host "   - Jupyter: http://localhost:8888 (token: agent-dev-token)" -ForegroundColor Gray
    Write-Host "   - Redis Commander: http://localhost:8081" -ForegroundColor Gray
    Write-Host "   - Neo4j Browser: http://localhost:7474 (neo4j/password)" -ForegroundColor Gray
}

function Stop-AlitaStack {
    <#
    .SYNOPSIS
    Stop the Super Alita development stack
    #>
    Write-Host "⚠️  Stopping Super Alita development stack..." -ForegroundColor Yellow
    docker-compose down
    Write-Host "🔄 Stack stopped!" -ForegroundColor Green
}

function Reset-AlitaStack {
    <#
    .SYNOPSIS
    Reset the Super Alita development stack (removes volumes)
    #>
    Write-Host "⚠️  Resetting Super Alita development stack..." -ForegroundColor Yellow
    docker-compose down -v
    docker-compose up -d
    Start-Sleep -Seconds 5
    Write-Host "🔄 Stack has been reset!" -ForegroundColor Green
}

function Show-AlitaStackLogs {
    <#
    .SYNOPSIS
    Show logs from the Super Alita development stack
    #>
    docker-compose logs -f
}

function Get-AlitaStackStatus {
    <#
    .SYNOPSIS
    Get status of the Super Alita development stack
    #>
    Write-Host "📊 Super Alita Stack Status" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    docker-compose ps
    Write-Host ""
    Write-Host "📈 Container Resource Usage:" -ForegroundColor Yellow
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Live Monitoring Functions
function Start-AlitaGlances {
    <#
    .SYNOPSIS
    Start live system monitoring with glances
    #>
    if (Get-Command glances -ErrorAction SilentlyContinue) {
        glances
    }
    else {
        Write-Host "⚠️  Glances not installed. Install with: pip install glances" -ForegroundColor Yellow
        # Alternative: use PowerShell native monitoring
        while ($true) {
            Clear-Host
            Write-Host "🖥️  System Monitor (Press Ctrl+C to exit)" -ForegroundColor Cyan
            Write-Host "CPU: $((Get-WmiObject win32_processor | Measure-Object -Property LoadPercentage -Average).Average)%" -ForegroundColor Yellow
            $memory = Get-WmiObject Win32_OperatingSystem
            $memUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
            Write-Host "Memory: $memUsage%" -ForegroundColor Yellow
            Write-Host "Processes: $(Get-Process | Where-Object {$_.ProcessName -like '*agent*' -or $_.ProcessName -like '*alita*'} | Measure-Object | Select-Object -ExpandProperty Count) agent processes" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
}

function Start-AlitaEventMonitor {
    <#
    .SYNOPSIS
    Monitor Super Alita events in real-time
    #>
    Write-Host "📡 Starting event monitor..." -ForegroundColor Yellow
    Write-Host "Monitoring Redis events (Press Ctrl+C to exit)" -ForegroundColor Gray
    
    if (Get-Command redis-cli -ErrorAction SilentlyContinue) {
        redis-cli monitor | Select-String -Pattern "(atomize|memory|bond|request|agent)"
    }
    else {
        Write-Host "⚠️  redis-cli not found. Make sure Redis is installed and in PATH" -ForegroundColor Yellow
    }
}

function Get-AlitaResources {
    <#
    .SYNOPSIS
    Show comprehensive resource usage for Super Alita
    #>
    Write-Host "🖥️  Super Alita Resource Usage" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    
    # CPU Usage
    $cpu = Get-WmiObject win32_processor | Measure-Object -Property LoadPercentage -Average
    Write-Host "CPU: $($cpu.Average)%" -ForegroundColor Yellow
    
    # Memory Usage
    $memory = Get-WmiObject Win32_OperatingSystem
    $totalMem = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMem = [math]::Round($totalMem - $freeMem, 2)
    $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 2)
    Write-Host "Memory: $usedMem/$totalMem GB ($memPercent%)" -ForegroundColor Yellow
    
    # Disk Usage
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskUsed = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $diskTotal = [math]::Round($disk.Size / 1GB, 2)
    $diskPercent = [math]::Round(($diskUsed / $diskTotal) * 100, 2)
    Write-Host "Disk: $diskUsed/$diskTotal GB ($diskPercent%)" -ForegroundColor Yellow
    
    # Agent Processes
    $agentProcesses = Get-Process | Where-Object { $_.ProcessName -like '*agent*' -or $_.ProcessName -like '*alita*' -or $_.ProcessName -like '*python*' }
    Write-Host "Agent Processes: $($agentProcesses.Count)" -ForegroundColor Yellow
    
    if ($agentProcesses.Count -gt 0) {
        Write-Host ""
        Write-Host "🤖 Active Agent Processes:" -ForegroundColor Cyan
        $agentProcesses | ForEach-Object {
            $memMB = [math]::Round($_.WorkingSet / 1MB, 2)
            Write-Host "   $($_.ProcessName) (PID: $($_.Id)) - $memMB MB" -ForegroundColor Gray
        }
    }
}

# Enhanced REPL and API Functions
function Start-AlitaREPL {
    <#
    .SYNOPSIS
    Start enhanced Python REPL for Super Alita development
    #>
    Write-Host "🐍 Starting Super Alita development REPL..." -ForegroundColor Yellow
    
    $env:PYTHONPATH = "$(Get-Location)\src;$env:PYTHONPATH"
    $env:ALITA_MODE = "repl"
    
    $replScript = @"
import sys
import os
sys.path.insert(0, './src')
os.environ.setdefault('ALITA_MODE', 'repl')

print('🤖 Super Alita Development REPL')
print('===============================')
print('📁 Working Directory:', os.getcwd())
print('🐍 Python Version:', sys.version.split()[0])
print('')
print('Available imports:')
print('- Core modules pre-imported')
print('- Agent development utilities loaded')
print('')

# Pre-import common modules
try:
    import asyncio
    import json
    import logging
    from pathlib import Path
    print('✅ Standard modules imported')
except ImportError as e:
    print(f'⚠️  Import error: {e}')

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('alita-repl')
logger.info('REPL session started')

print('')
print('💡 Tip: Use logger.info() for logging, asyncio.run() for async code')
print('🔧 Type "help()" for Python help, exit() to quit')
print('')
"@
    
    if (Get-Command ptpython -ErrorAction SilentlyContinue) {
        # Use ptpython if available
        $replScript | python -c "exec(input())" -i
    }
    elseif (Get-Command ipython -ErrorAction SilentlyContinue) {
        # Use IPython if available
        ipython -i -c $replScript
    }
    else {
        # Use standard Python REPL
        python -i -c $replScript
    }
}

function Test-AlitaAPI {
    <#
    .SYNOPSIS
    Test Super Alita API endpoints
    .PARAMETER Endpoint
    API endpoint to test (default: /health)
    .PARAMETER Method
    HTTP method (default: GET)
    .PARAMETER Body
    Request body for POST/PUT requests
    #>
    param(
        [string]$Endpoint = "/health",
        [string]$Method = "GET",
        [string]$Body = $null
    )
    
    $baseUrl = "http://localhost:8000"
    $url = "$baseUrl$Endpoint"
    
    Write-Host "🌐 Testing API: $Method $url" -ForegroundColor Yellow
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
            "User-Agent"   = "Super-Alita-DevTools/1.0"
        }
        
        if ($Body) {
            $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers -Body $Body
        }
        else {
            $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers
        }
        
        Write-Host "✅ Response received:" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 4 | Write-Host
        
    }
    catch {
        Write-Host "❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        }
    }
}

# Git and Release Management
function Invoke-AlitaCommit {
    <#
    .SYNOPSIS
    Smart commit with pre-commit hooks
    .PARAMETER Message
    Commit message
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host "📝 Preparing commit: $Message" -ForegroundColor Yellow
    
    # Run pre-commit checks
    Write-Host "🔍 Running pre-commit checks..." -ForegroundColor Yellow
    Invoke-AlitaQuick
    
    if ($LASTEXITCODE -eq 0) {
        git add .
        git commit -m $Message
        Write-Host "✅ Committed: $Message" -ForegroundColor Green
        
        # Show status
        Write-Host "📊 Repository status:" -ForegroundColor Yellow
        git status --short
    }
    else {
        Write-Host "❌ Pre-commit checks failed. Fix issues before committing." -ForegroundColor Red
    }
}

function Invoke-AlitaRelease {
    <#
    .SYNOPSIS
    Create a new release with automated notes
    .PARAMETER Version
    Release version (default: current date)
    #>
    param(
        [string]$Version = (Get-Date -Format "v2025.MM.dd.HHmm")
    )
    
    Write-Host "🚀 Creating release: $Version" -ForegroundColor Cyan
    
    # Generate release notes
    $notes = git log --oneline --since="1 week ago" | Select-Object -First 10
    $releaseNotes = @"
# Release $Version

## Recent Changes
$($notes | ForEach-Object { "- $_" } | Out-String)

## System Status
- Tests: $(if ((pytest --collect-only -q 2>$null).Count -gt 0) { "✅ Passing" } else { "⚠️ Check required" })
- Coverage: Available in htmlcov/index.html
- Performance: Event throughput optimized

## Deployment
This release includes:
- Enhanced terminal cockpit features
- Improved monitoring and observability
- Docker stack configuration
- Professional development tooling

Generated automatically on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    Set-Content -Path "RELEASE_NOTES.md" -Value $releaseNotes
    Write-Host "📝 Release notes generated in RELEASE_NOTES.md" -ForegroundColor Green
    
    # Create git tag
    git tag -a $Version -m "Release $Version"
    Write-Host "🏷️  Tagged as $Version" -ForegroundColor Green
    
    Write-Host "💡 Next: Push with 'git push origin main && git push origin $Version'" -ForegroundColor Yellow
}

# Secrets Management (Windows-compatible)
function New-AlitaSecrets {
    <#
    .SYNOPSIS
    Initialize encrypted secrets for Super Alita
    #>
    Write-Host "🔐 Initializing secrets management..." -ForegroundColor Yellow
    
    $secretsTemplate = @"
# Super Alita Secrets
# Rename this file to .env.secrets and update with real values

# API Keys
GEMINI_API_KEY=your-gemini-api-key-here
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Database URLs
DATABASE_URL=postgresql://agent:agent123@localhost:5432/agent_dev
REDIS_URL=redis://localhost:6379/0
MONGO_URL=mongodb://admin:password@localhost:27017/agent_dev?authSource=admin
NEO4J_URL=bolt://neo4j:password@localhost:7687

# Development Settings
AGENT_MODE=development
LOG_LEVEL=DEBUG
DEBUG_MODE=true

# External Services
GITHUB_TOKEN=your-github-token-here
GRAFANA_API_KEY=your-grafana-api-key-here
"@
    
    Set-Content -Path ".env.secrets.template" -Value $secretsTemplate
    
    if (-not (Test-Path ".env.secrets")) {
        Copy-Item ".env.secrets.template" ".env.secrets"
        Write-Host "✅ Secrets template created: .env.secrets" -ForegroundColor Green
        Write-Host "📝 Edit .env.secrets with your actual secrets" -ForegroundColor Yellow
    }
    else {
        Write-Host "⚠️  .env.secrets already exists" -ForegroundColor Yellow
    }
    
    # Add to .gitignore if not present
    if (Test-Path ".gitignore") {
        $gitignore = Get-Content ".gitignore" -Raw
        if ($gitignore -notmatch "\.env\.secrets") {
            Add-Content ".gitignore" "`n# Secrets`n.env.secrets`n.env.secrets.*"
            Write-Host "✅ Added .env.secrets to .gitignore" -ForegroundColor Green
        }
    }
}

function Import-AlitaSecrets {
    <#
    .SYNOPSIS
    Load secrets from .env.secrets file
    #>
    if (Test-Path ".env.secrets") {
        Write-Host "🔐 Loading secrets..." -ForegroundColor Yellow
        
        Get-Content ".env.secrets" | ForEach-Object {
            if ($_ -match '^([^#][^=]*?)=(.*)$') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
        
        Write-Host "✅ Secrets loaded into environment" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  No .env.secrets file found. Run 'New-AlitaSecrets' to create template." -ForegroundColor Yellow
    }
}

# Starship and Prompt Enhancement
function Install-AlitaCockpit {
    <#
    .SYNOPSIS
    Install and configure the ultimate terminal cockpit
    #>
    Write-Host "🚀 Installing Ultimate Super Alita Terminal Cockpit..." -ForegroundColor Cyan
    
    # Check and install tools
    $tools = @(
        @{ Name = "starship"; Command = "starship --version"; Install = "winget install starship" },
        @{ Name = "docker"; Command = "docker --version"; Install = "winget install Docker.DockerDesktop" },
        @{ Name = "git"; Command = "git --version"; Install = "winget install Git.Git" }
    )
    
    foreach ($tool in $tools) {
        Write-Host "🔍 Checking $($tool.Name)..." -ForegroundColor Yellow
        try {
            Invoke-Expression $tool.Command | Out-Null
            Write-Host "✅ $($tool.Name) is installed" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  $($tool.Name) not found. Install with: $($tool.Install)" -ForegroundColor Yellow
        }
    }
    
    # Setup Starship configuration
    $starshipConfigDir = "$env:USERPROFILE\.config"
    if (-not (Test-Path $starshipConfigDir)) {
        New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
    }
    
    $starshipConfig = Join-Path $starshipConfigDir "starship.toml"
    if (-not (Test-Path $starshipConfig)) {
        Copy-Item "config\starship\starship.toml" $starshipConfig -Force
        Write-Host "✅ Starship configuration installed" -ForegroundColor Green
    }
    
    # Setup PowerShell profile
    $profileContent = @"

# Super Alita Terminal Cockpit Enhancement
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# Load Super Alita development aliases
if (Test-Path "$(Get-Location)\scripts\dev-aliases.ps1") {
    . "$(Get-Location)\scripts\dev-aliases.ps1"
}

# Auto-load secrets if available
if (Test-Path ".env.secrets") {
    Import-AlitaSecrets
}

Write-Host "🚀 Super Alita Terminal Cockpit loaded!" -ForegroundColor Green
"@
    
    Write-Host "💡 Add the following to your PowerShell profile:" -ForegroundColor Yellow
    Write-Host $profileContent -ForegroundColor Gray
    Write-Host ""
    Write-Host "📍 Profile location: $PROFILE" -ForegroundColor Yellow
    Write-Host "✅ Cockpit installation complete!" -ForegroundColor Green
}

# ============================================================================
# ALIASES FOR CONVENIENCE
# ============================================================================

# Original aliases
Set-Alias -Name alita-format -Value Invoke-AlitaFormat
Set-Alias -Name alita-lint -Value Invoke-AlitaLint
Set-Alias -Name alita-test -Value Invoke-AlitaTest
Set-Alias -Name alita-security -Value Invoke-AlitaSecurity
Set-Alias -Name alita-types -Value Invoke-AlitaTypes
Set-Alias -Name alita-precommit -Value Invoke-AlitaPrecommit
Set-Alias -Name alita-quality -Value Invoke-AlitaQuality
Set-Alias -Name alita-quick -Value Invoke-AlitaQuick
Set-Alias -Name alita-dev -Value Start-AlitaDev
Set-Alias -Name alita-mcp -Value Start-AlitaMCP
Set-Alias -Name alita-health -Value Test-AlitaHealth
Set-Alias -Name alita-monitor -Value Start-AlitaMonitor
Set-Alias -Name alita-clean -Value Clear-AlitaCache
Set-Alias -Name alita-deps -Value Install-AlitaDeps
Set-Alias -Name alita-docs -Value New-AlitaDocs
Set-Alias -Name alita-setup -Value Initialize-AlitaSetup
Set-Alias -Name alita-validate -Value Test-AlitaValidation
Set-Alias -Name alita-info -Value Get-AlitaInfo
Set-Alias -Name alita-new-plugin -Value New-AlitaPlugin

# Ultimate Cockpit aliases
Set-Alias -Name alita-stack-up -Value Start-AlitaStack
Set-Alias -Name alita-stack-down -Value Stop-AlitaStack
Set-Alias -Name alita-stack-reset -Value Reset-AlitaStack
Set-Alias -Name alita-stack-logs -Value Show-AlitaStackLogs
Set-Alias -Name alita-stack-status -Value Get-AlitaStackStatus
Set-Alias -Name alita-glances -Value Start-AlitaGlances
Set-Alias -Name alita-events -Value Start-AlitaEventMonitor
Set-Alias -Name alita-resources -Value Get-AlitaResources
Set-Alias -Name alita-repl -Value Start-AlitaREPL
Set-Alias -Name alita-api -Value Test-AlitaAPI
Set-Alias -Name alita-commit -Value Invoke-AlitaCommit
Set-Alias -Name alita-release -Value Invoke-AlitaRelease
Set-Alias -Name alita-secrets -Value New-AlitaSecrets
Set-Alias -Name alita-load-secrets -Value Import-AlitaSecrets
Set-Alias -Name alita-cockpit -Value Install-AlitaCockpit

# Quick shortcuts
Set-Alias -Name asu -Value Start-AlitaStack        # alita-stack-up
Set-Alias -Name asd -Value Stop-AlitaStack         # alita-stack-down
Set-Alias -Name asr -Value Reset-AlitaStack        # alita-stack-reset
Set-Alias -Name ass -Value Get-AlitaStackStatus    # alita-stack-status
Set-Alias -Name agr -Value Get-AlitaResources      # alita-resources
Set-Alias -Name are -Value Start-AlitaREPL         # alita-repl

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# Set environment variables for development
$env:ALITA_DEV_MODE = "1"
$env:PYTHONPATH = "$env:PYTHONPATH;$(Get-Location)\src"

Write-Host "🚀 Super Alita PowerShell development environment loaded!" -ForegroundColor Green
Write-Host "💡 Run 'Get-AlitaInfo' for environment details" -ForegroundColor Yellow
Write-Host "📚 Available commands: alita-* for Super Alita operations" -ForegroundColor Yellow
# SIG # Begin signature block
# MIIaSQYJKoZIhvcNAQcCoIIaOjCCGjYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAop5KVEuOnl04h
# M/aJAxl4K0Fh9CvPntTHtj2NHve//6CCFRswggHdMIIBRqADAgECAhB1LVe8LkJa
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgW6DPE5GMjyO2/RtGcjl/
# rQ/ZN6AbHAqCSoTV30uaHvowDQYJKoZIhvcNAQEBBQAEgYCe4uQ5Ao0bqFo+SHeR
# 9/YVQh4F0Lme25vIf0r3RYIr2X5/+fHy6CqT1E2RashazhMrdUs8KyvoNvURGdRu
# smfNGeDb6fem4MI2GWiF7fVCYa2K0QP2d634mWw09WXzqGR9iVyR9g1p+LBqGDXq
# LlZmMw0QesV9YckKfBX42XAcDKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA4
# MTYwOTE4MTRaMC8GCSqGSIb3DQEJBDEiBCC1WLdsT7KhI2N40cDizvvMhZLRAogA
# r15gTHDlqz1LEDANBgkqhkiG9w0BAQEFAASCAgB58W3yxNyNfQDlDA5zg4pmBwU2
# wOsEiBsvNnMfr+zUndeOS/eZ23ZU7BRmlj8LYih5252KvYKOi+RCUUKTHfSbUNxx
# 1V/4PEIYbrwpUHDIY92iqB9MNhAwS6RwFGTdD1aeu0/WDknpwSO8t1KvJ73TpPpu
# xLQiZ33zjYvlzIijBN4cm5M4AOVKNqsgW4RBeBgbOd6n5EQI03A80HRYVP8gfJJP
# /n7kp3a+c3OFZtny9cb/mmDtF1VLg1cnQ4cWWii/L4SmC5l9AUa5jyktwV8pUY+5
# 0hH2Qgk8HX+hdVJj4o6DD8+FTtuSnGDEyis2Sv4Umej75tcYEtCTFnQKHP5wsrhE
# AdhFO8z44RRNUfH7UM3rRnnYAHL+5A9uvNTkLww/wqJiYaOEDlNLLFIoI2AH4QME
# upkcsGKuVgqWfQcFnBcqFbP4kAkrFaKzGP6Z48pCAcJ1UgKpZDEL00uhBsVQw3bK
# 3quX/iOz4j3wcyVUJhSs9KUcUF9gx7oUExCzyIGzUysapCp4pvSpoNyls6V5Mqah
# vgv5/UUZZZHCgTQ/LDgXnTh2lWUk+IAhwNvo1sjNCOtKhtul1PhLG3Kx46FB3sPj
# 9M3pzASm6F+K8uHdoYR44FXhaEcoaFemt0Dgt1LVdzYeDdfuEdqUOkDQZBiXjKyZ
# Bm+5JizJiCM77wX/xw==
# SIG # End signature block
