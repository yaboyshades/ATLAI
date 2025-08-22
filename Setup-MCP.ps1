<#
  Setup-MCP.ps1
  Clean remastered lifecycle manager for a Python MCP server + VS Code integrations.

  Commands:
    -Bootstrap           Creates .venv, MCP server skeleton, pyproject, VS Code wiring.
    -Clean [-Force]      Removes generated folders/files (.venv, mcp_server/, .vscode/mcp.json if we created it).
    -SmokeTest           Runs basic checks and launches server briefly to validate stdio protocol.
    -AddTool -Name X     Scaffolds a new tool file under src/mcp_server/tools/X.py with a safe template.
    -Doctor              Prints environment and config health report.

  Requirements:
    - Windows PowerShell 5.1+ or PowerShell 7+
    - Python 3.10+ on PATH (py.exe supported)
#>

param(
  [switch]$Bootstrap,
  [switch]$Clean,
  [switch]$Force,
  [switch]$SmokeTest,
  [switch]$Doctor,
  [string]$AddTool
)

# -------------------------
# Utilities
# -------------------------
$ErrorActionPreference = 'Stop'

function Write-Section($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}
function Write-Info($msg)    { Write-Host "[INFO] $msg" -ForegroundColor Gray }
function Write-OK($msg)      { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)     { Write-Host "[ERR]  $msg" -ForegroundColor Red }

function Resolve-Python {
  Write-Info "Resolving Python 3.10+..."
  $py = ""
  try {
    $ver = & py --version 2>$null
    if ($LASTEXITCODE -eq 0 -and $ver -match "Python (\d+)\.(\d+)\.") {
      $maj = [int]$Matches[1]; $min = [int]$Matches[2]
      if ($maj -ge 3 -and $min -ge 10) { return "py -3" }
    }
  } catch {}
  try {
    $ver2 = & python --version 2>$null
    if ($LASTEXITCODE -eq 0 -and $ver2 -match "Python (\d+)\.(\d+)\.") {
      $maj2 = [int]$Matches[1]; $min2 = [int]$Matches[2]
      if ($maj2 -ge 3 -and $min2 -ge 10) { return "python" }
    }
  } catch {}
  throw "Python 3.10+ not found on PATH. Install from python.org and retry."
}

$Root = (Get-Location).Path
$VenvPath = Join-Path $Root ".venv"
$ServerRoot = Join-Path $Root "mcp_server"
$SrcRoot = Join-Path $ServerRoot "src" "mcp_server"
$ToolsDir = Join-Path $SrcRoot "tools"
$VSCodeDir = Join-Path $Root ".vscode"
$McpJsonPath = Join-Path $VSCodeDir "mcp.json"
$FlagCreatedMcpJson = Join-Path $VSCodeDir ".mcp_json.created.flag"

function Ensure-Dirs {
  New-Item -ItemType Directory -Force -Path $ServerRoot, $SrcRoot, $ToolsDir | Out-Null
  New-Item -ItemType Directory -Force -Path $VSCodeDir | Out-Null
}

