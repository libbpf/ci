# Run veristat

`run_veristat.py` measures prepared BPF corpora against the running kernel.
It requires Python 3 and a veristat executable. The caller prepares the objects,
boots the kernel, and handles baselines and publication.

```sh
python3 run_veristat.py --veristat /tools/veristat \
    --manifest /inputs/manifest.json --output /results/current
```

The manifest selects exact objects and optional veristat filter files. Paths
are relative to the manifest directory; corpus names must be unique directory
names and object basenames must be unique within each corpus.

```json
{
  "version": 1,
  "corpora": [
    {
      "name": "kernel",
      "objects": {"kernel/example.bpf.o": "<sha256>"},
      "filter": "kernel/veristat.cfg"
    }
  ]
}
```

The output directory must be new. The runner checks object SHA256s and runs
one veristat process per corpus with `-o csv -q -e file,prog,verdict,states`.
Each corpus gets `results.csv`, `stderr.log`, and an atomic `status.json`.
Status is `running`, `measured`, or `error`; a missing status means the corpus
was not started. Interrupted and partial results must not be cached as measured.

`measured` requires a zero tool exit status and nonempty, valid program records.
Rejected programs remain CSV data for the caller's comparison policy.
The runner continues after a corpus error and returns nonzero if any corpus
could not be measured. The VM launcher handles VM failure and timeouts.

Status includes the corpus digest: SHA256 of the sorted SHA256SUMS-style
`<sha256>  <basename>\n` listing. Source/build details and directory locations
do not participate in object identity.

Diagnostics go to stderr: run inputs, corpus progress, and completion or failure
details. Messages are flushed so an interrupted run retains its last operation.
Tool output stays in files. The caller controls visibility of the result files
and VM console. Meta objects and raw verifier logs must remain private; OSS
callers can publish their results.

## Prepare a corpus

`create_manifest.py` selects local files by glob and records their checksums:

```sh
python3 create_manifest.py --name kernel --directory /inputs/kernel \
    --pattern '*.bpf.o' --filter /inputs/kernel/veristat.cfg \
    --output /inputs/manifest.json
```

Omit `--filter` when none is needed. A batch caller can use `make_corpus()`
to build the manifest's `corpora` list. Downloads and builds belong to the caller.

## Run with run-vmtest

Select `run-vmtest/run-veristat.sh` through `VMTEST_SCRIPT` and supply guest paths:

```sh
VERISTAT_BINARY=/mnt/vmtest/selftests/bpf/veristat
VERISTAT_MANIFEST=/mnt/vmtest/manifest.json
VERISTAT_RESULTS=/mnt/vmtest/veristat-results
```

The entrypoint records `veristat:<exitcode>` in `STATUS_FILE` (default
`/mnt/vmtest/exitstatus`) and runs the kernel-splat check. The host `run.sh`
collects those statuses after the guest exits and fails the action on errors.
Per-corpus outcomes remain in the result JSON files.

When upgrading from v4, migrate `kernel-test: run_veristat` callers to this
entrypoint and prepare their manifests before booting the VM.
