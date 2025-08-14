# Super Alita: Upgrade and Developer Guide

This guide provides instructions for upgrading the `super-alita` agent to the new "Modular Neural Atom System Quarks" architecture. It also serves as a developer guide for working with the new architecture.

## 1. Introduction to the Quark Architecture

The new architecture is based on the concept of "Quarks," which are self-contained, composable components that encapsulate different aspects of an agent's functionality. This modular approach makes the agent more flexible, maintainable, and robust.

The core Quark types are:
- **`CapabilityQuark`**: Describes what an agent can do abstractly.
- **`ToolBindingQuark`**: Connects a capability to a concrete tool or API.
- **`SkillPlanQuark`**: Defines a multi-step plan for achieving a complex goal.
- **`IOContractQuark`**: Defines the input/output schema for any component.
- **`IdentityQuark`**: Defines the agent's persona, scope, and permissions.
- **`PolicyQuark`**: Encodes the rules and constraints the agent must follow.
- **`GuardQuark`**: Enforces policies and contracts at runtime.

## 2. High-Level Upgrade Strategy

The upgrade process will be done in phases to minimize disruption. The high-level strategy is as follows:

1.  **Introduce Core Quark Data Structures**: Define the Pydantic models for all the Quarks.
2.  **Refactor Plugins into Services and Quarks**: Convert the existing plugins into standalone services and expose their functionality through `ToolBindingQuarks`.
3.  **Redesign the `NeuralAtom`**: Decompose the monolithic `NeuralAtom` into a set of Quarks.
4.  **Update the Orchestrator**: Update the main application to load, assemble, and manage Quarks.

## 3. Step-by-Step Upgrade Guide

This section provides a detailed, step-by-step guide for the upgrade.

### Step 1: Define Quark Data Structures

- Create a new file `src/core/quarks.py`.
- In this file, define the Pydantic models for all the Quark types as specified in the "Modular Neural Atom System Quarks" document.

### Step 2: Refactor the `SemanticMemoryPlugin`

- Create a new `src/services/memory_service.py` module.
- Move the logic for interacting with `ChromaDB` from `semantic_memory_plugin.py` to this new service.
- Create a new `src/tools/memory_tools.py` module.
- In this file, define the following `ToolBindingQuarks`:
    - `MemoryUpsertTool`: For adding or updating memories.
    - `MemoryQueryTool`: For searching memories.
    - `TextEmbeddingTool`: For getting text embeddings.
- Remove the `SemanticMemoryPlugin`.

### Step 3: Refactor the `LADDERAOGPlugin`

- Create a new `src/services/planner_service.py` module.
- Move the MCTS planning logic from `ladder_aog_plugin.py` to this new service.
- Convert the existing AOGs into `SkillPlanQuark` definitions. These can be stored in a new `src/plans` directory as JSON or YAML files.
- The `AOGNode` data structure will be replaced by the `SkillPlanQuark` and `PlanStep` models.
- Remove the `LADDERAOGPlugin`.

### Step 4: Refactor the `SemanticFSMPlugin`

- Create a new `src/services/fsm_service.py` module.
- Move the `SemanticFSM` logic to this new service.
- The FSM definitions ("agent_lifecycle", etc.) should be loaded from configuration files.
- The actions associated with FSM states should be implemented by emitting events that trigger `SkillPlanQuarks` or `ToolBindingQuarks`.
- Remove the `SemanticFSMPlugin`.

### Step 5: Refactor the `SkillDiscoveryPlugin`

- Create a new `src/services/skill_discovery_service.py` module.
- Move the PAE pipeline logic to this new service.
- The service should now generate `CapabilityQuarks` and `SkillPlanQuarks` instead of `NeuralAtom`s.
- Remove the `SkillDiscoveryPlugin`.

### Step 6: Refactor the `OpenAIAgentPlugin`

- Create a new `ToolBindingQuark` for the OpenAI Agent in `src/tools/openai_tools.py`.
- Create a new `SkillPlanQuark` in `src/plans` to define the conversation logic.
- Remove the `OpenAIAgentPlugin`.

### Step 7: Redesign the Core Components

- **`src/core/neural_atom.py`**: This file will be removed. The `NeuralAtom` concept is replaced by the new Quark-based model.
- **`src/core/genealogy.py`**: This will be refactored into a more generic `src/services/telemetry_service.py`. It will continue to provide the genealogy and auditability features, but it will be adapted to trace events from any Quark.
- **`src/core/event_bus.py`**: The event bus will be preserved, but the event schemas in `src/core/events.py` will be redesigned to be more generic and to carry Quark-specific information.

### Step 8: Update the Orchestrator

- The main orchestrator in `src/main.py` will be updated to:
    1.  Load and initialize the new services (`PlannerService`, `FSMService`, etc.).
    2.  Load the `ToolBindingQuarks` and `SkillPlanQuarks` from their respective directories.
    3.  Assemble the agent by composing the required Quarks.
    4.  The main application loop will be driven by the `FSMService` and the `PlannerService`.

## 4. Developer Guide for the New Architecture

This section provides guidance for developers working with the new Quark-based architecture.

### Creating a New Tool

1.  Create a new `ToolBindingQuark` for your tool. This involves defining its name, description, and input/output schemas.
2.  Implement the tool's logic as a Python function.
3.  Register the new `ToolBindingQuark` with the agent's orchestrator.

### Creating a New Skill Plan

1.  Create a new `SkillPlanQuark` definition as a JSON or YAML file in the `src/plans` directory.
2.  Define the steps of the plan, specifying which tools or other skills to call.
3.  The new skill plan will be automatically loaded by the `PlannerService`.

### Best Practices

-   **Keep Quarks Small and Focused**: Each Quark should have a single, well-defined responsibility.
-   **Use IOContracts**: Define clear input/output schemas for all your Quarks to ensure interoperability.
-   **Emit Telemetry Events**: Use the central telemetry service to emit events from your Quarks. This is crucial for debugging and auditing.
-   **Leverage the Event Bus**: Use the event bus for communication between Quarks and services. Avoid direct calls between components.