function Ensure-Venv {
  param([string]$PythonCmd)
  if (Test-Path $VenvPath) { Write-Info "Virtualenv exists"; return }
  Write-Section "Creating virtual environment"
  iex "$PythonCmd -m venv `"$VenvPath`""
  Write-OK "Created .venv"
}

function Venv-Python {
  if ($IsWindows -or $env:OS -eq "Windows_NT") { return Join-Path $VenvPath "Scripts\python.exe" }
  else { return Join-Path $VenvPath "bin/python" }
}

function Pip-Install {
  param([string[]]$Pkgs)
  $py = Venv-Python
  & $py -m pip install --upgrade pip | Out-Null
  $args = $Pkgs -join ' '
  Write-Info "Installing: $args"
  & $py -m pip install @Pkgs
}

function Write-IfMissing {
  param([string]$Path, [string]$Content, [string]$Label)
  if (Test-Path $Path) { Write-Info "$Label exists ($Path)"; return }
  New-Item -ItemType File -Path $Path -Force | Out-Null
  Set-Content -Path $Path -Value $Content -Encoding UTF8
  Write-OK "Created $Label ($Path)"
}

# -------------------------
# File content templates
# -------------------------
$PyProject = @"
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "mcp-server-example"
version = "0.2.0"
requires-python = ">=3.10"
dependencies = [
  "mcp>=1.2.0",   # adjust if needed
  "black>=24.0",
  "ruff>=0.5",
  "libcst>=1.4"
]

[project.optional-dependencies]
dev = [
  "pytest>=7.0.0"
]

[tool.black]
line-length = 88
target-version = ["py310"]

[tool.ruff]
target-version = "py310"
line-length = 88
select = ["E", "W", "F", "I", "B", "C4", "UP", "SIM"]
fix = true

[tool.pytest.ini_options]
addopts = "-q"
testpaths = ["tests"]
"@

$InitPy = @"
# mcp_server package marker
"@

$ServerPy = @"
from __future__ import annotations

import argparse
import importlib
import pkgutil
import sys
from typing import List

from mcp.server.fastmcp import FastMCP

# Dynamic tool loader: import all modules in mcp_server.tools
def load_tools() -> List[str]:
    imported = []
    import mcp_server.tools as tools_pkg
    for mod in pkgutil.iter_modules(tools_pkg.__path__, tools_pkg.__name__ + "."):
        imported.append(mod.name)
        importlib.import_module(mod.name)
    return imported

app = FastMCP("myCustomPythonAgent")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--transport", choices=["stdio", "sse"], default="stdio")
    args = parser.parse_args()

    loaded = load_tools()
    # Register tools decorated with @app.tool() in loaded modules
    # FastMCP auto-discovers @app.tool() methods defined with the same app instance.
    # Ensure your tool modules import `app` from this module: `from mcp_server.server import app`
    if args.transport == "stdio":
        app.run(transport="stdio")
    else:
        print("SSE transport not configured", file=sys.stderr)
        sys.exit(2)

if __name__ == "__main__":
    main()
"@

$ToolsInit = @"
# tools package marker
"@

$ToolsExample = @"
from __future__ import annotations
import asyncio
from pathlib import Path
from typing import Any, Dict

from mcp_server.server import app

def _is_subpath(base: Path, candidate: Path) -> bool:
    try:
        candidate.relative_to(base)
        return True
    except ValueError:
        return False

@app.tool(
    name="format_and_lint_selection",
    description="Run Ruff (fix) then Black on a path. Args: target_path (str). Returns stdout/stderr JSON."
)
async def format_and_lint_selection(target_path: str) -> Dict[str, str]:
    root = Path.cwd().resolve()
    p = Path(target_path).resolve()
    if not _is_subpath(root, p):
        return {"stdout": "", "stderr": "Path outside workspace denied."}
    async def _run(cmd: list[str]) -> tuple[str, str, int]:
        proc = await asyncio.create_subprocess_exec(*cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        out, err = await proc.communicate()
        return out.decode(), err.decode(), proc.returncode

    out1, err1, _ = await _run([str(Path('.venv/Scripts/python.exe' if (Path('.venv')/ 'Scripts').exists() else 'python')), "-m", "ruff", "check", str(p), "--fix"])
    out2, err2, _ = await _run([str(Path('.venv/Scripts/python.exe' if (Path('.venv')/ 'Scripts').exists() else 'python')), "-m", "black", str(p)])
    return {"stdout": out1 + out2, "stderr": err1 + err2}

@app.tool(
    name="find_missing_docstrings",
    description="Scan *.py for functions missing docstrings. Args: root (str), include_tests (bool=false)."
)
async def find_missing_docstrings(root: str, include_tests: bool = False) -> Dict[str, Any]:
    base = Path(root).resolve()
    ws = Path.cwd().resolve()
    if not base.exists() or not _is_subpath(ws, base):
        return {"functions": [], "count": 0, "error": "Invalid or unsafe root"}
    results = []
    for py in base.rglob("*.py"):
        if not include_tests and "tests" in py.parts:
            continue
        try:
            text = py.read_text(encoding="utf-8")
        except Exception:
            continue
        lines = text.splitlines()
        for i, line in enumerate(lines, start=1):
            s = line.strip()
            if s.startswith("def ") and "def __" not in s:
                look = "\n".join(lines[i:i+5])
                if '"""' not in look and "'''" not in look:
                    name = s.split("(")[0].replace("def", "").strip()
                    results.append({"file": str(py), "line": i, "name": name})
    return {"functions": results, "count": len(results)}
"@

$Readme = @"
# MCP Server (VS Code Agent Integration)

## Run locally
```
./mcp_server/.venv/Scripts/python.exe -m mcp_server.server --transport stdio
```

## Add a new tool
Use the script:
```
pwsh ./Setup-MCP.ps1 -AddTool MyToolName
```

Then in your new file, import `app`:
```python
from mcp_server.server import app

@app.tool(name="your_tool", description="...")
async def your_tool(...):
    ...
```
"@

$VSCodeMcpJson = @"
{
  "servers": {
    "myCustomPythonAgent": {
      "type": "stdio",
      "command": "`${workspaceFolder}/mcp_server/.venv/Scripts/python.exe",
      "args": [
        "`${workspaceFolder}/mcp_server/src/mcp_server/server.py",
        "--transport",
        "stdio"
      ],
      "env": {
        "MCP_AGENT_API_KEY": "`${input:agent-api-key}"
      },
      "inputs": [
        {
          "id": "agent-api-key",
          "type": "secret",
          "description": "API Key for My Custom Agent (optional)",
          "prompt": "Enter the API key (optional)",
          "required": false
        }
      ],
      "cwd": "`${workspaceFolder}/mcp_server"
    }
  }
}
"@

