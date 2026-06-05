# Ansible Role: base

## Description

This role installs the basic packages required by any deployment on our
Debian-family (Ubuntu / s390x LinuxONE) hosts, starts docker, and performs
common host setup (disabling auditd, and configuring swap on s390x).

The package list lives in [defaults/main.yml](defaults/main.yml).

It also provides handlers that can be useful to any other roles, such as
- `"reset systemd failed"`: runs `systemctl reset-failed`
- `"reload systemd daemon"`: essentially runs `systemctl daemon-reload`

This role is typically evaluated first.
