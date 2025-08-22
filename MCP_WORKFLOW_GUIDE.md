# MCP Server Workflow Guide

This document provides a comprehensive workflow for managing your Model Context Protocol (MCP) server with VS Code integration.

## 🚀 Quick Start

### Initial Setup
```powershell
# Bootstrap the entire environment
pwsh .\Setup-MCP.ps1 -Bootstrap
```

### Health Check
```powershell
# Verify environment status
pwsh .\Setup-MCP.ps1 -Doctor
```

### Expected Output:
```
=== Doctor ===
[OK]   Python resolver: py -3
[OK]   .venv present
[OK]   mcp_server/pyproject.toml present
[OK]   .vscode/mcp.json present
[INFO] Try: MCP: Show Installed Servers in VS Code
```

## 🛠️ Development Workflow

### 1. Adding New Tools
```powershell
# Create a new tool (e.g., MyNewTool)
pwsh .\Setup-MCP.ps1 -AddTool MyNewTool
```

**Expected Output:**
```
[OK] Created tool: D:\...\mcp_server\src\mcp_server\tools\mynewtool.py
Next: call it from Copilot Agent Mode: MyNewTool(example_arg='value')
```

**Generated Tool Template:**
```python
from __future__ import annotations
from typing import Any, Dict
from pathlib import Path

from mcp_server.server import app

@app.tool(
    name="MyNewTool",
    description="Describe what MyNewTool does, required args, and return shape."
)
async def MyNewTool(example_arg: str) -> Dict[str, Any]:
    """Short doc for humans & LLM.
    Args:
        example_arg: what it is.

    Returns:
        dict with structured result for the client.
    """
    # TODO: implement. Keep scope narrow. Validate inputs.
    return {"ok": True, "arg": example_arg}
```

### 2. Testing Tools
```powershell
# Run smoke test to verify server works
pwsh .\Setup-MCP.ps1 -SmokeTest
```

### 3. VS Code Integration
1. **Open VS Code Insiders** in the project folder
2. **Command Palette** → `MCP: Show Installed Servers`
3. Verify `myCustomPythonAgent` is listed
4. **Copilot Chat** → Switch to Agent Mode
5. Test your tools:
   ```
   MyNewTool(example_arg='test_value')
   format_and_lint_selection(target_path='src/example.py')
   find_missing_docstrings(root='src', include_tests=false)
   ```

## 🧹 Maintenance Commands

### Clean Environment
```powershell
# Clean all generated files (requires -Force)
pwsh .\Setup-MCP.ps1 -Clean -Force
```

### Environment Troubleshooting
```powershell
# Check current status
pwsh .\Setup-MCP.ps1 -Doctor

# Re-bootstrap if needed
pwsh .\Setup-MCP.ps1 -Bootstrap
```

## 📁 Project Structure

```
super-alita/
├── Setup-MCP.ps1           # Lifecycle manager script
├── .venv/                  # Virtual environment
├── .vscode/
│   ├── mcp.json           # MCP server configuration
│   └── settings.json      # VS Code settings
└── mcp_server/            # MCP server package
    ├── pyproject.toml     # Project configuration
    ├── README.md          # Server documentation
    └── src/mcp_server/
        ├── __init__.py
        ├── server.py      # Main server with dynamic tool loading
        └── tools/         # Tool modules directory
            ├── __init__.py
            ├── format_and_scan.py    # Built-in tools
            └── mynewtool.py         # Your custom tools
```

## 🔑 Key Features

### 1. **Dynamic Tool Loading**
- Tools are automatically discovered from `src/mcp_server/tools/`
- No need to manually register tools in server.py
- Import `app` from `mcp_server.server` in your tool files

### 2. **Environment Variable Integration**
- Gemini API key automatically loaded from `.env`
- Secure key management through VS Code MCP configuration

### 3. **Development Best Practices**
- Black formatting (88 line length)
- Ruff linting with selected rules
- Type hints enforced
- Pytest for testing

### 4. **VS Code Integration**
- Automatic Python interpreter configuration
- Format on save enabled
- Code actions for imports and linting
- MCP server auto-discovery

## 🔧 Tool Development Guidelines

### Best Practices:
1. **Keep tools focused** - One clear purpose per tool
2. **Validate inputs** - Always check user input for safety
3. **Path safety** - Use workspace-relative paths, validate against directory traversal
4. **Type hints** - Use proper type annotations
5. **Documentation** - Clear docstrings for humans and LLMs
6. **Error handling** - Return structured error responses

### Example Tool Pattern:
```python
from __future__ import annotations
import asyncio
from pathlib import Path
from typing import Any, Dict

from mcp_server.server import app

def _is_subpath(base: Path, candidate: Path) -> bool:
    """Safety check for path traversal."""
    try:
        candidate.relative_to(base)
        return True
    except ValueError:
        return False

@app.tool(
    name="my_secure_tool",
    description="Clear description of what this tool does and its parameters."
)
async def my_secure_tool(file_path: str, option: bool = False) -> Dict[str, Any]:
    """Tool that safely processes files.

    Args:
        file_path: Path to the file to process (workspace-relative)
        option: Optional flag to modify behavior

    Returns:
        dict with 'success', 'result', and optional 'error' keys
    """
    try:
        # Validate and resolve path
        workspace = Path.cwd().resolve()
        target = Path(file_path).resolve()

        if not _is_subpath(workspace, target):
            return {"success": False, "error": "Path outside workspace denied"}

        if not target.exists():
            return {"success": False, "error": f"File not found: {file_path}"}

        # Your tool logic here
        result = f"Processed {target.name} with option={option}"

        return {"success": True, "result": result}

    except Exception as e:
        return {"success": False, "error": str(e)}
```

## 🚨 Remember for AI Assistants

**Always use this workflow pattern when working with MCP servers:**

1. **Health Check First**: `pwsh .\Setup-MCP.ps1 -Doctor`
2. **Add Tools**: `pwsh .\Setup-MCP.ps1 -AddTool YourToolName`
3. **Test Integration**: Verify in VS Code Agent Mode
4. **Maintain**: Use clean/bootstrap as needed

This setup provides a complete, production-ready MCP server with VS Code integration, secure tool development, and comprehensive lifecycle management.
