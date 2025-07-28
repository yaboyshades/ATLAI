# Super Alita AI Agent Instructions

This document provides actionable guidance for AI agents working with the Super Alita neuro-symbolic agent codebase.

## 🏗️ Architecture Overview

Super Alita is a **plugin-based, event-driven** neuro-symbolic agent with:
- **Neural Atoms**: Reactive state units with genealogy (`src/core/neural_atom.py`)
- **Event Bus**: Async Protobuf communication (`src/core/event_bus.py`) 
- **Plugin System**: Hot-swappable modules (`src/core/plugin_interface.py`)
- **Genealogy Tracing**: Darwin-Gödel lineage tracking (`src/core/genealogy.py`)
- **Semantic FSM**: Embedding-based workflow states (`src/plugins/semantic_fsm_plugin.py`)
- **MCTS Evolution**: Skill discovery and optimization (`src/tools/mcts_evolution.py`)

## 🔧 Code Patterns & Conventions

### Plugin Development
All plugins inherit from `PluginInterface` and follow this lifecycle:
```python
class YourPlugin(PluginInterface):
    @property
    def name(self) -> str:
        return "your_plugin"
    
    async def setup(self, event_bus, store, config): 
        # Initialize with dependencies
        
    async def start(self):
        # Register event listeners, start tasks
        await self.subscribe("event_type", self._handle_event)
        
    async def shutdown(self):
        # Clean up resources
```

**Key plugin files to reference:**
- `src/plugins/semantic_memory_plugin.py` - Memory management
- `src/plugins/skill_discovery_plugin.py` - PAE skill evolution
- `src/plugins/semantic_fsm_plugin.py` - Workflow state management

### Neural Atom Management
Create reactive state atoms with genealogy:
```python
atom = NeuralAtom(
    key="skill:your_skill",
    default_value=skill_object,
    vector=embedding,
    parent_keys=["parent1", "parent2"],
    birth_event="skill_creation",
    lineage_metadata={"fitness": 0.85}
)
await store.register_with_lineage(atom, parents, "birth_event", metadata)
```

### Event Communication
Use typed events for inter-plugin communication:
```python
# Define in src/core/events.py
class YourEvent(BaseEvent):
    event_type: str = "your_event"
    data: Dict[str, Any]

# Emit events
await self.emit_event("your_event", data=payload)

# Subscribe to events  
await self.subscribe("your_event", self._handle_your_event)
```

### Genealogy Tracking
All cognitive primitives must track lineage:
```python
from src.core.genealogy import trace_birth

# Track atom birth
trace_birth(
    key="atom_key",
    node_type="skill",
    birth_event="creation",
    parent_keys=["parent1", "parent2"],
    metadata={"fitness": 0.9}
)
```

## 📁 File Organization

```
src/
├── core/           # Core systems (atoms, events, genealogy)
├── plugins/        # Swappable agent modules  
├── tools/          # Utility functions and MCTS evolution
├── config/         # YAML configuration
└── main.py         # Agent orchestrator
```

**When adding features:**
- Core logic → `src/core/`
- Agent capabilities → `src/plugins/`
- Utilities/algorithms → `src/tools/`
- Configuration → `src/config/agent.yaml`

## 🔄 Development Workflow

### Adding New Skills
1. Create skill atom with embedding and parents
2. Register in `NeuralStore` with genealogy 
3. Emit `SkillProposalEvent` for PAE evaluation
4. Track fitness and evolution in genealogy

### Plugin Integration
1. Extend `PluginInterface` 
2. Register event handlers in `start()`
3. Add plugin config in `agent.yaml`
4. Add to plugin list in `main.py`

### Testing Strategy
- Unit tests in `tests/core/` for core systems
- Plugin tests in `tests/plugins/` 
- Integration tests in `tests/integration/`
- Use `pytest-asyncio` for async code

## 🛠️ Common Tasks

### Debugging
- Export genealogy: `tracer.export_to_graphml("debug.graphml")`
- Check atom lineage: `await store.get_children(atom_key)`
- Monitor events: Subscribe to `SystemEvent` for logging

### Performance Optimization  
- Prune unfit atoms: `await store.prune_atoms(fitness_threshold=0.1)`
- Monitor health: Use `HealthCheckEvent` system
- Profile with genealogy export for bottlenecks

### Configuration Changes
- Plugin settings in `src/config/agent.yaml`
- Environment variables for dev/prod differences
- Runtime config via event system

## ⚠️ Critical Constraints

### Must Follow
- **All atoms need genealogy**: Use `register_with_lineage()` not `register_atom()`
- **Event-driven communication**: No direct plugin-to-plugin calls
- **Async patterns**: All I/O operations must be async
- **Type safety**: Use Pydantic models for events (`src/core/events.py`)

### Avoid
- Blocking operations in event handlers
- Direct database/file access (use atoms and events)
- Hardcoded plugin dependencies (use event bus)
- Mutations without genealogy tracking

## 🧪 Testing & Validation

### Required Tests
```python
# Plugin tests
@pytest.mark.asyncio
async def test_plugin_lifecycle():
    plugin = YourPlugin()
    await plugin.setup(mock_bus, mock_store, config)
    await plugin.start()
    assert plugin.is_running
    await plugin.stop()

# Atom genealogy tests  
@pytest.mark.asyncio
async def test_atom_genealogy():
    atom = await create_skill_atom(store, "test", skill, ["parent1"])
    children = await store.get_children("parent1")
    assert "skill:test" in children
```

### Validation Commands
```bash
# Run core tests
pytest tests/core/ -v

# Test plugin integration
pytest tests/plugins/ -v  

# Check genealogy export
python -c "from src.core.genealogy import get_global_tracer; get_global_tracer().export_to_graphml('test.graphml')"
```

## 🎯 Integration Points

### External Services
- Vector databases: Configure in `semantic_memory_plugin.py`
- LLM APIs: Handle in skill discovery plugin
- File I/O: Use genealogy export/import system

### Key Interfaces
- `PluginInterface`: All agent capabilities
- `NeuralAtom`: State management
- `BaseEvent`: Inter-component communication  
- `GenealogyTracer`: Lineage tracking

## 📚 Reference Examples

### Complete Plugin Example
See `src/plugins/semantic_memory_plugin.py` - demonstrates:
- Event subscription patterns
- Atom management with genealogy
- Configuration handling
- Resource cleanup

### Evolution Example  
See `src/plugins/skill_discovery_plugin.py` - shows:
- PAE (Proposer-Agent-Evaluator) cycle
- MCTS integration for skill evolution
- Fitness tracking and genealogy

### FSM Example
See `src/plugins/semantic_fsm_plugin.py` - illustrates:
- Embedding-based state transitions
- Semantic similarity thresholds
- Workflow management patterns

---

**Quick Reference**: This codebase prioritizes **traceability**, **modularity**, and **evolution**. Every change should be tracked in genealogy, communicated via events, and tested in isolation.
