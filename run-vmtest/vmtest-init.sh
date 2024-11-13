#!/bin/bash

/bin/mount bpffs /sys/fs/bpf -t bpf
ip link set lo up

