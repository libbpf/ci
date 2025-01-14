#!/usr/bin/python3

# This script normalizes a list of selftests/bpf test names. These
# lists have the following format:
#    * each line indicates a test name
#    * a line can contain an end-line comment, starting with #
#
# The test names may contain spaces, commas, and potentially other characters.
#
# The purpose of this script is to take in a composite allow/denylist
# (usually produced as an append of multiple different lists) and
# transform it into one clean deduplicated list.
#
# In addition to dedup of tests by exact match, subtests are taken
# into account. For example, one source denylist may contain a test
# "a_test/subtest2", and another may contain simply "a_test". In such
# case "a_test" indicates that no subtest of "a_test" should run, and
# so "a_test/subtest2" shouldn't be in the list.
#
# The result is printed to stdout

import sys

def clean_line(line: str) -> str:
    line = line.split('#')[0] # remove comment
    line = line.strip()       # strip whitespace
    return line

def read_clean_and_sort_input(file) -> list[str]:
    input = []
    for line in file:
        line = clean_line(line)
        if len(line) == 0:
            continue
        input.append(line)
    input.sort()
    return input

# Deduplicate subtests and yield the next unique test name
def next_test(lines: list[str]):

    if not lines:
        return

    prev = lines[0]

    def is_subtest(line: str) -> bool:
        return ('/' in line) and ('/' not in prev) and line.startswith(prev)

    yield lines[0]
    for line in lines[1:]:
        if prev == line or is_subtest(line):
            continue
        yield line
        prev = line


if __name__ == '__main__':

    if len(sys.argv) != 2:
        print("Usage: merge_test_lists.py <filename>", file=sys.stderr)
        sys.exit(1)

    lines = []
    with open(sys.argv[1]) as file:
        lines = read_clean_and_sort_input(file)

    for line in next_test(lines):
        print(line)

