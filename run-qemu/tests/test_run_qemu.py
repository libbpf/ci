#!/usr/bin/env python3

import json
import unittest

from pathlib import Path

from print_test_summary import build_summaries

THIS_DIR = Path(__file__).parent
FIXTURE_DIR = THIS_DIR / "fixtures"


def read_file(fname: str) -> str:
    with open(fname) as f:
        return f.read()


class TestPrintTestSummary(unittest.TestCase):
    def test_build_summaries(self) -> None:
        """
        Test that our script generate the expected output.
        If this fail because of expected output changes, regenerate
        the fixture with:
        ```
        python3 print_test_summary.py -j tests/fixtures/test_progs.json -s tests/fixtures/test_progs.summary > tests/fixtures/test_progs.console\
        ```
        """
        input = read_file(FIXTURE_DIR / "test_progs.json")
        expected_summary = read_file(FIXTURE_DIR / "test_progs.summary").strip()
        expected_console = read_file(FIXTURE_DIR / "test_progs.console").strip()

        summary, console = build_summaries(json.loads(input))

        self.assertEqual(summary, expected_summary)
        self.assertEqual(console, expected_console)
