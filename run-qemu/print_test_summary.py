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
- :next_track_button: Skipped: ${json_summary['skipped']}
- :x: Failed: {json_summary['failed']}"""


def console_summary(json_summary: json):
    return f"Success: {json_summary['success']}/{json_summary['success_subtest']}, Skipped: {json_summary['skipped']}, Failed: {json_summary['failed']}"


def log_gh_summary(file, text: str):
    print(text, file=file)


def log_console(text: str):
    print(text)


def group(text: str, title: str = "") -> str:
    return f"""::group::{title}
{text}
::endgroup::"""


def test_error_console_log(test_error: str, test_message: str) -> str:
    error_msg = error(test_error)
    if test_message:
        error_msg += "\n" + test_message.strip()
        return group(error_msg, title=test_error)
    else:
        return error_msg


if __name__ == "__main__":
    args = parse_args()
    step_open_mode = "a" if args.append else "w"
    json_summary = None

    with open(args.json_summary, "r") as f:
        json_summary = json.load(f)

    with open(args.step_summary, step_open_mode) as f:
        log_gh_summary(f, "# Tests summary")
        log_gh_summary(f, markdown_summary(json_summary))

        log_console(notice(console_summary(json_summary)))

        for test in json_summary["results"]:
            test_name = test["name"]
            test_number = test["number"]
            if test["failed"]:
                test_log = f"#{test_number} {test_name}"
                log_gh_summary(f, test_log)
                log_console(test_error_console_log(test_log, test["message"]))

            for subtest in test["subtests"]:
                if subtest["failed"]:
                    subtest_log = f"#{test_number}/{subtest['number']} {test_name}/{subtest['name']}"
                    log_gh_summary(f, subtest_log)
                    log_console(test_error_console_log(subtest_log, subtest["message"]))
