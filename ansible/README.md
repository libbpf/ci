## Install `ansible`

```
sudo dnf install -y ansible
```

## SSH keys
`ansible` uses SSH to connect to hosts. We can put the s390x machines key in our ssh authentication agent to automatically authenticate without having to keep a copy of the key on our dev server:

```
ssh-add <(secrets_tool get_from_group KERNEL_PATCHES_S390X_SSH_PRIVATE_KEY KERNEL_PATCHES_KEYS)
```

## Inventory

The [inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) is where we define our hosts, hostgroup, possibly variable...

Using an inventory similar to P531683832.

After having changed the github token, one can run the following commands:

Run the playbook against `bpf-ci-runner-s390x` only, and in check mode (`-C`):
```
ansible-playbook -i ~/inventory.yml ansible/playbook.yml -C --limit bpf-ci-runner-s390x
```

Run the playbook against all hosts in `s390x_odd` group, in check mode and display the change diff `-D`:

```
ansible-playbook -i ~/inventory.yml ansible/playbook.yml -C -D --limit s390x_odd
```
See output in P531732743 .

Same, but against all hosts:
```
ansible-playbook -i ~/inventory.yml ansible/playbook.yml -C -D
```

To actually apply the changes, remove `-C`.
