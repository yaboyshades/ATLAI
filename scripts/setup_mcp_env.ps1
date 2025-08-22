# scripts/setup_mcp_env.ps1
# Windows-friendly bootstrap for: Python MCP Server + Copilot Agent Mode + VS Code Insiders wiring
# - Creates src/mcp_server with a minimal stdio MCP server + tools
# - Adds VS Code settings, tasks, and MCP config
# - Adds pyproject (Black, Ruff, Pytest, Mypy), pre-commit, and EditorConfig
# - Creates .venv and installs dependencies
# - Adds a tiny test and README
# Re-run safely (idempotent). Requires: Python 3.11+ recommended (3.12/3.13 OK).

$ErrorActionPreference = "Stop"

function Ensure-Dir {
  param([string]$Path)
  if (!(Test-Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
}

# 1) Directories
Ensure-Dir ".vscode"
Ensure-Dir "src\mcp_bootstrap_server"
Ensure-Dir "scripts"
Ensure-Dir ".github"
Ensure-Dir "tests"

# 2) .editorconfig
@'
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true
max_line_length = 88

[*.py]
indent_size = 4

[*.{yml,yaml}]
indent_size = 2
'@ | Set-Content -Encoding UTF8 ".editorconfig"

# 3) pyproject.toml (single root config; src/ is the package root)
@'
[build-system]
requires = ["setuptools>=69", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "mcp-workspace"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
  "mcp>=1.0.0",          # MCP SDK (stdio server)
  "black>=24.3.0",
  "ruff>=0.5.0",
  "mypy>=1.10.0",
  "pytest>=8.0.0",
  "libcst>=1.4.0"
]
dynamic = ["readme"]

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.packages.find]
where = ["src"]

[tool.black]
line-length = 88
target-version = ["py311","py312","py313"]

[tool.ruff]
target-version = "py311"
line-length = 88
# pycodestyle/pyflakes/isort/bugbear/comprehensions/upgrade/python-simplify/pytest
select = ["E","W","F","I","B","C4","UP","SIM","PT"]
ignore = ["E501"]  # handled by Black
fix = true
unsafe-fixes = false

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["S101", "T20"]

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true
warn_unreachable = true
warn_redundant_casts = true

[tool.pytest.ini_options]
minversion = "8.0"
addopts = "-ra -q"
testpaths = ["tests"]
'@ | Set-Content -Encoding UTF8 "pyproject.toml"

# 4) pre-commit
@'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/psf/black
    rev: 24.3.0
    hooks:
      - id: black

  - repo: local
    hooks:
      - id: python-compile-check
        name: python-compile-check
        entry: python -m py_compile
        language: system
        types: [python]
'@ | Set-Content -Encoding UTF8 ".pre-commit-config.yaml"

# 5) VS Code settings.json + tasks.json + mcp.json
@'
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/Scripts/python.exe",
  "python.terminal.activateEnvironment": true,
  "python.analysis.typeCheckingMode": "strict",
  "python.analysis.autoImportCompletions": true,
  "python.analysis.completeFunctionParens": true,
  "python.analysis.inlayHints.variableTypes": true,
  "python.analysis.inlayHints.functionReturnTypes": true,
  "python.analysis.inlayHints.pytestParameters": true,

  "ruff.enable": true,
  "ruff.organizeImports": true,
  "ruff.fixAll": true,

  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports.ruff": "explicit",
      "source.fixAll.ruff": "explicit"
    }
  },

  "files.autoSave": "onFocusChange",

  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.venv/**": true,
    "**/__pycache__/**": true,
    "**/.ruff_cache/**": true
  },
  "search.exclude": {
    "**/.venv/**": true,
    "**/node_modules/**": true,
    "**/*.pyc": true
  },

  "workbench.extensionHost.maxMemory": 4096
}
'@ | Set-Content -Encoding UTF8 ".vscode\settings.json"

