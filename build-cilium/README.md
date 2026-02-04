# Build cilium bpf programs

This action builds programs in bpf/ directory from https://github.com/cilium/cilium

## Required inputs

* `output-dir` - Path to the output directory, where built artifacts will be placed.

## Environment variables

* `LLVM_VERSION` - LLVM (clang) version. Default: `20`.
* `CILIUM_ROOT` - Path to the cilium repository. If not set (default), the action will clone the main branch of https://github.com/cilium/cilium to a temporary directory.
