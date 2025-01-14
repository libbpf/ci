# Run vmtest

This action is designed to run Linux Kernel BPF selftests.

It expects kernel binaries as well as test runner binaries as input,
and executes the test runners with a given kernel using the [vmtest
tool](https://github.com/danobi/vmtest).

In summary the action performs the following:
* Download specified vmtest release
* Install qemu and other dependencies (assuming Ubuntu environment)
* Configure access to [/dev/kvm](https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine)
* Execute run.sh
  * Set up the environment variables
  * Choose runner scripts
  * Run vmtest
  * Collect and test results and report

Note that behavior of the running scripts is tunable mostly by the
environment variables.

## Required inputs

* `arch` - Target architecture

## Optional inputs

* `kernel-root` (default: current dir) - path to the root of Linux Kernel source tree
* `kernel-test` - controls what test runners are executed
  * can be a name of a test runner program, such as `test_progs`
  * if not set, all known test runners will run one-by-one, see `run-bpf-selftests.sh`
  * if set to `sched_ext`, then `run-scx-selftests.sh` is executed
* `max-cpu` - limit number of cpus to use
* `vmlinuz` - path to the kernel bzImage, passed to vmtest
  * if not specified, `$VMLINUZ` var is checked
  * if `$VMLINUZ` is not set, the script will attempt to run `make -s
    image_name` to find the image
* `output-dir` - path for test runner summaries and veristat output
* `kbuild-output` (default: `./kbuild-output`) - path to Linux Kernel binaries, aka `$KBUILD_OUTPUT`
* `vmtest-release` - release version name of the vmtest tool

## run-vmtest.env

There are a couple of scripts, as well as code in the
`run-bpf-selftests.sh` that handles ALLOWLIST and DENYLIST, which are
very important in context of CI.

Typically there is a need for granular lists, such as per arch list,
per kernel version, per test runner, etc. And so it is often necessary
to pre-process a number of lists into one, which is then passed to the
test runner.

To avoid copy-pasting merging scripts between the action users, a
special file `$VMTEST_CONFIGS/run-vmtest.env` is sourced by
`run.sh`.

run-vmtest.env is expected to export `SELFTESTS_BPF_ALLOWLIST_FILES`
and `SELFTESTS_BPF_DENYLIST_FILES`, which are pipe-separated lists of
files. These variables are then used by `prepare-bpf-selftests.sh` to
produce final allow/denylist passed to the runners. If these variables
are not set, `prepare-bpf-selftests.sh` does nothing.

See `ci/vmtest/configs/run-vmtest.env` for an example.

