#!/usr/bin/python3

import sys

def clean_line(line: str) -> str:
    line = line.split('#')[0] # remove comment
    line = line.strip()       # strip whitespace
    return line

def read_clean_and_sort_input() -> list[str]:
    input = []
    for line in sys.stdin:
        line = clean_line(line)
        if len(line) == 0:
            continue
        input.append(line)
    input.sort()
    return input

def dedup_subtests(lines: list[str]):
    i = 0
    j = 1
    while j < len(lines):
        l1 = lines[i]
        l2 = lines[j]
        # for a pair of "foo_test" and "foo_test/subtest"
        # remove a subtest from the list
        if l1 == l2 or ('/' not in l1) and ('/' in l2) and l2.startswith(l1):
            # print(f"removing '{l2}' because '{l1}' is in the list")
            lines.remove(l2)
        else:
            i += 1
            j += 1

if __name__ == '__main__':
    lines = read_clean_and_sort_input()
    dedup_subtests(lines)
    for line in lines:
        print(line)