@'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Python: Compile Check (current file)",
      "type": "shell",
      "command": "${config:python.defaultInterpreterPath}",
      "args": ["-m", "py_compile", "${file}"],
      "group": "build",
      "problemMatcher": [{
        "owner": "python",
        "fileLocation": "relative",
        "pattern": {
          "regexp": "^\\s*File \\\"(.*)\\\", line (\\d+)",
          "file": 1,
          "line": 2
        }
      }]
    },
    {
      "label": "Python: Tabnanny (workspace)",
      "type": "shell",
      "command": "${config:python.defaultInterpreterPath}",
      "args": ["-m", "tabnanny", "${workspaceFolder}"],
      "group": "build"
    },
    {
      "label": "Full Check & Fix",
      "dependsOrder": "sequence",
      "dependsOn": [
        "Python: Compile Check (current file)",
        "Python: Tabnanny (workspace)"
      ],
      "group": { "kind": "build", "isDefault": true }
    }
  ]
}
'@ | Set-Content -Encoding UTF8 ".vscode\tasks.json"

@'
{
  "servers": {
    "myCustomPythonAgent": {
      "type": "stdio",
      "command": "${workspaceFolder}/.venv/Scripts/python.exe",
      "args": [
        "${workspaceFolder}/src/mcp_bootstrap_server/server.py"
      ],
      "env": {
        "MCP_AGENT_API_KEY": "${input:agent-api-key}"
      },
      "inputs": [
        {
          "id": "agent-api-key",
          "type": "secret",
          "description": "API Key for Custom Agent (optional)",
          "prompt": "Enter the API key",
          "required": false
        }
      ],
      "cwd": "${workspaceFolder}"
    }
  }
}
'@ | Set-Content -Encoding UTF8 ".vscode\mcp.json"

# 6) MCP server package files

# __init__.py
@'
"""mcp_bootstrap_server package."""
'@ | Set-Content -Encoding UTF8 "src\mcp_bootstrap_server\__init__.py"

# result_types.py (simple Result container if you expand later)
@'
from __future__ import annotations
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E")

@dataclass(slots=True)
class Result(Generic[T, E]):
    ok: bool
    value: T | None = None
    error: E | None = None

    @classmethod
    def Ok(cls, value: T) -> "Result[T, E]":
        return cls(ok=True, value=value)

    @classmethod
    def Err(cls, error: E) -> "Result[T, E]":
        return cls(ok=False, error=error)
'@ | Set-Content -Encoding UTF8 "src\mcp_bootstrap_server\result_types.py"

# ast_utils.py (stubbed transform & diff)
@'
from __future__ import annotations
from difflib import unified_diff

def rewrite_function_to_result(src: str, function_name: str) -> tuple[str | None, str | None]:
    # TODO: Replace with a real libcst transform.
    if f"def {function_name}(" not in src:
        return None, "Function not found"
    new_src = src  # placeholder; no-op transform for demo
    diff = "".join(
        unified_diff(
            src.splitlines(keepends=True),
            new_src.splitlines(keepends=True),
            fromfile="a.py",
            tofile="b.py",
        )
    )
    return new_src, diff
'@ | Set-Content -Encoding UTF8 "src\mcp_bootstrap_server\ast_utils.py"

# tools.py
@'
from __future__ import annotations
import asyncio
from pathlib import Path
from typing import Any, Dict, List, Tuple

from .ast_utils import rewrite_function_to_result

async def _run(cmd: list[str], cwd: Path | None = None) -> tuple[str, str, int]:
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        cwd=str(cwd) if cwd else None,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    out, err = await proc.communicate()
    return out.decode(), err.decode(), proc.returncode

async def refactor_to_result(file_path: str, function_name: str, dry_run: bool = True) -> Dict[str, Any]:
    p = Path(file_path).resolve()
    if not p.exists() or p.suffix != ".py":
        return {"applied": False, "diff": "", "error": "Invalid Python file path."}

    original = p.read_text(encoding="utf-8")
    rewritten, diff = rewrite_function_to_result(original, function_name=function_name)
    if not rewritten:
        return {"applied": False, "diff": diff or "", "error": "Function not found or transform failed."}

    if not dry_run:
        p.write_text(rewritten, encoding="utf-8")
    return {"applied": not dry_run, "diff": diff or ""}

async def format_and_lint(target_path: str) -> Dict[str, str]:
    # Ruff fix first, then Black
    out1, err1, _ = await _run(["python", "-m", "ruff", "check", target_path, "--fix"])
    out2, err2, _ = await _run(["python", "-m", "black", target_path])
    return {"stdout": out1 + out2, "stderr": err1 + err2}

