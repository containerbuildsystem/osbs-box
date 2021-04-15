# Docker Hub README

After creating an account (browse to [Docker Hub][]), you will need to add your
account credentials to 'overrides.yaml'[^1] (check [group vars][] for the key names;
they are 'docker_*').

*Please* do not use your actual password; instead, go to your Docker Hub
[Security][] settings page, and click the "New Access Token" button to create a
new token to use in place of your password.

You should end up with something like

  ```yaml
  docker_id: myname
  docker_password: 2daf3987-fa45-4cab-365d-a454bcd365ef
  docker_email: me@work.ez
  ```

in 'overrides.yaml'. From there, proceed with
`ansible-playbook deploy.yaml -i <inventory file> -e @overrides.yaml`

---

[^1]: Create it if it doesn't exist

[Docker Hub]: https://hub.docker.com
[group vars]: ./group_vars/all.yaml
[Security]: https://hub.docker.com/settings/security
