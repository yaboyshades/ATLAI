#!/usr/bin/env python3
"""
Capability Audit CLI for Super Alita
====================================

Command-line interface for the Capability Audit System
"""

import argparse
import asyncio
import sys
from pathlib import Path

# Add the src directory to the path so we can import our modules
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.core.capability_audit import (
    CapabilityStatus,
    CapabilityType,
    capability_registry,
    run_capability_audit,
)


async def cmd_audit(args):
    """Run a full capability audit"""
    print("🔍 Running Super Alita Capability Audit...")
    print("=" * 50)

    audit_results = await run_capability_audit()

    # Display summary
    summary = audit_results["summary"]
    print("\n📊 Audit Summary:")
    print(f"  Total capabilities: {summary['total_capabilities']}")
    print(f"  Total errors: {summary['total_errors']}")
    print(f"  Health score: {summary['health_score']}%")

    print("\n📋 By Category:")
    for category, count in summary["categories"].items():
        if count > 0:
            print(f"  {category}: {count}")

    # Show issues if any
    if audit_results["issues"]:
        print(f"\n⚠️  Issues Found ({len(audit_results['issues'])}):")
        for issue in audit_results["issues"][:5]:  # Show first 5
            print(f"  - {issue['description']}")
        if len(audit_results["issues"]) > 5:
            print(f"  ... and {len(audit_results['issues']) - 5} more")

    # Show recommendations
    if audit_results["recommendations"]:
        print("\n💡 Recommendations:")
        for rec in audit_results["recommendations"]:
            print(f"  - {rec}")

    # Export if requested
    if args.export:
        export_path = args.export
        if capability_registry.export_capabilities(export_path):
            print(f"\n📄 Full report exported to {export_path}")


async def cmd_list(args):
    """List capabilities with optional filtering"""
    # Apply filters
    capability_type = None
    if args.type:
        try:
            capability_type = CapabilityType(args.type)
        except ValueError:
            print(f"❌ Invalid capability type: {args.type}")
            print(f"Valid types: {[t.value for t in CapabilityType]}")
            return

    status = None
    if args.status:
        try:
            status = CapabilityStatus(args.status)
        except ValueError:
            print(f"❌ Invalid status: {args.status}")
            print(f"Valid statuses: {[s.value for s in CapabilityStatus]}")
            return

    tags = args.tags.split(",") if args.tags else None

    # Get capabilities
    capabilities = capability_registry.list_capabilities(
        capability_type=capability_type, status=status, tags=tags
    )

    if not capabilities:
        print("No capabilities found matching the criteria.")
        return

    print(f"Found {len(capabilities)} capabilities:")
    print("-" * 60)

    for cap in capabilities[: args.limit]:
        print(f"📦 {cap.name}")
        print(f"   Type: {cap.capability_type.value}")
        print(f"   Status: {cap.status.value}")
        print(f"   Description: {cap.description}")
        if cap.tags:
            print(f"   Tags: {', '.join(cap.tags)}")
        if cap.usage_count > 0:
            print(f"   Usage: {cap.usage_count} times")
        print()

    if len(capabilities) > args.limit:
        print(f"... and {len(capabilities) - args.limit} more")


async def cmd_search(args):
    """Search capabilities by keyword"""
    results = capability_registry.search_capabilities(args.query)

    if not results:
        print(f"No capabilities found for query: '{args.query}'")
        return

    print(f"Found {len(results)} capabilities matching '{args.query}':")
    print("-" * 60)

    for cap in results[: args.limit]:
        print(f"📦 {cap.name}")
        print(f"   Type: {cap.capability_type.value}")
        print(f"   Description: {cap.description}")
        if cap.tags:
            print(f"   Tags: {', '.join(cap.tags)}")
        print()

    if len(results) > args.limit:
        print(f"... and {len(results) - args.limit} more")


