#!/usr/bin/env python3
"""
Super Alita Agent Demo

This script demonstrates the key features of the Super Alita agent:
- Plugin-based architecture with event-driven communication
- Neural atom/store with genealogy tracking
- Semantic memory with ChromaDB and embeddings
- LADDER-AOG reasoning for planning and diagnosis
- Event bus with async communication
"""

import asyncio
import logging
from pathlib import Path
import time

from src.main import SuperAlita
from src.core.events import PlanningEvent


async def demo_basic_functionality():
    """Demonstrate basic agent functionality."""
    print("🚀 Super Alita Agent Demo")
    print("=" * 50)
    
    # Create and initialize agent
    print("1. Initializing Super Alita agent...")
    agent = SuperAlita()
    
    try:
        await agent.initialize()
        print("   ✓ Agent initialized successfully")
        
        # Start the agent
        print("\n2. Starting agent and plugins...")
        await agent.start()
        print("   ✓ Agent started successfully")
        
        # Wait a moment for plugins to fully start
        await asyncio.sleep(2)
        
        # Show agent status
        print("\n3. Agent Status:")
        stats = await agent.get_agent_stats()
        print(f"   - Agent: {stats['agent']['name']} v{stats['agent']['version']}")
        print(f"   - Runtime: {stats['agent']['runtime_seconds']:.1f} seconds")
        print(f"   - Plugins: {list(stats['plugins'].keys())}")
        print(f"   - Neural Store: {stats['neural_store']['total_atoms']} atoms")
        
        # Demonstrate event emission
        print("\n4. Testing event system...")
        await agent.event_bus.emit(
            "demo",
            source_plugin="demo_script",
            message="Hello from demo!",
            level="info"
        )
        print("   ✓ Event emitted successfully")
        
        # Test command processing
        print("\n5. Testing command interface...")
        health_result = await agent.process_command("health")
        print(f"   ✓ Health check completed: {len(health_result['health_reports'])} plugins reported")
        
        # Demonstrate planning request (if LADDER-AOG plugin is available)
        if "ladder_aog" in agent.plugins:
            print("\n6. Testing LADDER-AOG planning...")
            
            # Create a planning event
            planning_event = PlanningEvent(
                event_type="planning",
                source_plugin="demo_script",
                goal="Demonstrate agent planning capabilities",
                current_state={"demo_mode": True, "step": 1},
                action_space=["analyze", "plan", "execute", "monitor"]
            )
            
            # Emit planning request
            event_data = planning_event.model_dump()
            # Remove the fields that are already in BaseEvent to avoid conflict
            event_data.pop('event_type', None)
            event_data.pop('source_plugin', None)
            event_data.pop('event_id', None)
            event_data.pop('version', None)
            event_data.pop('timestamp', None)
            event_data.pop('embedding', None)
            event_data.pop('metadata', None)
            
            await agent.event_bus.emit(
                "planning",
                source_plugin="demo_script",
                **event_data
            )
            print("   ✓ Planning request submitted to LADDER-AOG plugin")
            
            # Wait for processing
            await asyncio.sleep(1)
        
        # Show memory status (if semantic memory plugin is available)
        if "semantic_memory" in agent.plugins:
            print("\n7. Memory system status:")
            memory_plugin = agent.plugins["semantic_memory"]
            try:
                # This would normally show memory stats
                print("   ✓ Semantic memory plugin is active")
            except Exception as e:
                print(f"   ⚠ Memory plugin error: {e}")
        
        # Show final stats
        print("\n8. Final Statistics:")
        final_stats = await agent.get_agent_stats()
        print(f"   - Total runtime: {final_stats['agent']['runtime_seconds']:.1f} seconds")
        print(f"   - Events processed: {final_stats['event_bus'].get('events_processed', 0)}")
        print(f"   - Neural atoms: {final_stats['neural_store']['total_atoms']}")
        
        print("\n✅ Demo completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Demo failed: {e}")
        logging.exception("Demo error")
    
    finally:
        # Shutdown the agent
        print("\n9. Shutting down agent...")
        await agent.shutdown()
        print("   ✓ Agent shutdown complete")


async def demo_planning_workflow():
    """Demonstrate LADDER-AOG planning workflow."""
    print("\n" + "=" * 50)
    print("🧠 LADDER-AOG Planning Demo")
    print("=" * 50)
    
    # Create minimal agent for planning demo
    agent = SuperAlita()
    
    try:
        await agent.initialize()
        await agent.start()
        
        if "ladder_aog" not in agent.plugins:
            print("❌ LADDER-AOG plugin not available")
            return
        
        ladder_plugin = agent.plugins["ladder_aog"]
        print(f"✓ LADDER-AOG plugin loaded: {ladder_plugin.name}")
        
        # Test planning scenarios
        scenarios = [
            {
                "name": "Simple Task Planning",
                "goal": "Organize daily schedule",
                "state": {"time": "morning", "tasks": ["meeting", "coding", "lunch"]},
                "actions": ["prioritize", "schedule", "execute"]
            },
            {
                "name": "Problem Solving",
                "goal": "Debug software issue",
                "state": {"bug_reported": True, "severity": "high"},
                "actions": ["investigate", "isolate", "fix", "test"]
            }
        ]
        
        for i, scenario in enumerate(scenarios, 1):
            print(f"\n{i}. {scenario['name']}:")
            
            planning_event = PlanningEvent(
                event_type="planning",
                source_plugin="demo_script",
                goal=scenario["goal"],
                current_state=scenario["state"],
                action_space=scenario["actions"]
            )
            
            # Submit to LADDER-AOG
            event_data = planning_event.model_dump()
            # Remove the fields that are already in BaseEvent to avoid conflict
            event_data.pop('event_type', None)
            event_data.pop('source_plugin', None)
            event_data.pop('event_id', None)
            event_data.pop('version', None)
            event_data.pop('timestamp', None)
            event_data.pop('embedding', None)
            event_data.pop('metadata', None)
            
            await agent.event_bus.emit(
                "planning",
                source_plugin="demo_script",
                **event_data
            )
            
            print(f"   ✓ Planning request submitted for: {scenario['goal']}")
            
            # Wait for processing
            await asyncio.sleep(2)
        
        print("\n✅ Planning demo completed!")
        
    except Exception as e:
        print(f"❌ Planning demo failed: {e}")
        logging.exception("Planning demo error")
    
    finally:
        await agent.shutdown()


async def main():
    """Main demo function."""
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Create logs directory
    Path("logs").mkdir(exist_ok=True)
    
    try:
        # Run basic functionality demo
        await demo_basic_functionality()
        
        # Small delay between demos
        await asyncio.sleep(1)
        
        # Run planning demo
        await demo_planning_workflow()
        
    except KeyboardInterrupt:
        print("\n⚠ Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Demo failed with error: {e}")
        logging.exception("Main demo error")


if __name__ == "__main__":
    print("Super Alita Agent - Production Demo")
    print("Press Ctrl+C to interrupt at any time\n")
    
    # Run the async demo
    asyncio.run(main())
