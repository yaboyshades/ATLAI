param(
  [switch]$RecreateVenv = $true
)

if ($RecreateVenv) {
  if (Test-Path .venv) { Remove-Item -Recurse -Force .venv }
  py -3 -m venv .venv
}

. .\.venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
# Core dev tooling
pip install black ruff mypy pytest pre-commit
# MCP server deps
pip install -e ./mcp_server

pre-commit install
Write-Host "Dev environment ready."
