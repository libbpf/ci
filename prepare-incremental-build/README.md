[![Action test](https://github.com/libbpf/ci/actions/workflows/test-prepare-incremental-build-action.yml/badge.svg)](https://github.com/libbpf/ci/actions/workflows/test-prepare-incremental-build-action.yml)

# Prepare incremental build

This action uses [actions/cache](https://github.com/actions/cache) in combination with custom scripts to save kernel build output from previous workflow runs to faciliate incremental builds.

## Required inputs

* `repo-root` - Path to the root of the Linux kernel repository.
* `base-branch` - Branch of the kernel repository. This is used to find the commit hash for cache lookup.
* `arch` - Kernel build architecture. Part of the cache key.
* `toolchain_full` - Toolchain name, such as `llvm-17`. Part of the cache key.
* `kbuild-output` - Path to the directory where the kernel build output is saved or restored to. This is passed as `path` to [actions/cache](https://github.com/actions/cache?tab=readme-ov-file#inputs).

## Optional inputs
* `cache-key-prefix` - Prefix for the cache key. Defaults to `kbuild-output`.