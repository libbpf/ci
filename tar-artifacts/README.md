# Tar build artifacts

This action creates a tarball with kbuild-output and other build
artifacts necessary to run the selftests.

The action is expected to be executed by a workflow with access to the
Linux kernel repository.

## Required inputs

* `arch` - Kernel build architecture, required to find image_name
* `archive` - path to the produced .zst archive
* `kbuild-output` - Path to the kernel build output
* `repo-root` - Path to the root of the Linux kernel repository

# Archive options

Essential content of the directory passed via `kbuild-output` input is
always included in the tarball.

For selftests artifacts the script checks environment variables to
determine what to include. These are handled as bash flags:
emptystring means false, any other value means true.

* `ARCHIVE_BPF_SELFTESTS` - add `tools/testing/selftests/bpf` binaries
  under `selftests/bpf` in the tarball
* `ARCHIVE_MAKE_HELPERS` - add all the Linux repo makefiles and other
  scripts
* `ARCHIVE_SCHED_EXT_SELFTESTS` - add
  `tools/testing/selftests/sched_ext` binaries under
  `selftests/sched_ext` in the tarball



