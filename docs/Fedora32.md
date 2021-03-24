# Fedora 32 Workstation Prerequisites

## Packages

- docker
- origin-clients
- python-devel

## Other tweaks

- Adding insecure registry setting to `/etc/sysconfig/docker`
- Adding `systemd.unified_cgroup_hierarchy=0` to `/boot/efi/EFI/fedora/grubenv`

  *This is required due to a limitation of the docker engine (moby) available
  to Fedora 32 Workstation*
- Rebooting after the above setting changes are made.

## Ansible Playbook

`prequisite-playbooks/Fedora32-prerequisites.yaml` installs the required
packages and tweaks.

### Example

`> sudo ansible-playbook prequisite-playbooks/Fedora32-prerequisites.yaml
-i inventory-example.yaml`

```text
PLAY [Install Tools] *********************************************************

TASK [Gathering Facts] *******************************************************
ok: [localhost]

TASK [enable ssh] ************************************************************
ok: [localhost]
.
.
.
```
