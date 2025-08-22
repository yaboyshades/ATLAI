"""
Register Super Alita K tools with the MCP server.

This script registers the tools defined in super_alita_config.json with the MCP server.
"""

import asyncio
import json
from pathlib import Path

import httpx

# HTTP status codes
HTTP_OK = 200


async def register_tools():
    """Register tools from config with the MCP server."""
    config_path = (
        Path(__file__).parent.parent / "src" / "mcp" / "super_alita_config.json"
    )

    # Load configuration
    with open(config_path) as f:
        config = json.load(f)

    # MCP server URL
    base_url = config.get("base_url", "http://localhost:5678")

    # Get tools from config
    tools = config.get("tools", {})

    # Create async client
    async with httpx.AsyncClient() as client:
        # Check if server is running
        try:
            health_response = await client.get(f"{base_url}/health")
            if health_response.status_code != HTTP_OK:
                print(
                    f"Server health check failed with status {health_response.status_code}"
                )
                return False
            print("MCP server is healthy")
        except Exception as e:
            print(f"Failed to connect to MCP server: {e!s}")
            print(f"Make sure the server is running at {base_url}")
            return False

        # Register each tool
        for tool_name, tool_spec in tools.items():
            # Create tool registration payload
            tool_data = {
                "name": f"mcp_super_alita_k_{tool_name}",
                "description": tool_spec.get("description", ""),
                "parameters": tool_spec.get("parameters", {}),
                "handler": {
                    "type": "http",
                    "url": f"{base_url}/tools/execute/super_alita/{tool_name}",
                },
            }

            # Register the tool
            try:
                register_response = await client.post(
                    f"{base_url}/tools/register", json=tool_data
                )
                if register_response.status_code == HTTP_OK:
                    print(
                        f"Successfully registered tool: mcp_super_alita_k_{tool_name}"
                    )
                else:
                    print(
                        f"Failed to register tool {tool_name}: {register_response.status_code} - {register_response.text}"
                    )
            except Exception as e:
                print(f"Error registering tool {tool_name}: {e!s}")

    return True


async def main():
    """Main entry point."""
    success = await register_tools()
    if success:
        print("All tools successfully registered with MCP server.")
    else:
        print("Failed to register tools. See above errors for details.")


if __name__ == "__main__":
    asyncio.run(main())
# EOF