async def find_missing_docstrings(root: str, include_tests: bool = False) -> Dict[str, Any]:
    base = Path(root).resolve()
    if not base.exists():
        return {"functions": [], "count": 0, "error": "Root path does not exist."}

    results: list[dict[str, Any]] = []
    for py in base.rglob("*.py"):
        if not include_tests and ("tests" in py.parts):
            continue
        text = py.read_text(encoding="utf-8", errors="ignore")
        lines = text.splitlines()
        for i, line in enumerate(lines, start=1):
            s = line.strip()
            if s.startswith("def ") and "def __" not in s:
                # look ahead a few lines for a docstring
                snippet = "\n".join(lines[i:i+5])
                if '"""' not in snippet and "'''" not in snippet:
                    name = s.split("(")[0].replace("def", "").strip()
                    results.append({"file": str(py), "line": i, "name": name})
    return {"functions": results, "count": len(results)}
'@ | Set-Content -Encoding UTF8 "src\mcp_server\tools.py"

# server.py
@'
from __future__ import annotations
import logging
from typing import Any, Dict

from mcp.server.fastmcp import FastMCP, tool  # part of MCP Python SDK
from .tools import refactor_to_result, format_and_lint, find_missing_docstrings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp_server")

app = FastMCP("myCustomPythonAgent")

@tool(
    name="apply_result_pattern_refactor",
    description=(
        "Refactor a Python function to a Result-returning pattern. "
        "Args: file_path (str), function_name (str), dry_run (bool, default true). "
        "Returns JSON: {'applied': bool, 'diff': str, 'error': Optional[str]}."
    ),
)
async def apply_result_pattern_refactor(file_path: str, function_name: str, dry_run: bool = True) -> Dict[str, Any]:
    return await refactor_to_result(file_path=file_path, function_name=function_name, dry_run=dry_run)

@tool(
    name="format_and_lint_selection",
    description=(
        "Run Ruff (fix) and Black on a path. "
        "Args: target_path (str). Returns JSON: {'stdout': str, 'stderr': str}."
    ),
)
async def format_and_lint_selection(target_path: str) -> Dict[str, str]:
    return await format_and_lint(target_path=target_path)

@tool(
    name="find_missing_docstrings",
    description=(
        "Find functions missing docstrings under a root dir. "
        "Args: root (str), include_tests (bool, default false). "
        "Returns JSON: {'functions': [{'file': str, 'line': int, 'name': str}], 'count': int}."
    ),
)
async def find_missing_docstrings_tool(root: str, include_tests: bool = False) -> Dict[str, Any]:
    return await find_missing_docstrings(root=root, include_tests=include_tests)

def main() -> None:
    transport = "stdio"  # VS Code launches this as a subprocess
    logger.info("Starting MCP server (transport=%s)", transport)
    app.run(transport=transport)

if __name__ == "__main__":
    main()
'@ | Set-Content -Encoding UTF8 "src\mcp_server\server.py"

# 7) Copilot instructions (optional but helpful)
@'
# Project DNA for Copilot & Agent Mode

- Follow pyproject.toml: Black 88, Ruff selected rules; no wildcard imports.
- Use type hints everywhere; prefer dataclasses where suitable.
- Use pathlib.Path, not os.path.
- For refactors, prefer AST/libcst transforms; never regex patch code.
- Tests: pytest; parametrize edge cases; no prints.

## MCP tools
- Default to `dry_run=true`; return unified diffs for review.
- Never modify files outside ${workspaceFolder}.
- Assume Windows paths; normalize/resolve before file ops.
'@ | Set-Content -Encoding UTF8 ".github\copilot-instructions.md"

# 8) Tests
@'
def test_smoke():
    assert True
'@ | Set-Content -Encoding UTF8 "tests\test_smoke.py"

# 9) README
@'
# MCP + Copilot Agent Mode (VS Code Insiders)

## Quickstart
1. Create venv and install deps:
```
.\.venv\Scripts\python -m pip install -U pip
.\.venv\Scripts\pip install -e .
.\.venv\Scripts\pre-commit install
```
2. Open in VS Code **Insiders**. Trust the workspace.
3. Ensure Python interpreter = `.venv\Scripts\python.exe`.
4. Run command: **MCP: Show Installed Servers** (should list `myCustomPythonAgent`).
5. In Copilot Chat, switch **Mode: Agent**. Try prompts:
   - `find_missing_docstrings root=src include_tests=false`
   - `format_and_lint_selection target_path=src`
   - `apply_result_pattern_refactor file_path=path\to\file.py function_name=foo dry_run=true`

