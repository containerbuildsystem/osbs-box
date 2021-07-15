# OSBS-Box

An OpenShift based project that provides an environment for testing OSBS
components.

OSBS-Box for OpenShift 4.x is *not* intended to run locally, and assumes a
multi-tenant cluster, to which you have cluster admin credentials, and which
either *has* Filesystem-capable PVs, or can be so configured.

Basic usage is described [below](#basic-usage)

## Requirements

- Locally (on your laptop/desktop)
  - Python >= 3.6
  - Ansible >= 2.9
  - sshd (e.g. from the 'openssh-server' RPM) installed/configured/running
  - A working `oc` (e.g. from the 'openshift-clients' RPM, but I *highly*
    recommend manually downloading it from [cloud.redhat.com][], as the RPM
    version is *very* old)
- A working OCP 4.x cluster, on which you have an account. CRC (
  [CodeReady Containers][]; basically the OS 4 equivalent of OS 3’s `oc cluster`,
  i.e. a single-node development cluster) has been tested and should work, as
  should any "normal" OCP cluster hosted pretty much anywhere. **NOTE** that
  cluster admin access is ***required***

In the examples given throughout this doc, I'll use CRC-specific values instead
of placeholders, to help make things more concrete, and similarly, I'll use my
username ('balkov') as the value for $USER.

## Assumptions

- The `oc` command is  available **locally**
- A working OpenShift 4 cluster is readily available to deploy into

  This can be an OpenShift 4 cluster running in someone’s cloud, on baremetal in
  your basement, or in a VM somewhere which is hosting CRC (I would *avoid*
  trying to run CRC locally - its resource requirements are very high)
- You have a user account therein
- **You have access to cluster admin credentials** (unfortunately)
- Given that we might deploy into a running cluster somewhere, we want to be a
  good neighbor. OSBS-Box will create Projects prefixed with (local)
  $USER, to avoid conflicts with existing Projects/Namespaces (you’ll need to
  put your OpenShift account name in [inventory.ini][] if it differs from $USER).
  This makes it possible for a team which is using a shared OpenShift 4 dev
  environment to run multiple deployments of OSBS in parallel.
- Backing storage is *not* created/configured. Simple Filesystem PVCs are
  requested, so if you don’t already have PVs which can provide that, you will
  need to set some up. Note that CRC provides 30 100G PVs by default.

Everything is already configured to deploy to a default configured CRC cluster
instance. Cloning this repo as it stands and running the playbooks against a CRC
cluster should Just Work.

## Pre steps

- `git clone` this repository
- In an 'overrides.yaml' file, you will need
  - For the OCP cluster
    - 'osbs_box_host': Locally-resolvable hostname
    - 'openshift_api': API URL

    CodeReady Containers is the default, i.e. with
    - `osbs_box_host: "apps-crc.testing"`
    - `openshift_api: "https://api.crc.testing:6443"`

  - 'kubeadmin_pwd': The password for `kubeadmin`, or another cluster admin.
    **There's no way to work around this requirement**
  - 'ocp_dev_account': (optional) Your OCP account name, **if** it differs from your
    local username
  - 'ocp_dev_passwd': Your OCP account password
  - Your dockerhub credentials as noted in [dockerhub.md][]. You *must* have a
      [Docker Hub] account of some kind to avoid hourly limits on image pulls.
      Depending on how you use OSBS-Box, you *might* require a paid account, as
      you *might* even hit the free account's limit.
- ansible *might* require an initial ssh login to localhost (use '-k' option)

## Deployment

- Run `ansible-playbook deploy.yaml -i inventory.ini -e @overrides.yaml`

  If you are **sure** that you do not need to re-generate certificates, use
  `--tags=openshift`

  Modifications to the inventory file are possible, but not necessary.

**NOTE**: [deploy.yaml][] only starts the build, it does not wait for the entire
deployment to finish. You can check the deployment status from the OpenShift web
console. You can also check from the command line with e.g.
`oc -n balkov-osbs-koji get pod` for the specified Project, which will give you e.g.

```bash
NAME                   READY   STATUS      RESTARTS   AGE
koji-base-1-build      0/1     Completed   0          9m11s
koji-builder-1-build   1/1     Running     0          4m56s
koji-client-1-build    1/1     Running     0          4m56s
koji-db-1-build        0/1     Completed   0          4m56s
koji-db-1-deploy       0/1     Completed   0          56s
koji-db-1-h78vj        1/1     Running     0          51s
koji-hub-1-build       1/1     Running     0          4m56s
```

and then stream logs from a specific pod with e.g.
`oc -n balkov-osbs-koji logs -f=true koji-builder-1-build`

It might take a while for everything to build and settle - give it time (10
minutes or so). In the event of massive or inexplicable failure, simply start
over with

```shell
ansible-playbook cleanup.yaml -i inventory.ini -e @overrides.yaml --tags=everything
```

and run the 'deploy.yaml' playbook again

## Basic usage

TBD; wating on OSBS Reimagined

### Useage; a closer look

#### OpenShift console

Consult your cluster's docs or admin to find the console URL. e.g. for CRC it is
'console-openshift-console.apps-crc.testing'.

You should see all the OSBS-Box Projects here (by default, they are called
`$USER-osbs-*`). After entering a Project, you can see all the running pods,
view their logs, open terminals etc.

#### OpenShift CLI

Generally, anything you can do in the console, you can do with `oc`. Just make
sure you are logged into the server and in the right project.

To run a command in a container from the command line (for example, `koji hello`
on koji client):

```shell
oc login -u balkov -p FOO https://api.crc.testing:6443  # If not yet logged in
oc project balkov-osbs-koji  # If not in the koji project
oc rsh dc/koji-client koji hello  # dc is short for deploymentconfig
oc -n balkov-osbs-koji rsh dc/koji-client koji hello  # From a project other than balkov-osbs-koji
```

Use

`oc -n <relevant-project> rsh <pod name>`

or

`oc -n <relevant-project> rsh <pod name> bash`

to open a remote shell in the specified pod.

It's important to stay aware of which Project is current. Always providing the
Project name using `-n` takes extra typing, but doesn't hurt anything.

#### Koji website

The koji-hub OpenShift app provides an external route where you can access the
koji website. You can find the URL in the console or with e.g.
`oc -n balkov-osbs-koji get route koji-hub`. Here, you can view information
about your Koji instance.

To log in to the koji-hub website, you will first need to import a client
certificate into your browser (e.g. in Firefox, the "Your Certificates" tab of
the Certificate Manager). These certificates are generated during deployment and
can be found in the koji certificates directory on the target machine
(`~/.local/share/osbs-box/certificates/koji/` by default). There is one for each
koji user (by default, only `kojiadmin` and `kojiosbs` are users).

#### Koji CLI (local)

Coming soon ^TM^

#### Container registry

OSBS-Box deploys a container registry for you. It is used as both the source
registry for base images and the output registry for built images.

You can access it just like any other container registry using its external
route. You can find the URL in the console or with e.g.
`oc -n balkov-osbs-registry get route osbs-registry`.

Since the certificate used for the registry is signed by our own, untrusted CA,
the registry is considered insecure.

Use the following to access the registry locally, depending on your tool

- `docker`
  - Add the registry URL to `insecure-registries` in '/etc/docker/daemon.json'
    and restart docker
- `podman`
  - Use the `--tls-verify=false` option
- `skopeo`
  - Use the `--tls-verify=false` option (or `--(src|dest)-tls-verify=false` for
    copying)

## Updating OSBS-Box

In general, there are *very few* reasons why you'd want to try to update your
OSBS-Box instance:

1. Changes in OSBS-Box itself - it's unlikely you'd want to re-deploy simply
   because of this, *unless* you're doing development work on OSBS-Box itself,
   in which case you'll want to destroy the existing OSBS deploy with

   ```shell
   ansible-playbook cleanup.yaml -i inventory.ini -e @overrides.yaml --tags=everything
   ```

   and re-deploy from scratch.
1. Changes in OSBS components

   Simply trigger a new build in the orchestrator Project (i.e.
   your_userid-osbs-orchestrator/buildconfigs/osbs-buildroot) - there's no need
   to update anything else
1. Changes *specifically* in the koji-containerbuild plugin

   See [koji-c.md][] regarding manually deploying the koji-c plugin. The
   headaches incurred via re-deploying all of koji, only for the purpose of
   updating the koji-c plugin, aren't worth it.
1. Changes to reactor-config-map

   It's more efficient to simply make the changes manually in the orchestrator
   Project's reactor-config-map
   (your_userid-osbs-orchestrator/configmaps/reactor-config-map)

1. Changes to other configs

   In this one instance, it might be better to incorporate changes into your
   local clone of this repo and then re-deploy with `--tags=osbs`

**NOTE** when working on OSBS-Box' code itself: To test changes concerning any
of the pieces used to build container images, you will need to **push the
changes first** before running the playbook, because OpenShift gets the code for
builds from git (you will almost certainly need to override 'osbs_box_repo' and
'osbs_box_version', either directly in [group_vars/all.yaml][], or in
'overrides.yaml'). Alternatively, instead of using the playbook, you can simply
`oc start-build {the component you changed} --from-dir .`

## Cleaning up

There are multiple reasons why you might want to clean up OSBS-Box data:

- You need to reset your koji/registry instances to a clean state
- For some reason, updating your OSBS-Box failed (not due to code changes)
- You are done with OSBS-Box (forever)

OSBS-Box provides the [cleanup.yaml][] playbook, which does parts of the cleanup
for you based on what `--tags` you specify. In addition to tags related to the
OpenShiftProjects, there are extra tags (not run by default) related to local
data:

- `openshift_files`
  - OpenShift files (templates, configs) created during deployment
- `certificates`
  - Certificates created during deployment

When you run the playbook without any tags, all OSBS-Box OpenShift Projects
are deleted (this also kills the pods running in them). All other data is
kept. To get rid of everything, use `everything`.

## Known issues

- Koji website login bug
  - Problem

    ```text
    An error has occurred in the web interface code. This could be due to a bug
    or a configuration issue.
    koji.AuthError: could not get user for principal: <user>
    ```

  - Reproduce
    - Log in to the koji website as a user that is neither `kojiadmin` nor
      `kojiosbs`
    - Bring koji down without logging out of the website
    - Remove koji database persistent data
    - Bring koji back up, go to the website
    - Congratulations, koji now thinks a non-existent user is logged in
  - Solution
    - Clear cookies, reload website

[cleanup.yaml]: ./cleanup.yaml
[cloud.redhat.com]: https://cloud.redhat.com/openshift/downloads
[CodeReady Containers]: https://developers.redhat.com/products/codeready-containers
[deploy.yaml]: ./deploy.yaml
[Docker Hub]: https://hub.docker.com
[dockerhub.md]: ./docs/dockerhub.md
[group_vars/all.yaml]: ./group_vars/all.yaml
[inventory.ini]: ./inventory.ini
[koji-c.md]: ./docs/koji-c.md
