#!/usr/bin/env python3
"""
Super Alita - Baseline Testing Monitor
Real-time monitoring and validation of self-insight features during baseline testing
"""

import asyncio
import json
import logging
from datetime import UTC, datetime

import aiohttp

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("baseline_monitor.log"), logging.StreamHandler()],
)

logger = logging.getLogger(__name__)


class BaselineMonitor:
    """Real-time monitoring for Super Alita baseline testing"""

    def __init__(self, kg_api_url: str = "http://localhost:8000"):
        self.kg_api_url = kg_api_url
        self.session_id = f"monitor_{int(datetime.now(UTC).timestamp())}"
        self.monitoring_active = True
        self.metrics_history = []
        self.test_results = {}

    async def check_kg_api_health(self) -> bool:
        """Check if KG API is responding"""
        try:
            async with (
                aiohttp.ClientSession() as session,
                session.get(
                    f"{self.kg_api_url}/health", timeout=aiohttp.ClientTimeout(total=5)
                ) as response,
            ):
                if response.status == 200:
                    health_data = await response.json()
                    logger.info(
                        f"✅ KG API healthy: {health_data.get('status', 'unknown')}"
                    )
                    return True
                else:
                    logger.warning(f"⚠️ KG API status: {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ KG API health check failed: {e}")
            return False

    async def collect_metrics_snapshot(self) -> dict:
        """Collect current metrics from all endpoints"""
        snapshot = {
            "timestamp": datetime.now(UTC).isoformat(),
            "session_id": self.session_id,
        }

        try:
            async with aiohttp.ClientSession() as session:
                # Collect from all KG API endpoints
                endpoints = [
                    ("/metrics", "prometheus_metrics"),
                    ("/api/kg/policy", "policy_data"),
                    ("/api/kg/personality", "personality_data"),
                    ("/api/kg/consolidation", "consolidation_data"),
                ]

                for endpoint, key in endpoints:
                    try:
                        async with session.get(
                            f"{self.kg_api_url}{endpoint}"
                        ) as response:
                            if response.status == 200:
                                if endpoint == "/metrics":
                                    snapshot[key] = await response.text()
                                else:
                                    snapshot[key] = await response.json()
                                logger.debug(f"✅ Collected {key}")
                            else:
                                logger.warning(
                                    f"⚠️ {endpoint} returned {response.status}"
                                )
                                snapshot[key] = f"ERROR_{response.status}"
                    except Exception as e:
                        logger.error(f"❌ Failed to collect {key}: {e}")
                        snapshot[key] = f"ERROR_{str(e)}"

                self.metrics_history.append(snapshot)
                return snapshot

        except Exception as e:
            logger.error(f"❌ Failed to collect metrics snapshot: {e}")
            return snapshot

    async def analyze_decision_confidence_trends(self) -> dict:
        """Analyze decision confidence patterns from metrics history"""
        if len(self.metrics_history) < 2:
            return {"status": "insufficient_data", "samples": len(self.metrics_history)}

        logger.info("📊 Analyzing decision confidence trends...")

        # Extract policy changes over time
        policy_counts = []
        for snapshot in self.metrics_history:
            policy_data = snapshot.get("policy_data", {})
            if isinstance(policy_data, dict):
                policy_counts.append(policy_data.get("count", 0))

        # Extract personality changes
        personality_changes = []
        for snapshot in self.metrics_history:
            personality_data = snapshot.get("personality_data", {})
            if isinstance(personality_data, dict) and personality_data.get("latest"):
                personality_changes.append(personality_data["latest"])

        analysis = {
            "timestamp": datetime.now(UTC).isoformat(),
            "total_snapshots": len(self.metrics_history),
            "policy_trend": {
                "initial_count": policy_counts[0] if policy_counts else 0,
                "current_count": policy_counts[-1] if policy_counts else 0,
                "total_growth": (policy_counts[-1] - policy_counts[0])
                if len(policy_counts) >= 2
                else 0,
            },
            "personality_evolution": {
                "snapshots_with_data": len(personality_changes),
                "has_personality_data": len(personality_changes) > 0,
            },
            "consolidation_insights": len(
                [
                    s
                    for s in self.metrics_history
                    if s.get("consolidation_data", {}).get("count", 0) > 0
                ]
            ),
        }

        logger.info(
            f"📈 Policy atoms: {analysis['policy_trend']['initial_count']} → {analysis['policy_trend']['current_count']}"
        )
        logger.info(
            f"🧠 Personality snapshots: {analysis['personality_evolution']['snapshots_with_data']}"
        )

        return analysis

    async def monitor_conversation_activity(self) -> None:
        """Monitor for conversation activity and insight generation"""
        logger.info("👂 Monitoring for conversation activity...")

        # This would integrate with the agent's event bus in a real implementation
        # For now, we'll monitor the API for changes
        previous_policy_count = 0
        previous_consolidation_count = 0

        while self.monitoring_active:
            try:
                snapshot = await self.collect_metrics_snapshot()

                # Check for policy changes (indicating decision confidence events)
                policy_data = snapshot.get("policy_data", {})
                if isinstance(policy_data, dict):
                    current_policy_count = policy_data.get("count", 0)
                    if current_policy_count > previous_policy_count:
                        logger.info(
                            f"🎯 NEW POLICY DETECTED: {current_policy_count - previous_policy_count} new policies"
                        )
                        previous_policy_count = current_policy_count

                # Check for consolidation changes (indicating cross-session insights)
                consolidation_data = snapshot.get("consolidation_data", {})
                if isinstance(consolidation_data, dict):
                    current_consolidation_count = consolidation_data.get("count", 0)
                    if current_consolidation_count > previous_consolidation_count:
                        logger.info(
                            f"🔄 NEW INSIGHTS: {current_consolidation_count - previous_consolidation_count} new consolidations"
                        )
                        previous_consolidation_count = current_consolidation_count

                # Wait before next check
                await asyncio.sleep(5)

            except Exception as e:
                logger.error(f"❌ Monitoring error: {e}")
                await asyncio.sleep(5)

    async def generate_baseline_report(self) -> dict:
        """Generate comprehensive baseline testing report"""
        logger.info("📋 Generating baseline testing report...")

        # Analyze trends
        trends = await self.analyze_decision_confidence_trends()

        # Generate final report
        report = {
            "session_info": {
                "session_id": self.session_id,
                "start_time": self.metrics_history[0]["timestamp"]
                if self.metrics_history
                else datetime.now(UTC).isoformat(),
                "end_time": datetime.now(UTC).isoformat(),
                "total_monitoring_duration": len(self.metrics_history)
                * 5,  # 5 second intervals
            },
            "system_health": {
                "kg_api_operational": await self.check_kg_api_health(),
                "total_snapshots_collected": len(self.metrics_history),
            },
            "baseline_analysis": trends,
            "test_validation": {
                "decision_confidence_active": trends.get("policy_trend", {}).get(
                    "total_growth", 0
                )
                > 0,
                "personality_tracking_active": trends.get(
                    "personality_evolution", {}
                ).get("has_personality_data", False),
                "insight_consolidation_active": trends.get("consolidation_insights", 0)
                > 0,
            },
            "recommendations": [
                "Continue monitoring during active conversations for real-time validation",
                "Execute decision confidence test cases (BT-DC-001, BT-DC-002, BT-DC-003)",
                "Test learning velocity with repeated task sequences",
                "Validate hypothesis lifecycle with complex reasoning tasks",
                "Test cross-session insight persistence with agent restarts",
            ],
        }

        # Save report
        report_filename = f"baseline_monitoring_report_{self.session_id}.json"
        with open(report_filename, "w") as f:
            json.dump(report, f, indent=2)

        logger.info(f"📄 Baseline monitoring report saved: {report_filename}")
        return report

    async def run_monitoring_session(self, duration_minutes: int = 10) -> dict:
        """Run a complete monitoring session"""
        logger.info(
            f"🚀 Starting {duration_minutes}-minute baseline monitoring session..."
        )

        # Check initial system health
        if not await self.check_kg_api_health():
            logger.error("❌ KG API not healthy - cannot start monitoring")
            return {"status": "failed", "reason": "kg_api_unhealthy"}

        # Collect initial snapshot
        await self.collect_metrics_snapshot()
        logger.info("✅ Initial metrics snapshot collected")

        # Start monitoring task
        monitor_task = asyncio.create_task(self.monitor_conversation_activity())

        try:
            # Monitor for specified duration
            await asyncio.sleep(duration_minutes * 60)

        except KeyboardInterrupt:
            logger.info("⚠️ Monitoring interrupted by user")
        finally:
            # Stop monitoring
            self.monitoring_active = False
            monitor_task.cancel()

            try:
                await monitor_task
            except asyncio.CancelledError:
                pass

        # Generate final report
        final_report = await self.generate_baseline_report()

        logger.info("✅ Baseline monitoring session completed!")
        return final_report


async def main():
    """Main monitoring execution"""
    logger.info("🎯 Super Alita Baseline Monitor - Starting...")

    monitor = BaselineMonitor()

    try:
        # Run 10-minute monitoring session
        results = await monitor.run_monitoring_session(duration_minutes=10)

        if results.get("status") == "failed":
            logger.error(f"❌ Monitoring failed: {results.get('reason')}")
            return 1

        logger.info("✅ Baseline monitoring completed successfully!")
        logger.info("📋 Check baseline_monitoring_report_*.json for detailed results")
        return 0

    except Exception as e:
        logger.error(f"❌ Monitoring session failed: {e}")
        return 1


if __name__ == "__main__":
    import sys

    sys.exit(asyncio.run(main()))