## Notes
- Tools favor `dry_run` to show diffs first.
- Ruff runs before Black for stable formatting.
- For big repos, narrow targets (folders/files) for speed.
'@ | Set-Content -Encoding UTF8 "README.md"

# 10) Python venv & install
Write-Host "Creating virtual environment (.venv)..." -ForegroundColor Cyan
if (!(Test-Path ".venv")) {
py -3 -m venv .venv
}
$python = ".\.venv\Scripts\python.exe"
$pip = ".\.venv\Scripts\pip.exe"

Write-Host "Upgrading pip..." -ForegroundColor Cyan
& $python -m pip install -U pip

Write-Host "Installing project in editable mode..." -ForegroundColor Cyan
& $pip install -e .

Write-Host "Installing pre-commit..." -ForegroundColor Cyan
& $pip install pre-commit

Write-Host "Installing pre-commit hook..." -ForegroundColor Cyan
& .\.venv\Scripts\pre-commit.exe install

Write-Host "`nAll set! Next:" -ForegroundColor Green
Write-Host "1) Open with VS Code **Insiders**."
Write-Host "2) Ensure interpreter is .venv\\Scripts\\python.exe (status bar)."
Write-Host "3) Run: MCP: Show Installed Servers -> verify myCustomPythonAgent."
Write-Host "4) In Copilot Chat, switch Mode: Agent and try a tool call." -ForegroundColor Yello
# SIG # Begin signature block
# MIIaSQYJKoZIhvcNAQcCoIIaOjCCGjYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAWfNpv+fqsCFcU
# 8HkJSUyJ7lp3ExJGklZn805N2/ejCKCCFRswggHdMIIBRqADAgECAhB1LVe8LkJa
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg0vkzqAQEqMQwDPkpRRL/
# Of+5pSi+4YYr/mjYW0FBLgEwDQYJKoZIhvcNAQEBBQAEgYBFytlmMkO/BAlFge/g
# ofs4EFvB3rOo+vasRkExm6FYdIMZv3yU28LGzDv7Nn01tM6VWg1FVSVxeu8bEQx3
# WeG4Dvu4Trpf4nxOKoXm2uJM7ROLP/Dwxa0RashlBFk4VJXCKKSMhCFxpD8jc9J2
# +c6olarhrTVQN5o7c7ghwmOThKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIB
# ATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8G
# A1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBT
# SEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA4
# MTkyMTQyMzFaMC8GCSqGSIb3DQEJBDEiBCAN5Ul6E+4KcyWqrSj4gCVo4VD1LpEx
# pGYsrp4OfsACfjANBgkqhkiG9w0BAQEFAASCAgCmgW5/+cr+gVg540E2cwXmzUzC
# UO1zEW/cbVdKa6EFXq7VVoKQm7rJuu8junSow6CEIvUf4eDrbITISW0FqGZ29Ifn
# /4l1Oz3FFJBHJIATM1BNB56ypo7uDXOYk+aEb8a6gHpK8o2lSH/SFpAcTBVA7jBO
# z4eKfXzO+RBP2o6+jpDfAjHtYPST9jesM4cYoMZfEnL5odPJveEJ3fV7wmIErfbt
# o7rdEvzvXjMowClvakUGNKATNw1WNRFpQ5CZK04W9z0mLNXu98GcuFtKULuk/hWa
# EEq7I72uBHUPiTrpFlKAK+9OAuav40oQPZLUshG1opR0IkWQy7HnM5lzMZuasrPr
# ExXzaH8vhwny1+0dkOXmkErvwuUrIqDPxGpRcfTjtb+5Y1pd4LSR7flmUvQk3/GA
# Hn1hXAbnFnU47nSv/qHjWdCK2+Sbb/Kv62I2uSRsdSZq6VNAs1ofVdHIc1PPcQKh
# u6KrgPmwWXVuJafCjHKBJ7uFdiJlSIFwMtJl6JLlruhLO+tonmM/wgLl1EuiUnAh
# yaU0iQZWiMryZvswsk6BReQrGxgELKVBEcUCgcwAlFhyydzJMPRtpWveZB1qiC0S
# QsTfpKS/D1Cc25eykwn5bKOZuONhw8uESqxmqWAXwMRdAe4TsEgKZsGn1Yv9ua+8
# pSdaP7cRHDhzQtYgzg==
# SIG # End signature block
