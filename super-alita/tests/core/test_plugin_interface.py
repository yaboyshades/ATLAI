import asyncio
from unittest.mock import Mock
import pytest

from src.core.plugin_interface import PluginInterface


class TestPlugin(PluginInterface):
    @property
    def name(self) -> str:  # type: ignore[override]
        return "test_plugin"

    async def setup(self, event_bus, store, config):  # type: ignore[override]
        await super().setup(event_bus, store, config)

    async def start(self) -> None:  # type: ignore[override]
        await super().start()

    async def shutdown(self) -> None:  # type: ignore[override]
        pass


@pytest.mark.asyncio
async def test_lifecycle():
    plugin = TestPlugin()
    await plugin.setup(Mock(), Mock(), {})
    await plugin.start()
    assert plugin.is_running
    await plugin.stop()
    assert not plugin.is_running


@pytest.mark.asyncio
async def test_task_management():
    plugin = TestPlugin()
    await plugin.setup(Mock(), Mock(), {})

    async def dummy():
        await asyncio.sleep(0.01)
        return 1

    task = plugin.add_task(dummy())
    await plugin.start()
    await task
    await plugin.stop()
    assert len(plugin._tasks) == 0