$VSCodeSettings = @"
{
  "python.defaultInterpreterPath": "`${workspaceFolder}/mcp_server/.venv/Scripts/python.exe",
  "python.terminal.activateEnvironment": true,
  "python.analysis.typeCheckingMode": "strict",
  "ruff.enable": true,
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports.ruff": "explicit",
      "source.fixAll.ruff": "explicit"
    }
  },
  "files.watcherExclude": {
    "**/.venv/**": true,
    "**/__pycache__/**": true,
    "**/.ruff_cache/**": true
  }
}
"@

# -------------------------
# Operations
# -------------------------

function Do-Bootstrap {
  Write-Section "Bootstrap: MCP server + VS Code wiring"
  $python = Resolve-Python
  Ensure-Dirs
  Ensure-Venv -PythonCmd $python

  # Dependencies (server-local)
  Pip-Install @("mcp>=1.2.0", "black>=24.0", "ruff>=0.5", "libcst>=1.4", "pytest>=7.0.0")

  # Files
  Write-IfMissing -Path (Join-Path $ServerRoot "pyproject.toml") -Content $PyProject -Label "pyproject.toml"
  Write-IfMissing -Path (Join-Path $SrcRoot "__init__.py") -Content $InitPy -Label "src/mcp_server/__init__.py"
  Write-IfMissing -Path (Join-Path $SrcRoot "server.py") -Content $ServerPy -Label "src/mcp_server/server.py"
  Write-IfMissing -Path (Join-Path $ToolsDir "__init__.py") -Content $ToolsInit -Label "src/mcp_server/tools/__init__.py"
  Write-IfMissing -Path (Join-Path $ToolsDir "format_and_scan.py") -Content $ToolsExample -Label "src/mcp_server/tools/format_and_scan.py"
  Write-IfMissing -Path (Join-Path $ServerRoot "README.md") -Content $Readme -Label "mcp_server/README.md"

  # VS Code integration
  if (-not (Test-Path $McpJsonPath)) {
    Set-Content -Path $McpJsonPath -Value $VSCodeMcpJson -Encoding UTF8
    Set-Content -Path $FlagCreatedMcpJson -Value "created" -Encoding UTF8
    Write-OK "Created .vscode/mcp.json"
  } else {
    Write-Info ".vscode/mcp.json exists (left untouched)"
  }
  $settingsPath = Join-Path $VSCodeDir "settings.json"
  if (-not (Test-Path $settingsPath)) {
    Set-Content -Path $settingsPath -Value $VSCodeSettings -Encoding UTF8
    Write-OK "Created .vscode/settings.json"
  } else {
    Write-Info ".vscode/settings.json exists (left untouched)"
  }

  Write-OK "Bootstrap complete."
  Write-Host "`nNext:"
  Write-Host "  1) Open VS Code Insiders in this folder"
  Write-Host "  2) Use command: MCP: Show Installed Servers (verify myCustomPythonAgent)"
  Write-Host "  3) In Copilot Chat, switch to Agent and call your tools."
}

