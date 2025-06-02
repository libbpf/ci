# Build sched_ext schedulers

This action builds schedulers from https://github.com/sched-ext/scx/

## Required inputs

* `output-dir` - Path to the output directory, where built artifacts will be placed.

## Environment variables

* `LLVM_VERSION` - LLVM (clang) version. Default: `20`.
* `SCX_ROOT` - Path to the SCX repository. If not set (default), the action will clone the main branch of https://github.com/sched-ext/scx to a temporary directory.