# Ansible Role: qemu-user-static

## Description

This is needed in order to run different architecture containers by QEMU.

See https://github.com/multiarch/qemu-user-static for more details.

The role merely create the needed systemd unit file and ensure the service is started once.
