#!/bin/bash
set -euo pipefail
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=.. python3 -m unittest -bv test_runner
