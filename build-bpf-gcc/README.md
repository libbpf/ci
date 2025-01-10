# Build BPF GCC

This action grabs latest GCC 15 source code snapshot from
https://gcc.gnu.org/pub/gcc/snapshots, as well as most recent
binutils, and builds GCC for BPF backend and installs it into a
specified directory.

Resulting artifacts are cached with
[actions/cache](https://github.com/actions/cache), using snapshot
names as a key.

## Required inputs

* `install-dir` - Path to the directory where built binaries are going to be installed, or restored from cache.

