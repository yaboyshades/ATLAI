"""Diagnostic script for testing planner -> router -> dispatcher flow."""

import asyncio
import logging
from unittest.mock import AsyncMock

from src.orchestration.dispatcher import Dispatcher
from src.orchestration.router import Router

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def test_router():
    """Test router parsing planner output."""
    logger.info("Testing Router...")

    router = Router()

    # Test GAP parsing
    gap_route = router.parse_planner_output(
        "GAP Create a tool to calculate fibonacci numbers"
    )
    print(f"GAP Test: {gap_route}")
    assert gap_route.action_type == "GAP"
    assert "fibonacci" in gap_route.params["description"]

    # Test NONE parsing
    none_route = router.parse_planner_output(
        "NONE I can help you with that, but I need more information."
    )
    print(f"NONE Test: {none_route}")
    assert none_route.action_type == "NONE"
    assert "help you" in none_route.params["response"]

    # Test TOOL parsing
    tool_route = router.parse_planner_output(
        "TOOL web_agent search for python tutorials"
    )
    print(f"TOOL Test: {tool_route}")
    assert tool_route.action_type == "TOOL"
    assert tool_route.target == "web_agent"

    # Test fallback (unknown format)
    fallback_route = router.parse_planner_output("Something unexpected")
    print(f"Fallback Test: {fallback_route}")
    assert fallback_route.action_type == "NONE"

    logger.info("Router tests passed!")


async def test_dispatcher():
    """Test dispatcher action execution."""
    logger.info("Testing Dispatcher...")

    # Mock event bus
    mock_event_bus = AsyncMock()
    dispatcher = Dispatcher(mock_event_bus, "test_session_123")

    # Test GAP dispatch
    await dispatcher.dispatch_gap(
        "Create fibonacci tool", "create a tool for fibonacci"
    )
    assert mock_event_bus.publish.called
    gap_event = mock_event_bus.publish.call_args[0][0]
    assert gap_event.event_type == "atom_gap"
    assert "fibonacci" in gap_event.description
    print(f"GAP Dispatch: Published {gap_event.event_type}")

    # Reset mock
    mock_event_bus.reset_mock()

    # Test NONE dispatch
    await dispatcher.dispatch_none("I understand your request.")
    assert mock_event_bus.publish.called
    none_event = mock_event_bus.publish.call_args[0][0]
    assert none_event.event_type == "conversation"
    assert "understand" in none_event.text
    print(f"NONE Dispatch: Published {none_event.event_type}")

    # Reset mock
    mock_event_bus.reset_mock()

    # Test TOOL dispatch
    await dispatcher.dispatch_tool(
        "web_agent", {"query": "python"}, "search for python"
    )
    assert mock_event_bus.publish.called
    tool_event = mock_event_bus.publish.call_args[0][0]
    assert tool_event.event_type == "tool_call"
    assert tool_event.tool_name == "web_agent"
    print(f"TOOL Dispatch: Published {tool_event.event_type}")

    logger.info("Dispatcher tests passed!")


async def test_end_to_end():
    """Test complete router -> dispatcher flow."""
    logger.info("Testing End-to-End Flow...")

    router = Router()
    mock_event_bus = AsyncMock()
    dispatcher = Dispatcher(mock_event_bus, "e2e_session_456")

    # Test complete flow for GAP
    user_message = "create a tool to reverse strings"
    planner_output = "GAP Create a string reversal tool"

    route = router.route_user_message(user_message, planner_output)
    await dispatcher.dispatch_action(route)

    assert mock_event_bus.publish.called
    event = mock_event_bus.publish.call_args[0][0]
    assert event.event_type == "atom_gap"
    assert "string reversal" in event.description
    print(f"E2E GAP: {user_message} -> {planner_output} -> {event.event_type}")

    # Reset mock
    mock_event_bus.reset_mock()

    # Test complete flow for TOOL
    user_message = "search for python tutorials"
    planner_output = "TOOL web_agent python tutorials"

    route = router.route_user_message(user_message, planner_output)
    await dispatcher.dispatch_action(route)

    assert mock_event_bus.publish.called
    event = mock_event_bus.publish.call_args[0][0]
    assert event.event_type == "tool_call"
    assert event.tool_name == "web_agent"
    print(f"E2E TOOL: {user_message} -> {planner_output} -> {event.event_type}")

    logger.info("End-to-End tests passed!")


async def main():
    """Run all diagnostic tests."""
    logger.info("Starting Planner -> Router -> Dispatcher Diagnostic Tests")

    try:
        await test_router()
        await test_dispatcher()
        await test_end_to_end()

        logger.info("🎉 All tests passed! Router and Dispatcher are working correctly.")

    except Exception as e:
        logger.error(f"❌ Test failed: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
