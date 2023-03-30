#!/bin/python3
# prints a summary of the tests to both the console and the job summary:
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#adding-a-job-summary
#
# To test the output of the GH test summary:
# python3 run-qemu/print_test_summary.py  -j run-qemu/fixtures/test_progs.json -s /dev/stderr  > /dev/null
# To test the output of the console:
# python3 run-qemu/print_test_summary.py  -j run-qemu/fixtures/test_progs.json -s /dev/stderr  2> /dev/null

import argparse
import json

from typing import Tuple, Dict, Optional


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-j",
        "--json-summary",
        required=True,
        metavar="FILE",
        help="test_progs's json summary file",
    )
    parser.add_argument(
        "-s",
        "--step-summary",
        required=True,
        metavar="FILE",
        help="Github step summary file",
    )
    parser.add_argument(
        "-a", "--append", action="store_true", help="Append to github step summary file"
    )
    return parser.parse_args()


def notice(text: str) -> str:
    return f"::notice::{text}"


def error(text: str) -> str:
    return f"::error::{text}"


def markdown_summary(json_summary: json):
    return f"""- :heavy_check_mark: Success: {json_summary['success']}/{json_summary['success_subtest']}
- :next_track_button: Skipped: {json_summary['skipped']}
- :x: Failed: {json_summary['failed']}"""


def log_summary(json_summary: json):
    return f"Success: {json_summary['success']}/{json_summary['success_subtest']}, Skipped: {json_summary['skipped']}, Failed: {json_summary['failed']}"


def group(text: str, title: str = "", error: bool = False) -> str:
    if error and title:
        title = f"\033[1;31mError:\033[0m {title}"
    return f"""::group::{title}
{text}
::endgroup::"""


def test_error_console_log(test_error: str, test_message: str) -> str:
    error_msg = error(test_error)
    if test_message:
        error_msg += "\n" + test_message.strip()
        return group(error_msg, title=test_error, error=True)
    else:
        return error_msg


def build_summaries_for_test(
    test: Dict, parent_name: Optional[str] = None, parent_number: Optional[int] = None
) -> Optional[Tuple[str, str]]:
    if not test["failed"]:
        return None
    test_log = f"#{test['number']} {test['name']}"
    if parent_number and parent_name:
        test_log = f"#{parent_number}/{test['number']} {parent_name}/{test['name']}"
    gh_summary = test_log
    console_summary = test_error_console_log(test_log, test["message"])
    return (gh_summary, console_summary)


def build_summaries(json_summary) -> Tuple[str, str]:
    """
    Given a json summary, return strings formatted for the GH summary and GH test step console respectively.
    """
    gh_summary = ["# Tests summary"]
    gh_summary.append(markdown_summary(json_summary))

    console_summary = [notice(log_summary(json_summary))]

    for test in json_summary["results"]:
        test_summaries = build_summaries_for_test(test, None, None)
        if test_summaries:
            gh_summary.append(test_summaries[0])
            console_summary.append(test_summaries[1])

        for subtest in test["subtests"]:
            subtest_summaries = build_summaries_for_test(
                subtest, parent_name=test["name"], parent_number=test["number"]
            )
            if subtest_summaries:
                gh_summary.append(subtest_summaries[0])
                console_summary.append(subtest_summaries[1])

    return "\n".join(gh_summary), "\n".join(console_summary)


if __name__ == "__main__":
    args = parse_args()
    step_open_mode = "a" if args.append else "w"
    json_summary = None

    with open(args.json_summary, "r") as f:
        json_summary = json.load(f)

    gh_summary, console_summary = build_summaries(json_summary)
    with open(args.step_summary, step_open_mode) as f:
        print(gh_summary, file=f)
        print(console_summary)
