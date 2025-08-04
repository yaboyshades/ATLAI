# Agent Instructions

- Run tests with `pytest` before committing.
- Decorate all asynchronous tests with `@pytest.mark.asyncio`.
- Use timezone-aware timestamps (`datetime.now(datetime.UTC)`).
- Emit events using keyword arguments; avoid positional dicts.
- Keep configuration files and README in sync with available plugins.
- When adding plugins, ensure they inherit from `PluginInterface` and implement `name` and `shutdown`.
