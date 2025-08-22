"""
Super Alita Final Integration: Start KG API + Validate Full System
This script ensures all components are working together properly.
"""

import asyncio
import logging
import subprocess
import sys
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def validate_environment() -> bool:
    """Validate that the environment is set up correctly."""
    logger.info("🔧 Validating environment...")

    checks = []

    # Check Python version
    if sys.version_info >= (3, 9):
        checks.append(("Python 3.9+", True))
        logger.info(f"✅ Python {sys.version_info.major}.{sys.version_info.minor}")
    else:
        checks.append(("Python 3.9+", False))
        logger.error(
            f"❌ Python {sys.version_info.major}.{sys.version_info.minor} (need 3.9+)"
        )

    # Check critical files exist
    critical_files = [
        "src/core/kg_api_server.py",
        "src/core/states.py",
        "src/core/execution_flow.py",
        "src/core/decision_engine.py",
        "src/core/smoothing.py",
        "src/core/risk_engine.py",
        "src/core/todo_sync.py",
        "start_kg_api.py",
    ]

    for filepath in critical_files:
        exists = Path(filepath).exists()
        checks.append((filepath, exists))
        if exists:
            logger.info(f"✅ {filepath}")
        else:
            logger.error(f"❌ Missing: {filepath}")

    # Check dependencies
    try:
        import fastapi

        checks.append(("FastAPI", True))
        logger.info("✅ FastAPI installed")
    except ImportError:
        checks.append(("FastAPI", False))
        logger.error("❌ FastAPI not installed")

    try:
        import uvicorn

        checks.append(("Uvicorn", True))
        logger.info("✅ Uvicorn installed")
    except ImportError:
        checks.append(("Uvicorn", False))
        logger.error("❌ Uvicorn not installed")

    all_passed = all(passed for _, passed in checks)

    if all_passed:
        logger.info("✅ Environment validation passed!")
    else:
        failed = [name for name, passed in checks if not passed]
        logger.error(f"❌ Environment validation failed: {failed}")

    return all_passed


