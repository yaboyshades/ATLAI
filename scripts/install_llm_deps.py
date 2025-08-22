#!/usr/bin/env python3
"""
Script to install or update dependencies needed for LLM integration.
This will install the latest versions of the required packages for Gemini and OpenAI APIs.
"""

import subprocess
import sys


def main():
    """Install LLM provider dependencies."""
    print("Installing/updating LLM provider dependencies...")

    # Determine if we're in a virtual environment
    in_venv = sys.prefix != sys.base_prefix
    pip_cmd = [sys.executable, "-m", "pip"]

    # Required packages
    packages = [
        "python-dotenv==1.0.0",  # For loading environment variables
        "google-generativeai==0.3.2",  # Gemini API client
        "openai==1.6.1",  # OpenAI API client
        "proto-plus==1.23.0",  # Required by google-generativeai
    ]

    # Install each package
    for package in packages:
        print(f"\nInstalling {package}...")
        result = subprocess.run(
            [*pip_cmd, "install", "--upgrade", package],
            capture_output=True,
            text=True,
            check=False,
        )

        if result.returncode == 0:
            print(f"✅ Successfully installed {package}")
        else:
            print(f"❌ Failed to install {package}:")
            print(result.stderr)

    print("\n" + "=" * 60)
    print("LLM provider dependencies installation complete!")
    print(f"Installed in: {'virtual environment' if in_venv else 'system Python'}")
    print("=" * 60)

    # Additional instructions for API keys
    print("\nImportant: Make sure your API keys are set in the .env file:")
    print("  - GEMINI_API_KEY for Google Generative AI")
    print("  - OPENAI_API_KEY for OpenAI")


if __name__ == "__main__":
    main()