async def cmd_info(args):
    """Show detailed information about a specific capability"""
    cap = capability_registry.get_capability(args.name)

    if not cap:
        print(f"❌ Capability '{args.name}' not found")
        return

    print(f"📦 {cap.name}")
    print("=" * 60)
    print(f"Type: {cap.capability_type.value}")
    print(f"Status: {cap.status.value}")
    print(f"Version: {cap.version}")
    print(f"Author: {cap.author}")
    print(f"Description: {cap.description}")

    if cap.tags:
        print(f"Tags: {', '.join(cap.tags)}")

    if cap.dependencies:
        print(f"Dependencies: {', '.join(cap.dependencies)}")

    if cap.use_cases:
        print("Use Cases:")
        for use_case in cap.use_cases:
            print(f"  - {use_case}")

    if cap.examples:
        print("Examples:")
        for example in cap.examples:
            print(f"  - {example}")

    print(f"Created: {cap.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
    if cap.last_used:
        print(f"Last Used: {cap.last_used.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Usage Count: {cap.usage_count}")

    if cap.file_path:
        print(f"File Path: {cap.file_path}")

    if cap.error_message:
        print(f"❌ Error: {cap.error_message}")


async def cmd_stats(args):
    """Show capability statistics"""
    stats = capability_registry.get_capability_stats()

    print("📊 Capability Statistics")
    print("=" * 40)
    print(f"Total Capabilities: {stats['total_capabilities']}")

    if stats["by_type"]:
        print("\nBy Type:")
        for cap_type, count in stats["by_type"].items():
            print(f"  {cap_type}: {count}")

    if stats["by_status"]:
        print("\nBy Status:")
        for status, count in stats["by_status"].items():
            print(f"  {status}: {count}")

    if stats["most_used"]:
        print("\nMost Used:")
        for item in stats["most_used"]:
            print(f"  {item['name']}: {item['usage_count']} times")

    if stats["recent_additions"]:
        print("\nRecent Additions:")
        for item in stats["recent_additions"]:
            print(f"  {item['name']}: {item['created_at'][:10]}")

    if stats["error_capabilities"]:
        print("\n❌ Capabilities with Errors:")
        for item in stats["error_capabilities"]:
            print(f"  {item['name']}: {item['error']}")


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Super Alita Capability Audit CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s audit                          # Run full audit
  %(prog)s audit --export report.json    # Run audit and export results
  %(prog)s list --type plugin            # List all plugins
  %(prog)s list --status active          # List active capabilities
  %(prog)s search memory                 # Search for memory-related capabilities
  %(prog)s info conversation_plugin      # Show details about specific capability
  %(prog)s stats                         # Show capability statistics
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Audit command
    audit_parser = subparsers.add_parser("audit", help="Run full capability audit")
    audit_parser.add_argument("--export", help="Export results to JSON file")

    # List command
    list_parser = subparsers.add_parser("list", help="List capabilities")
    list_parser.add_argument(
        "--type", help=f"Filter by capability type: {[t.value for t in CapabilityType]}"
    )
    list_parser.add_argument(
        "--status", help=f"Filter by status: {[s.value for s in CapabilityStatus]}"
    )
    list_parser.add_argument("--tags", help="Filter by tags (comma-separated)")
    list_parser.add_argument(
        "--limit", type=int, default=20, help="Maximum number of results to show"
    )

    # Search command
    search_parser = subparsers.add_parser("search", help="Search capabilities")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument(
        "--limit", type=int, default=10, help="Maximum number of results to show"
    )

    # Info command
    info_parser = subparsers.add_parser("info", help="Show capability details")
    info_parser.add_argument("name", help="Capability name")

    # Stats command
    stats_parser = subparsers.add_parser("stats", help="Show capability statistics")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    # Map commands to functions
    commands = {
        "audit": cmd_audit,
        "list": cmd_list,
        "search": cmd_search,
        "info": cmd_info,
        "stats": cmd_stats,
    }

    # Run the command
    try:
        return asyncio.run(commands[args.command](args))
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
        return 1
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback

        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main() or 0)
