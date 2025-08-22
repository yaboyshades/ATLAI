#!/usr/bin/env python3
"""
🚀 Super Alita Agent - One-Command Launch Script
================================================

Launch the complete neuro-symbolic cognitive agent with all plugins:
- EventBus (communication hub)
- SemanticMemory (ChromaDB + Gemini embeddings)
- SemanticFSM (behavioral states)
- SkillDiscovery (MCTS evolution)
- LADDER-AOG (And-Or Graph reasoning)

Usage:
    python launch.py

Or with custom goals:
    python launch.py --goal "Learn quantum computing"
    python launch.py --interactive
"""

import argparse
import asyncio
import logging
import signal

from src.core.events import PlanningEvent
from src.main import SuperAlita


class AgentLauncher:
    """Production launcher for Super Alita agent."""

    def __init__(self):
        self.agent = None
        self.running = False

    async def launch_agent(self, goals: list = None, interactive: bool = False):
        """Launch the agent with optional goals."""
        print("🚀 Launching Super Alita Agent...")
        print("=" * 50)

        try:
            # Initialize and start agent
            self.agent = SuperAlita()
            await self.agent.initialize()
            await self.agent.start()
            self.running = True

            print("✅ Agent launched successfully!")
            print(f"📊 Active plugins: {list(self.agent.plugins.keys())}")
            print(f"🧠 Neural atoms: {len(self.agent.neural_store._atoms)}")
            print()

            # Submit initial goals if provided
            if goals:
                print("🎯 Submitting initial goals...")
                for i, goal in enumerate(goals, 1):
                    await self._submit_goal(goal, f"launch_goal_{i}")
                    print(f"   {i}. {goal}")
                print()

            # Interactive mode
            if interactive:
                await self._interactive_mode()
            else:
                await self._autonomous_mode()

        except KeyboardInterrupt:
            print("\n⚠️  Shutdown requested by user")
        except Exception as e:
            print(f"❌ Launch failed: {e}")
            logging.exception("Agent launch error")
        finally:
            await self._shutdown()

    async def _submit_goal(self, goal: str, session_id: str):
        """Submit a planning goal to the agent."""
        if "ladder_aog" not in self.agent.plugins:
            print("⚠️  LADDER-AOG plugin not available for planning")
            return

        planning_event = PlanningEvent(
            event_type="planning",
            source_plugin="launcher",
            goal=goal,
            current_state={"session": session_id, "mode": "autonomous"},
            action_space=["analyze", "plan", "execute", "monitor", "adapt"],
        )

        # Extract event data for emission
        event_data = planning_event.model_dump()
        event_data.pop("event_type", None)
        event_data.pop("source_plugin", None)
        event_data.pop("event_id", None)
        event_data.pop("version", None)
        event_data.pop("timestamp", None)
        event_data.pop("embedding", None)
        event_data.pop("metadata", None)

        await self.agent.event_bus.emit(
            "planning", source_plugin="launcher", **event_data
        )

    async def _interactive_mode(self):
        """Run in interactive mode accepting user commands."""
        print("🎮 Interactive Mode Active")
        print("Commands: goal <description>, status, export, quit")
        print("-" * 50)

        try:
            while self.running:
                command = input("🤖 > ").strip()

                if command.lower() in ["quit", "exit", "q"]:
                    break
                if command.lower() == "status":
                    await self._show_status()
                elif command.lower() == "export":
                    await self._export_genealogy()
                elif command.lower().startswith("goal "):
                    goal = command[5:].strip()
                    if goal:
                        await self._submit_goal(goal, "interactive")
                        print(f"✅ Goal submitted: {goal}")
                    else:
                        print("❌ Please provide a goal description")
                elif command.lower() == "help":
                    print("Available commands:")
                    print("  goal <text>  - Submit planning goal")
                    print("  status       - Show agent status")
                    print("  export       - Export genealogy")
                    print("  quit         - Shutdown agent")
                else:
                    print("❓ Unknown command. Type 'help' for options.")

        except (EOFError, KeyboardInterrupt):
            pass

    async def _autonomous_mode(self):
        """Run in autonomous mode."""
        print("🤖 Autonomous Mode Active")
        print("Press Ctrl+C to shutdown")
        print("-" * 50)

        try:
            # Keep agent running and show periodic status
            while self.running:
                await asyncio.sleep(30)  # Status every 30 seconds
                await self._show_status()

        except KeyboardInterrupt:
            pass

    async def _show_status(self):
        """Show current agent status."""
        if not self.agent:
            return

        stats = await self.agent.get_agent_stats()
        print("📊 Agent Status:")
        print(f"   Runtime: {stats.get('runtime', 'Unknown')}")
        print(f"   Plugins: {len(stats.get('plugins', []))}")
        print(
            f"   Neural Store: {stats.get('neural_store', {}).get('total_atoms', 0)} atoms"
        )
        print(f"   Events: {stats.get('events_processed', 0)} processed")

    async def _export_genealogy(self):
        """Export current genealogy to GraphML."""
        if not self.agent:
            return

        from datetime import datetime

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"data/genealogy/export_{timestamp}.graphml"

        try:
            self.agent.genealogy_tracer.export_to_graphml(filename)
            print(f"✅ Genealogy exported to: {filename}")
        except Exception as e:
            print(f"❌ Export failed: {e}")

    async def _shutdown(self):
        """Gracefully shutdown the agent."""
        if self.agent and self.running:
            print("\n🛑 Shutting down Super Alita...")
            await self.agent.shutdown()
            self.running = False
            print("✅ Shutdown complete")


def setup_signal_handlers(launcher):
    """Setup graceful shutdown on signals."""

    def signal_handler(signum, frame):
        print(f"\n🛑 Received signal {signum}")
        if launcher.running:
            launcher.running = False

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)


async def main():
    """Main launcher entry point."""
    parser = argparse.ArgumentParser(description="Launch Super Alita Agent")
    parser.add_argument(
        "--goal", action="append", help="Initial planning goals (can specify multiple)"
    )
    parser.add_argument(
        "--interactive", action="store_true", help="Run in interactive mode"
    )
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Set logging level",
    )

    args = parser.parse_args()

    # Configure logging
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    # Launch agent
    launcher = AgentLauncher()
    setup_signal_handlers(launcher)

    await launcher.launch_agent(goals=args.goal or [], interactive=args.interactive)


if __name__ == "__main__":
    print("🧠 Super Alita Neuro-Symbolic Agent")
    print("🚀 Production Launch System")
    print("=" * 50)

    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"💥 Fatal error: {e}")
        exit(1)