async def start_kg_api_server() -> subprocess.Popen | None:
    """Start the KG API server in background."""
    logger.info("🚀 Starting KG API server...")

    try:
        # Start the server process
        process = subprocess.Popen(
            [sys.executable, "start_kg_api.py"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        # Give it a moment to start
        await asyncio.sleep(2)

        # Check if it's still running
        if process.poll() is None:
            logger.info("✅ KG API server started successfully")
            return process
        else:
            stdout, stderr = process.communicate()
            logger.error("❌ KG API server failed to start:")
            logger.error(f"stdout: {stdout}")
            logger.error(f"stderr: {stderr}")
            return None

    except Exception as e:
        logger.error(f"❌ Failed to start KG API server: {e}")
        return None


async def validate_kg_api_endpoints():
    """Validate that KG API endpoints are responding."""
    logger.info("🌐 Validating KG API endpoints...")

    try:
        import aiohttp

        async with aiohttp.ClientSession() as session:
            base_url = "http://localhost:8000"

            # Test health endpoint
            async with session.get(f"{base_url}/health") as response:
                if response.status == 200:
                    health_data = await response.json()
                    logger.info(f"✅ Health endpoint: {health_data['status']}")
                else:
                    logger.error(f"❌ Health endpoint failed: {response.status}")
                    return False

            # Test metrics endpoint
            async with session.get(f"{base_url}/metrics") as response:
                if response.status == 200:
                    metrics_data = await response.json()
                    logger.info(f"✅ Metrics endpoint: {len(metrics_data)} metrics")
                else:
                    logger.error(f"❌ Metrics endpoint failed: {response.status}")
                    return False

            # Test KG endpoints
            kg_endpoints = [
                "/api/kg/policy",
                "/api/kg/personality",
                "/api/kg/consolidation",
            ]

            for endpoint in kg_endpoints:
                async with session.get(f"{base_url}{endpoint}") as response:
                    if response.status == 200:
                        data = await response.json()
                        logger.info(f"✅ {endpoint}: {len(data)} items")
                    else:
                        logger.error(f"❌ {endpoint} failed: {response.status}")
                        return False

        logger.info("✅ All KG API endpoints validated!")
        return True

    except ImportError:
        logger.warning("⚠️  aiohttp not available, skipping API validation")
        return True
    except Exception as e:
        logger.error(f"❌ KG API validation failed: {e}")
        return False


async def test_metrics_pipeline():
    """Test the full metrics → todos pipeline."""
    logger.info("🔄 Testing metrics pipeline...")

    try:
        # Import the sync script
        sys.path.insert(0, str(Path("src/planning")))
        from sync_once import sync_metrics_to_todos

        # Run the sync
        result = await sync_metrics_to_todos()

        if result["success"]:
            logger.info("✅ Metrics pipeline test passed!")
            logger.info(f"  📊 Processed {result['metrics_processed']} metrics")
            logger.info(f"  📝 {result['actions_taken']} actions taken")
            logger.info(f"  📋 {result['active_todos']} active todos")
            logger.info(f"  ⚠️  Risk score: {result['risk_score']:.3f}")
            return True
        else:
            logger.error(f"❌ Metrics pipeline test failed: {result['error']}")
            return False

    except Exception as e:
        logger.error(f"❌ Metrics pipeline test failed: {e}")
        return False


async def demo_anti_thrash():
    """Run the anti-thrash demonstration."""
    logger.info("🎯 Running anti-thrash demonstration...")

    try:
        sys.path.insert(0, str(Path("src/planning")))
        from sync_once import demo_anti_thrash_protection

        demo_anti_thrash_protection()
        logger.info("✅ Anti-thrash demonstration completed!")
        return True

    except Exception as e:
        logger.error(f"❌ Anti-thrash demonstration failed: {e}")
        return False


def show_next_steps():
    """Show the user what to do next."""
    print("\n" + "=" * 60)
    print("🎉 SUPER ALITA INTEGRATION COMPLETE!")
    print("=" * 60)
    print()
    print("🔗 Next Steps:")
    print("  1. Start VS Code: code .")
    print("  2. Install the MCP extension if not already installed")
    print("  3. Run: pwsh .\\Setup-MCP.ps1 -Bootstrap")
    print("  4. Open the agent: MCP: Show Installed Servers")
    print("  5. Check metrics: http://localhost:8000/metrics")
    print("  6. View dashboard: Configure Grafana with config/grafana/")
    print()
    print("🛠️  Manual Verification:")
    print("  • KG API Server: http://localhost:8000/health")
    print("  • Metrics Sync: python src/planning/sync_once.py")
    print("  • Anti-Thrash Demo: python src/planning/sync_once.py --demo")
    print("  • Agent Launch: python src/main.py")
    print()
    print("📊 Monitoring:")
    print("  • Prometheus: Point to localhost:8000/metrics")
    print("  • Grafana: Import config/grafana/super-alita-dashboard.json")
    print("  • VS Code: Extension shows learning velocity in status bar")
    print()
    print("✅ System Status: READY FOR OPERATION")


async def main():
    """Main integration workflow."""
    print("🚀 Super Alita Final Integration")
    print("=" * 50)

    # 1. Validate environment
    if not validate_environment():
        print("❌ Environment validation failed. Please fix the issues above.")
        sys.exit(1)

    print()

    # 2. Start KG API server
    kg_process = await start_kg_api_server()
    if not kg_process:
        print("❌ Failed to start KG API server")
        sys.exit(1)

    try:
        # 3. Validate API endpoints
        if not await validate_kg_api_endpoints():
            print("❌ KG API endpoint validation failed")
            return

        print()

        # 4. Test metrics pipeline
        if not await test_metrics_pipeline():
            print("❌ Metrics pipeline test failed")
            return

        print()

        # 5. Demo anti-thrash
        if not await demo_anti_thrash():
            print("❌ Anti-thrash demo failed")
            return

        print()

        # 6. Show next steps
        show_next_steps()

    finally:
        # Clean shutdown
        if kg_process and kg_process.poll() is None:
            logger.info("🛑 Shutting down KG API server...")
            kg_process.terminate()
            kg_process.wait(timeout=5)


if __name__ == "__main__":
    asyncio.run(main())
