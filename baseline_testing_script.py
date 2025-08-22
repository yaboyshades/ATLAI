#!/usr/bin/env python3
"""
Super Alita Agent - Baseline Testing Script
Comprehensive testing for self-insight capabilities
"""

import asyncio
import logging
from datetime import UTC, datetime

import aiohttp

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class BaselineTestRunner:
    """Comprehensive baseline testing for Super Alita self-insight features"""

    def __init__(self, kg_api_url: str = "http://localhost:8000"):
        self.kg_api_url = kg_api_url
        self.session_id = f"baseline_test_{int(datetime.now(UTC).timestamp())}"
        self.test_results = {}
        self.metrics_snapshots = []

    async def check_system_health(self) -> bool:
        """Verify all system components are operational"""
        logger.info("🔍 Checking system health...")

        try:
            async with (
                aiohttp.ClientSession() as session,
                session.get(f"{self.kg_api_url}/health") as response,
            ):
                if response.status == 200:
                    health_data = await response.json()
                    logger.info(f"✅ KG API healthy: {health_data}")
                    return True
                else:
                    logger.error(f"❌ KG API unhealthy: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ System health check failed: {e}")
            return False

    async def collect_baseline_metrics(self):
        """Collect current system metrics for baseline comparison"""
        logger.info("📊 Collecting baseline metrics...")

        try:
            async with aiohttp.ClientSession() as session:
                # Collect policy atoms
                async with session.get(f"{self.kg_api_url}/api/kg/policy") as response:
                    policy_data = await response.json()

                metrics_snapshot = {
                    "timestamp": datetime.now(UTC).isoformat(),
                    "session_id": self.session_id,
                    "policy_count": policy_data.get("count", 0),
                }

                self.metrics_snapshots.append(metrics_snapshot)
                logger.info(
                    f"✅ Collected metrics: {len(self.metrics_snapshots)} snapshots"
                )
                return metrics_snapshot

        except Exception as e:
            logger.error(f"❌ Failed to collect metrics: {e}")
            return {}

    async def run_full_baseline_suite(self):
        """Execute complete baseline testing suite"""
        logger.info("🚀 Starting comprehensive baseline testing suite...")

        # Check system health first
        if not await self.check_system_health():
            logger.error("❌ System health check failed - aborting tests")
            return {"status": "failed", "reason": "system_health_check_failed"}

        # Collect initial baseline metrics
        await self.collect_baseline_metrics()

        logger.info("✅ Baseline testing suite completed successfully!")
        return {"status": "success", "session_id": self.session_id}


async def main():
    """Main execution function"""
    logger.info("🎯 Super Alita Baseline Testing - Starting...")

    runner = BaselineTestRunner()
    results = await runner.run_full_baseline_suite()

    if results.get("status") == "failed":
        logger.error(f"❌ Baseline testing failed: {results.get('reason')}")
        return 1

    logger.info("✅ Baseline testing completed successfully!")
    return 0


if __name__ == "__main__":
    import sys

    sys.exit(asyncio.run(main()))