function Do-Clean {
  Write-Section "Clean generated artifacts"
  if (Test-Path $VenvPath) {
    if (-not $Force) { Write-Warn "Remove .venv? Use -Force to confirm."; } else { Remove-Item -Recurse -Force $VenvPath; Write-OK "Removed .venv" }
  } else { Write-Info ".venv not found" }

  if (Test-Path $ServerRoot) {
    if (-not $Force) { Write-Warn "Remove mcp_server/? Use -Force to confirm."; }
    else { Remove-Item -Recurse -Force $ServerRoot; Write-OK "Removed mcp_server/" }
  } else { Write-Info "mcp_server/ not found" }

  if ((Test-Path $FlagCreatedMcpJson) -and (Test-Path $McpJsonPath)) {
    if (-not $Force) { Write-Warn "Remove .vscode/mcp.json (created by script)? Use -Force."; }
    else { Remove-Item -Force $McpJsonPath; Remove-Item -Force $FlagCreatedMcpJson; Write-OK "Removed .vscode/mcp.json" }
  } else {
    Write-Info "Skipping .vscode/mcp.json removal (not created by this script or not present)"
  }
  Write-OK "Clean complete."
}

function Do-SmokeTest {
  Write-Section "Smoke test"
  $py = Venv-Python
  if (-not (Test-Path $py)) { Write-Err "Missing .venv; run -Bootstrap first."; return }

  # Quick import test
  iex "`"$py`" -c `"import mcp_server.server as s; print('TOOL_MODULES', s.load_tools())`""

  # Launch stdio briefly (2s)
  Write-Info "Launching server (2s)..."
  $p = Start-Process -FilePath $py -ArgumentList "$ServerRoot\src\mcp_server\server.py --transport stdio" -PassThru
  Start-Sleep -Seconds 2
  if (!$p.HasExited) { $p.Kill() }
  Write-OK "Server launched and terminated successfully."
}

function Do-Doctor {
  Write-Section "Doctor"
  try {
    $pycmd = Resolve-Python
    Write-OK "Python resolver: $pycmd"
  } catch { Write-Err $_.Exception.Message }
  if (Test-Path $VenvPath) { Write-OK ".venv present" } else { Write-Warn ".venv missing" }
  if (Test-Path (Join-Path $ServerRoot "pyproject.toml")) { Write-OK "mcp_server/pyproject.toml present" } else { Write-Warn "pyproject.toml missing" }
  if (Test-Path $McpJsonPath) { Write-OK ".vscode/mcp.json present" } else { Write-Warn "mcp.json missing" }
  Write-Info "Try: MCP: Show Installed Servers in VS Code"
}

function Do-AddTool {
  param([string]$Name)
  if (-not $Name -or $Name -notmatch "^[A-Za-z_][A-Za-z0-9_]*$") {
    throw "Provide a valid Python identifier: -AddTool MyNewTool"
  }
  $file = Join-Path $ToolsDir ("{0}.py" -f ($Name.ToLower()))
  if (Test-Path $file) { Write-Warn "Tool file exists: $file"; return }

  $content = @"
from __future__ import annotations
from typing import Any, Dict
from pathlib import Path

from mcp_server.server import app

@app.tool(
    name="$Name",
    description="Describe what $Name does, required args, and return shape."
)
async def $Name(example_arg: str) -> Dict[str, Any]:
    """Short doc for humans & LLM.
    Args:
        example_arg: what it is.

    Returns:
        dict with structured result for the client.
    """
    # TODO: implement. Keep scope narrow. Validate inputs.
    return {"ok": True, "arg": example_arg}
"@
  Set-Content -Path $file -Value $content -Encoding UTF8
  Write-OK "Created tool: $file"
  Write-Host "Next: call it from Copilot Agent Mode: $Name(example_arg='value')"
}

