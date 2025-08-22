#!/usr/bin/env python
"""
Co-Architect MCP Verification Script
===================================

This script starts and verifies the Co-Architect MCP integration.
It checks that the MCP server is running, registers test tools,
and executes them to ensure everything is working correctly.
"""

import asyncio
import logging
import os
import sys
from typing import Any

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.core.co_architect_mcp import CoArchitectMCPConnector
from src.core.mcp_integration import create_mcp_integration

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler()],
)

logger = logging.getLogger("co-architect-mcp-verify")

# Constants
EXPECTED_TOOL_COUNT = 2
EXPECTED_ADD_RESULT = 12

# Test tools
TEST_TOOLS = [
    {
        "name": "echo",
        "schema": {
            "description": "Echo back the input",
            "parameters": {
                "type": "object",
                "properties": {
                    "message": {"type": "string", "description": "Message to echo back"}
                },
                "required": ["message"],
            },
        },
    },
    {
        "name": "add",
        "schema": {
            "description": "Add two numbers",
            "parameters": {
                "type": "object",
                "properties": {
                    "a": {"type": "number", "description": "First number"},
                    "b": {"type": "number", "description": "Second number"},
                },
                "required": ["a", "b"],
            },
        },
    },
]


# Tool handlers
async def handle_echo(message: str) -> dict[str, Any]:
    """Handle echo tool."""
    return {"message": message}


async def handle_add(a: float, b: float) -> dict[str, Any]:
    """Handle add tool."""
    return {"result": a + b}


async def verify_mcp_server() -> bool:
    """Verify MCP server is running."""
    logger.info("Verifying MCP server...")
    mcp = await create_mcp_integration()

    is_running = await mcp.ping()
    if is_running:
        logger.info("✅ MCP server is running")
    else:
        logger.error("❌ MCP server is not running")
        logger.error(
            "Please start the MCP server using 'python -m src.mcp.server' "
            "or run task 'mcp:server'"
        )

    await mcp.shutdown()
    return is_running


async def verify_co_architect_mcp() -> bool:
    """Verify Co-Architect MCP integration."""
    logger.info("Verifying Co-Architect MCP integration...")

    # Create connector
    connector = CoArchitectMCPConnector()
    await connector.start()

    # Register test tools
    logger.info("Registering test tools...")
    # Fix type issues by explicitly converting to str and Dict
    tool_name = str(TEST_TOOLS[0]["name"])
    tool_schema = dict(TEST_TOOLS[0]["schema"])
    success_echo = await connector.register_tool(tool_name, tool_schema, handle_echo)

    tool_name = str(TEST_TOOLS[1]["name"])
    tool_schema = dict(TEST_TOOLS[1]["schema"])
    success_add = await connector.register_tool(tool_name, tool_schema, handle_add)

    if success_echo and success_add:
        logger.info("✅ Successfully registered test tools")
    else:
        logger.error("❌ Failed to register test tools")
        await connector.shutdown()
        return False

    # List tools
    logger.info("Listing registered tools...")
    tools = await connector.list_tools()

    if tools and len(tools) >= EXPECTED_TOOL_COUNT:
        logger.info("✅ Found %s registered tools", len(tools))
    else:
        logger.error("❌ Failed to list tools")
        await connector.shutdown()
        return False

    # Execute tools
    logger.info("Executing echo tool...")
    echo_result = await connector.execute_tool(
        "echo", {"message": "Hello, Co-Architect MCP!"}
    )

    if (
        echo_result.get("success")
        and echo_result.get("result", {}).get("message") == "Hello, Co-Architect MCP!"
    ):
        logger.info("✅ Successfully executed echo tool")
    else:
        logger.error("❌ Failed to execute echo tool")
        await connector.shutdown()
        return False

    logger.info("Executing add tool...")
    add_result = await connector.execute_tool("add", {"a": 5, "b": 7})

    if (
        add_result.get("success")
        and add_result.get("result", {}).get("result") == EXPECTED_ADD_RESULT
    ):
        logger.info("✅ Successfully executed add tool")
    else:
        logger.error("❌ Failed to execute add tool")
        await connector.shutdown()
        return False

    # Check memory records
    logger.info("Checking memory records...")
    records = await connector.get_memory_records()

    if records and len(records) > 0:
        logger.info("✅ Found %s memory records", len(records))
    else:
        logger.error("❌ Failed to retrieve memory records")
        await connector.shutdown()
        return False

    # Shutdown
    await connector.shutdown()
    logger.info("✅ All Co-Architect MCP verification steps passed!")
    return True


async def main() -> int:
    """Main function."""
    logger.info("Co-Architect MCP Verification")
    logger.info("============================")

    # Verify MCP server
    if not await verify_mcp_server():
        return 1

    # Verify Co-Architect MCP integration
    if not await verify_co_architect_mcp():
        return 1

    logger.info("🎉 Co-Architect MCP integration is working correctly!")
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
