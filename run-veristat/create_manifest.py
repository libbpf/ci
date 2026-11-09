#!/usr/bin/env python3
"""Describe selected local objects for a veristat measurement."""

import argparse
import json
import os
from pathlib import Path

from run_veristat import file_sha256


def make_corpus(name, directory, pattern, config, manifest_path):
    parent = Path(manifest_path).absolute().parent
    corpus = {
        "name": name,
        "objects": {
            os.path.relpath(path, parent): file_sha256(path)
            for path in sorted(Path(directory).absolute().glob(pattern))
            if path.is_file()
        },
    }
    if config:
        corpus["filter"] = os.path.relpath(Path(config).absolute(), parent)
    return corpus


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--name", required=True)
    parser.add_argument("--directory", required=True)
    parser.add_argument("--pattern", required=True)
    parser.add_argument("--filter")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    corpus = make_corpus(
        args.name, args.directory, args.pattern, args.filter, args.output
    )
    args.output.write_text(
        json.dumps({"version": 1, "corpora": [corpus]}, indent=2) + "\n"
    )


if __name__ == "__main__":
    main()