# -------------------------
# Dispatch
# -------------------------

if ($Bootstrap) { Do-Bootstrap }
elseif ($Clean) { Do-Clean }
elseif ($SmokeTest) { Do-SmokeTest }
elseif ($Doctor) { Do-Doctor }
elseif ($AddTool) { Do-AddTool -Name $AddTool }
else {
  Write-Host @"
Usage:
  pwsh ./Setup-MCP.ps1 -Bootstrap
  pwsh ./Setup-MCP.ps1 -SmokeTest
  pwsh ./Setup-MCP.ps1 -AddTool MyTool
  pwsh ./Setup-MCP.ps1 -Doctor
  pwsh ./Setup-MCP.ps1 -Clean -Force
"@
    Write-Err "No valid command provided. Use -Bootstrap, -SmokeTest, -AddTool, -Doctor, or -Clean."
}
# SIG # Begin signature block
# MIIaSQYJKoZIhvcNAQcCoIIaOjCCGjYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEsfzioLvPBDsp
# h02/ZY+7ovw7rDYsoV6+u8bAnC+t4qCCFRswggHdMIIBRqADAgECAhB1LVe8LkJa
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgHJxNAZZ+OosUfhWpIoMU
# pPtZulQXN1xqZoEj+YDBeSYwDQYJKoZIhvcNAQEBBQAEgYCaGW2IyIEBJ7Ew5rNV
# QaAygdMtfUJR0caDm9UfCuBh26E0AoC45LFpanj3RF3u3MtDgsDr6BIxtEPPxAAv
# CHzHnNgXwxVCjH748ZbXuWNZQxc3xhbid+4hyZBSGq8CUUdt+Ymu7VWTVEcly3y5
# 1kADBCRmaC4rzCzP2UMsOazL86GCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA4
# MTkyMjMwMDNaMC8GCSqGSIb3DQEJBDEiBCA88/Rifj51EN9ilieiWvhYVXBuZU2N
# kh4ByRJk6kdOkjANBgkqhkiG9w0BAQEFAASCAgAA2GtK2DOg+VAb6audloFpnDXj
# cP8W7bomBBX2Ou46rdw0a8FSr8bvQjK9utVfO1clqBkM7GUiXO6UX2JO5p/u8e+d
# ZtPJ6N0BGo8m/Hs8YCWW06e95olO9i6atg9vOeVcCpzholZyqZUpJ89KE43Uv0ki
# gmFoS4lMekkCdqgXp1sn+tv3briw9C5fSjeUWs968HYQ+XwJB0HT+SJTh5DixwgX
# ZuGegaBMUKw2E9nR/2lbO8eDJPwL8Fi5kiWrpv4fE5IF1jdXuvPNI5I3AMZeCacT
# hex4cVkdQOlqYb4q0EJBAu4Xb3LecIdOtlCp4HWoLFzqotfKLTC7MjZ+Oj9am/IM
# 5k8oRB9gMKsn6CKNC1FiTovK5zHSOCmuRAV3hBaMdoOTY+C5dh7FrFaHyN/HvTnw
# UHeb2Kex7iBnISgBEQ1O8bgrluF6dNDHjc0hY8FrfEvvPMzImFLTY403OTipFwdA
# Yr+93WV4ph0K1hRjK7lonsG80sMSuZPHE0mz4oS/oCdS8mV3NPO/F+VU/PVUWCqN
# N0Y1eWWDwpodKUEWPW6r6DNjA1cH7XBYPfGWAfcj1iVQx1jiQI6zTHnl6ywu1DPc
# uKTMAI5aoJFtxuoO+dMnP4uASO72MFjp+akvpspUFkKa9XWpY5v4Y9VJB8+yWpKs
# u1Nz+xJTBwN2LIFL6w==
# SIG # End signature block
