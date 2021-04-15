# OSBS-Box

An OpenShift based project that provides an environment for testing OSBS
components; it can be deployed locally using the [example inventory][].

## Basic usage

Run a simple container build on your OSBS-Box:

```shell
$ # If running remotely, first log in to the OpenShift server or ssh into the remote machine
$ oc login --server https://<IP address>:8443 -u osbs -p osbs

$ # Get URL of container registry
$ OSBS_REGISTRY=$(oc -n osbs-registry get route osbs-registry --output jsonpath='{ .spec.host }')

$ # Copy base image for container build to registry
$ skopeo copy docker://registry.fedoraproject.org/fedora:30 \
              docker://${OSBS_REGISTRY}/fedora:30 \
              --all \
              --dest-tls-verify=false

$ # Run koji container-build
$ oc -n osbs-koji rsh dc/koji-client \
      koji container-build candidate \
          git://github.com/chmeliik/docker-hello-world#origin/osbs-box-basic \
          --git-branch osbs-box-basic
```

When logging into the server, you will likely need to use the
`--insecure-skip-tls-verify` flag.

If your version of `skopeo` does not support the `--all` flag, you might want to
use `skopeo-lite` instead ([more on that][]).

## Deployment

OSBS-Box is primarily intended for use with OpenShift clusters created using
`oc cluster up`.

Setting one up should be as simple as:

```shell
dnf install origin-clients
oc cluster up
```

For more details, refer to [cluster_up_down.md][].

### Prerequisites

- **On the target machine**
  - ansible >= 2.8
  - pyOpenSSL >= 0.15 (for the `openssl_*` ansible modules)
  - an OpenShift cluster, as described above

- **Detailed prerequisites on a Fedora 32 target machine**

  - see [Fedora32.md][]

- **Note about Docker Hub (docker.io image registry)**

  - You *must* have a [Docker Hub] account of some kind for pulling necessary
    images. Depending on how you use OSBS Box, you *might* require a paid account,
    as you *might* hit the free account's hourly limit on image pulls.
  - Consult [dockerhub.md][] for more details.

### Deployment steps

