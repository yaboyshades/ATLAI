"""Local shim for Copilot-specific MCP server launch within the packaged
`super-alita` directory. Mirrors top-level `mcp/copilot_mcp_server.py` so
VS Code / Copilot extension kernels referencing `super-alita/mcp/copilot_mcp_server.py`
don't fail with FileNotFound.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# --- Path Bootstrap -----------------------------------------------------
# Support being launched with cwd anywhere (extension hosts sometimes set cwd
# to the file's directory or repository root). We locate the repository root
# by walking up until we find a sibling 'src' directory.
_HERE = Path(__file__).resolve()
_CANDIDATE = _HERE.parents[1]  # super-alita/
if not (_CANDIDATE / "src").exists():  # fallback: walk further up
    for _p in _HERE.parents:
        if (_p / "src").exists():
            _CANDIDATE = _p
            break

if (_CANDIDATE / "src").exists():  # ensure on sys.path front
    candidate_str = str(_CANDIDATE)
    if candidate_str not in sys.path:
        sys.path.insert(0, candidate_str)
        if os.environ.get("ALITA_MCP_DEBUG"):
            print(
                f"[copilot_mcp_server] Added to sys.path: {candidate_str}",
                file=sys.stderr,
            )
    # --- Duplicate path segment detection (developer aid) ---
    # Detect launches where the command path accidentally included an extra
    # 'super-alita' segment (e.g. super-alita\\super-alita\\mcp\\copilot_mcp_server.py)
    if not os.environ.get("ALITA_MCP_SUPPRESS_DUP_WARN"):
        parts = [p for p in candidate_str.split(os.sep) if p]
        if parts.count("super-alita") > 1:
            print(
                (
                    "[copilot_mcp_server][WARN] Detected duplicate 'super-alita' path segments.\n"
                    f"  resolved: {candidate_str}\n"
                    "  You may have launched from the parent directory using a path\n"
                    "  containing the folder twice.\n"
                    "  Recommended: set cwd to the inner 'super-alita' directory and run:\n"
                    "    python -m src.integrations.copilot_mcp.server\n"
                    "  Suppress: set ALITA_MCP_SUPPRESS_DUP_WARN=1"
                ),
                file=sys.stderr,
            )
else:
    print(
        f"[copilot_mcp_server] WARNING: Could not locate 'src' directory starting from {_HERE}",
        file=sys.stderr,
    )

# --- Import Main --------------------------------------------------------
try:  # pragma: no cover
    from src.integrations.copilot_mcp.server import main as _main
except Exception as _e:  # pragma: no cover
    # Emit rich diagnostics before exiting to help extension developers.
    print(
        "[super-alita/mcp/copilot_mcp_server.py] Import failure diagnostics:\n"
        f"  error: {_e}\n"
        f"  sys.path: {sys.path}\n"
        f"  cwd: {os.getcwd()}",
        file=sys.stderr,
    )
    raise SystemExit(
        f"[super-alita/mcp/copilot_mcp_server.py] Cannot import copilot MCP server: {_e}"
    ) from _e

if __name__ == "__main__":  # pragma: no cover
    _main()
