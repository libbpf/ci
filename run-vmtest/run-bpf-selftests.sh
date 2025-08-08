#!/bin/bash

# This script is expected to be executed by vmtest program (a qemu
# wrapper). By default vmtest mounts working directory to /mnt/vmtest,
# which is why this path is often assumed in the script. The working
# directory is usually (although not necessarily) the
# $GITHUB_WORKSPACE of the Github Action workflow, calling
# libbpf/ci/run-vmtest action.
# See also action.yml and run.sh
#
# The script executes the tests within $SELFTESTS_BPF directory.
# Runners passed as arguments are executed. In case of no arguments,
# all test runners are executed.

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

ARCH=$(uname -m)

export SELFTESTS_BPF=${SELFTESTS_BPF:-/mnt/vmtest/selftests/bpf}

STATUS_FILE=${STATUS_FILE:-/mnt/vmtest/exitstatus}
OUTPUT_DIR=${OUTPUT_DIR:-/mnt/vmtest}

test_progs_helper() {
  local selftest="test_progs${1}"
  local args=("$2")

  if [ "${args[0]}" == "" ]; then
	args=("${args[@]:1}")
  fi

  json_file=${selftest/-/_}
  if [ "$2" == "-j" ]
  then
    json_file+="_parallel"
  fi
  json_file="${OUTPUT_DIR}/${json_file}.json"

  args+=(${TEST_PROGS_WATCHDOG_TIMEOUT:+-w$TEST_PROGS_WATCHDOG_TIMEOUT})
  args+=(${ALLOWLIST_FILE:+-a@$ALLOWLIST_FILE})
  args+=(${DENYLIST_FILE:+-d@$DENYLIST_FILE})
  args+=(-J "${json_file}")
  args+=(${TEST_PROGS_TRAFFIC_MONITOR:+-m '*'})

  foldable start ${selftest} "Testing ${selftest}"
  echo "./${selftest}" "${args[@]}"
  # "&& true" does not change the return code (it is not executed
  # if the Python script fails), but it prevents exiting on a
  # failure due to the "set -e".
  ./${selftest} "${args[@]}" && true
  echo "${selftest}:$?" >>"${STATUS_FILE}"
  foldable end ${selftest}
}

test_progs() {
  test_progs_helper "" ""
}

test_progs_parallel() {
  test_progs_helper "" "-j"
}

test_progs_no_alu32() {
  test_progs_helper "-no_alu32" ""
}

test_progs_no_alu32_parallel() {
  test_progs_helper "-no_alu32" "-j"
}

test_progs_cpuv4() {
  test_progs_helper "-cpuv4" ""
}

test_maps() {
  foldable start test_maps "Testing test_maps"
  taskset 0xF ./test_maps && true
  echo "test_maps:$?" >>"${STATUS_FILE}"
  foldable end test_maps
}

test_verifier() {
  foldable start test_verifier "Testing test_verifier"
  ./test_verifier && true
  echo "test_verifier:$?" >>"${STATUS_FILE}"
  foldable end test_verifier
}

test_progs-bpf_gcc() {
    test_progs_helper "-bpf_gcc" ""
}

export VERISTAT_TARGET=${VERISTAT_TARGET:-kernel}
export VERISTAT_CONFIGS=${VERISTAT_CONFIGS:-/mnt/vmtest/ci/vmtest/configs}
export WORKING_DIR=$(pwd) # veristat config expects this variable

run_veristat() {
  foldable start run_veristat_${VERISTAT_TARGET} "Running veristat ${VERISTAT_TARGET}"
  # Make veristat commands visible in the log
  if [ -o xtrace ]; then
      xtrace_was_on="1"
  else
      xtrace_was_on=""
      set -x
  fi

  (
    # shellcheck source=ci/vmtest/configs/run_veristat.default.cfg
    # shellcheck source=ci/vmtest/configs/run_veristat.meta.cfg
    source "${VERISTAT_CONFIGS}/run_veristat.${VERISTAT_TARGET}.cfg"
    pushd "${VERISTAT_OBJECTS_DIR}"

    args=()
    args+=(-o csv)
    args+=(-q)
    args+=(-e file,prog,verdict,states)
    args+=(${VERISTAT_CFG_FILE:+-f@$VERISTAT_CFG_FILE})

    "${SELFTESTS_BPF}/veristat" "${args[@]}" ${VERISTAT_OBJECTS_GLOB} > \
      "${OUTPUT_DIR}/${VERISTAT_OUTPUT}"

    echo "run_veristat_${VERISTAT_TARGET}:$?" >> ${STATUS_FILE}
    popd
  )

  # Hide commands again
  if [ -z "$xtrace_was_on" ]; then
      set +x
  fi
  foldable end run_veristat_${VERISTAT_TARGET}
}

foldable end vm_init

foldable start kernel_config "Kconfig"
zcat /proc/config.gz
foldable end kernel_config


if [ -f "${ALLOWLIST_FILE:-}" ]; then
  foldable start allowlist "Print ALLOWLIST"
  cat "${ALLOWLIST_FILE}"
  foldable end allowlist
else
  echo "ALLOWLIST_FILE=${ALLOWLIST_FILE:-} is not set or does not exist"
fi

if [ -f "${DENYLIST_FILE:-}" ]; then
  foldable start denylist "Print DENYLIST"
  cat "${DENYLIST_FILE}"
  foldable end denylist
else
  echo "DENYLIST_FILE=${DENYLIST_FILE:-} is not set or does not exist"
fi

cd $SELFTESTS_BPF

declare -a TEST_NAMES=($@)
# if we don't have any test name provided to the script, we run all tests.
if [ ${#TEST_NAMES[@]} -eq 0 ]; then
	test_progs
	test_progs_no_alu32
	test_progs_cpuv4
	test_maps
	test_verifier
	if [ -f test_progs-bpf_gcc ]; then
		test_progs-bpf_gcc
	fi
else
	# else we run the tests passed as command-line arguments and through boot
	# parameter.
	for test_name in "${TEST_NAMES[@]}"; do
		"${test_name}"
	done
fi
