#!/usr/bin/env bash
set -euo pipefail

# Run repository checks
if command -v busted >/dev/null 2>&1; then
    echo "Running Busted tests..."
    busted -e 'require("tests.spec_helper")' tests "$@"
else
    echo "Busted is not installed. Skipping tests."
    echo "Install it via: sudo apt-get install lua-busted"
fi