1. If you haven't already, `git clone` this repository
1. Take a look at [group_vars/all.yaml][]<sup id="a1">[1](#f1)</sup>
1. You **MUST** override the 'docker_*' group vars in a YAML file, and provide
   that file to the ansible-playbook command via (e.g.) `-e @overrides.yaml`.
   Consult [dockerhub.md][] for more details. (Note that the '@' *is a necessary
   part of the command*)
1. Provide an inventory file, or use the example one
1. Run `ansible-playbook deploy.yaml -i <inventory file>`

   If you are sure that you do not need to re-generate certificates, use
   `--tags=openshift`

**NOTE**: [deploy.yaml][] only starts the build, it does not wait for the entire
deployment to finish. You can check the deployment status in the web console or
with `oc status`.

## Using OSBS-Box

During deployment, the OpenShift user specified in [group_vars/all.yaml][]
will be given cluster admin privileges. This is the user you are going to want
to log in as from the web console / CLI.

### OpenShift console

Located at <https://localhost:8443/console> by default (if running locally).

You will see all the OSBS-Box namespaces here (by default, they are called
`osbs-*`). After entering a namespace, you will see all the running pods, you
can view their logs, open terminals in them etc.

### OpenShift CLI

Generally, anything you can do in the console, you can do with `oc`. Just make
sure you are logged into the server and in the right project.

To run a command in a container from the command line (for example, `koji hello`
on the client):

```shell
oc login --server <server> -u osbs -p osbs  # If not yet logged in
oc rsh dc/koji-client koji hello  # dc is short for deploymentconfig
oc -n osbs-koji rsh dc/koji-client koji hello  # From a project other than osbs-koji
```

Use

`oc rsh <pod name>`

or

`oc rsh <pod name> bash`

to open a remote shell in the specified pod.

### Koji website

The koji-hub OpenShift app provides an external route where you can access the
koji website. You can find the URL in the console or with
`oc get route koji-hub`. Here, you can view information about your Koji instance.

To log in to the website, you will first need to import a client certificate
into your browser. These certificates are generated during deployment and can be
found in the koji certificates directory on the target machine
(`~/.local/share/osbs-box/certificates/koji/` by default). There is one for
each koji user (by default, only `kojiadmin` and `kojiosbs` are users, but
logging in creates a user automatically).

### Koji CLI (local)

Coming soon ^TM^

### Container registry

OSBS-Box deploys a container registry for you. It is used both as the source
registry for base images and the output registry for built images.

You can access it just like any other container registry using its external
route. You can find the URL in the console or with `oc get route osbs-registry`.

Since the certificate used for the registry is signed by our own, untrusted CA,
the registry is considered insecure.

Use the following to access the registry, depending on your tool

- `docker`
  - Add the registry URL to `insecure-registries` in '/etc/docker/daemon.json'
            and restart docker
- `podman`
  - Use the `--tls-verify=false` option
- `skopeo`
  - Use the `--tls-verify=false` option (or `--(src|dest)-tls-verify=false` for
    copying)

### Skopeo-lite

**NOTE**: Starting with `skopeo` release `v0.1.40`, the `copy` command comes
with an `--all` flag, which makes skopeo also copy manifest lists. That renders
`skopeo-lite` obsolete.

Prior to `v0.1.40`, `skopeo` would not copy manifest lists. Builds may work even
with base images missing manifest lists, but they will not use the related OSBS
features.

For this purpose, OSBS-Box provides a `skopeo-lite` image.

Use it with `podman`:

```shell
$ podman build skopeo-lite/ --tag skopeo-lite

$ # Get URL of container registry
$ OSBS_REGISTRY=$(oc -n osbs-registry get route osbs-registry --output jsonpath='{ .spec.host }')

$ # Copy image to container registry
$ podman run --rm -ti \
      skopeo-lite copy docker://registry.fedoraproject.org/fedora:30 \
                       docker://${OSBS_REGISTRY}/fedora:30 \
                       --dest-tls-verify=false
```

Or `docker`:

```shell
$ docker build skopeo-lite/ --tag skopeo-lite

$ # If you are on the target machine, you might need to use the registry IP instead
$ OSBS_REGISTRY=$(oc -n osbs-registry get svc osbs-registry --output jsonpath='{ .spec.clusterIP }')

$ # Otherwise, use the URL
$ OSBS_REGISTRY=$(oc -n osbs-registry get route osbs-registry --output jsonpath='{ .spec.host }')

$ # Copy image to container registry
$ docker run --rm -ti \
      skopeo-lite copy docker://registry.fedoraproject.org/fedora:30 \
                       docker://${OSBS_REGISTRY}:5000/fedora:30 \
                       --dest-tls-verify=false
```

## Updating OSBS-Box

In general, there are two reasons why you might want to update your OSBS-Box
instance:

1. Changes in OSBS-Box itself
1. Changes in other OSBS components

For case 1, your best bet is to rerun the entire deployment

```shell
ansible-playbook deploy.yaml -i <inventory> -e <overrides>
```

For case 2, usually you will only need

```shell
ansible-playbook deploy.yaml -i <inventory> -e <overrides> --tags=koji,buildroot
```

In fact, it might be desirable to run the update like this to avoid having any
potential manual changes to the reactor config map overwritten. But if you are
not sure, running the full playbook or at least `--tags=openshift` will work.

**NOTE**: When working on OSBS-Box code, to test changes concerning any of the
pieces used to build Docker images, you will need to **push the changes first**
before running the playbook, because OpenShift gets the code for builds from
git. Alternatively, instead of using the playbook, you can just `oc start-build
{the component you changed} --from-dir .`.

## Cleaning up

There are multiple reasons why you might want to clean up OSBS-Box data:

- You need to reset your koji/registry instances to a clean state
- For some reason, updating your OSBS-Box failed (and it is not because of the
  code)
- You are done with OSBS-Box (forever)

OSBS-Box provides the **cleanup.yaml** playbook, which does parts of the cleanup
for you based on what `--tags` you specify. In addition to tags related to
OpenShift namespaces/applications, there are extra tags (not run by default)
related to local data:

- `openshift_files`
  - OpenShift files (templates, configs) created during deployment
- `certificates`
  - Certificates created during deployment
- `pvs` (uses `sudo`; run playbook with `--ask-become-pass`)
  - `registry_pv`
    - PV for the container registry
  - `koji_pvs`
    - `koji_db_pv`
      - koji database PV
    - `koji_files_pv`
      - PV used by koji-hub and koji-builder for `/mnt/koji/`

When you run the playbook without any tags, all OSBS-Box OpenShift namespaces
are deleted, this also kills the containers running in them. All other data is
kept, including persistent volume directories. If you need to reset your
instance to a clean state, you will likely want to use the `pvs` tag. To get rid
of everything, use `everything`.

You may also want to

- Remove the docker images built/pulled by OpenShift

  You will find them in your local registry, like normal docker images
- Run `oc cluster down` and remove the data left behind by `oc cluster up`
  - Volumes that were mounted by OpenShift and never unmounted

    ```shell
    findmnt -r -n -o TARGET | grep "openshift.local.clusterup" | xargs -r umount
    ```

  - The `openshift.local.clusterup` directory created when you ran
    `oc cluster up` (or whatever you passed as the `--base-dir` param to
    `oc cluster up`)

## Project structure

Coming soon ^TM^

## Known issues

- Koji website login bug
  - Problem

    ```text
    An error has occurred in the web interface code. This could be due to a bug
    or a configuration issue.
    koji.AuthError: could not get user for principal: <user>
    ```

  - Reproduce
    1. Log in to the koji website as a user that is neither `kojiadmin` nor
    `kojiosbs`
    1. Bring koji down without logging out of the website
    1. Remove koji database persistent data
    1. Bring koji back up, go to the website
    1. Congratulations, koji now thinks a non-existent user is logged in
  - Solution
    - Clear cookies, reload website
- Running deployment playbook triggers multiple deployments in OpenShift
  - Problem
    - For some reason, even though the DeploymentConfigs are configured to only
      trigger deployments on imageChange, running the deployment playbook
      against a running OSBS-Box instance triggers multiple re-deployments of
      koji components
  - Solution
    - This is not a major issue, just do not be surprised when you see your koji
      containers getting restarted 2 or 3 times after each deployment (except
      for the initial deployment, that works fine)

---

<b id="f1">1.</b> It's better to override group vars via `overrides.yaml` than
to change the global configuration in [group_vars/all.yaml][] [↩](#a1)

[example inventory]: ./inventory-example.ini
[Docker Hub]: https://hub.docker.com
[dockerhub.md]: ./docs/dockerhub.md
[more on that]: #Skopeo-lite
[cluster_up_down.md]: https://github.com/openshift/origin/blob/release-3.11/docs/cluster_up_down.md
[Fedora32.md]: ./docs/Fedora32.md
[group_vars/all.yaml]: ./group_vars/all.yaml
[deploy.yaml]: ./deploy.yaml
