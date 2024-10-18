# Build selftests/sched_ext

This action builds selftests/sched_ext given a kernel build
output. Kernel build configuration is supposed to include necessary
flags (i.e. `tools/testing/selftests/sched_ext/config`).

The action is expected to be executed by a workflow with access to the
Linux kernel repository.

## Required inputs

* `kbuild-output` - Path to the kernel build output.
* `repo-root` - Path to the root of the Linux kernel repository.
* `arch` - Kernel build architecture.
* `toolchain` - Toolchain name: `gcc` (default) or `llvm`.

## Optional inputs
* `llvm-version` - LLVM version, used when `toolchain` is `llvm`. Default: `16`.
* `max-make-jobs` - Maximum number of jobs to use when running make (e.g argument to -j). Default: 4*nproc.

