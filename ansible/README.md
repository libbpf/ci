## Install `ansible`

```
sudo dnf install -y ansible
```


## Inventory

The [inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) is where we define our hosts, hostgroup, possibly variable...

Using an inventory similar to [inventory_example.yml](inventory_example.yml).

After having changed the github token, one can run the following commands:

Run the playbook against `s390x` only, and in check mode (`-C`):
```
ansible-playbook -i ~/inventory.yml ansible/playbook.yml -C --limit s390x
```

Run the playbook against all hosts in `repo_and_org_runner` group, in check mode and display the change diff `-D`:

```
ansible-playbook -i ~/inventory.yml ansible/playbook.yml -C -D --limit repo_and_org_runner
```


Same, but against all hosts:
```
ansible-playbook -i ~/inventory.yml ansible/playbook.yml -C -D
```

To actually apply the changes, remove `-C`.

