# Ansible Role: base

## Description

This role is used to install basic packages that may be required by any deployment.

Some default packages that apply to both RedHat based and Debian based is set in [defaults/main.yml](defaults/main.yml) file.

Each specific distro that has different package name has a file under [vars/](vars/) with a list of packages (example: `docker.io` for Debian, `podman-docker` for RedHat).

It also provides handler that can be useful to any other roles, such as
- `"reset systemd failed"`: runs `systemctl reset-failed`
- `"reload systemd daemon"`: essentially runs `systemctl daemon-reload`

This role is typically evaluated first.
