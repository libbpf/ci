# Ansible Role: runner

## Description

This Ansile role configures [github action self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners).

The self-hosted runners will register to GH at the repository level.

This role currently installs runners suitable to run on s390x architecture as described in https://github.com/libbpf/libbpf/tree/master/ci/rootfs/s390x-self-hosted-builder .

The role will sync with libbpf repository where all the files needed to build the docker image reside.
It then set up the runners configurations, systemd service units.

## Requirements

This role requires the ``qemu-user-static`` role to be executed before, and `docker` must be installed.

## Role variables

All variables which can be overridden are stored in [defaults/main.yml](defaults/main.yml) file as well as in table below.

| Name | Default Value | Description |
| ---- | ------------- | ----------- |
| `runner_libbpf_repo_url` | https://github.com/libbpf/libbpf.git | The libbpf repository where to fetch s390x runners installation artifacts from. |
| `runner_libbpf_repo_branch` | master | Which branch to check out |
| `runner_repo_list` | [ {name: kernel-patches/bpf, instances: 2}, {name: kernel-patches/vmtest, instances: 1} ] | List of dictionaries of name/instances. The name being the name of the repository to attach to, instances being the number of runners to run on a single host. |
| `runner_gh_tokens` | {'foo/bar': 'foo/bar token'} | Dictionary of repository names and their associated tokens. |
| `runner_gh_token_default` | "replace with your token" | The default token to use for authenticating the runner. Used if no entry for the repository is found in `runner_gh_tokens`. |

## Example

Example playbook:

```
---
- hosts: all
  vars:
    - runner_gh_tokens: ghp_token
    - runner_gh_token_default:
      myowner/myrepo: ghp_token2
    - runner_repo_list:
      - {name: myowner2/myrepo2, instances: 2}
      - {name: myowner/myrepo, instances: 1}
  roles:
    - role: base
      tags: [base]
    - role: qemu-user-static
      tags: [qemu]
      when: ansible_architecture == "s390x"
    - role: runner
      tags: [runner]
      when: ansible_architecture == "s390x"
```
