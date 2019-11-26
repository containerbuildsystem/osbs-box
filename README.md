# OSBS-Box

An OpenShift based project that provides a local environment for testing OSBS components.


## Basic usage

Run a simple container build on your OSBS-Box:

```bash
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

If your version of `skopeo` does not support the `--all` flag, you might want to use `skopeo-lite`
instead. More on that [here](#Skopeo-lite).


## Deployment

OSBS-Box is primarily intended for use with OpenShift clusters created using `oc cluster up`.

Setting one up should be as simple as:

```bash
$ dnf install origin-clients
$ oc cluster up
```

For more details, refer to
[the OKD documentation](https://docs.okd.io/latest/getting_started/administrators.html#running-in-a-docker-container).


### Prerequisites

* Ansible
* pyOpenSSL >= 0.15 (for the `openssl_*` ansible modules)
* an OpenShift cluster, as described above


### Deployment steps

1. If you haven't already, `git clone` this repository
2. Take a look at the [configuration file](group_vars/all.yaml)
3. Run `ansible-playbook deploy.yaml`
    * If you are sure that you do not need to re-generate certificates, use `--tags=openshift`

__NOTE__: Rather than changing the configuration in __group_vars/all.yaml__, you might want to
create a file containing your overrides (e.g. __overrides.yaml__) and run the playbooks like this:

```bash
$ ansible-playbook <playbook> -e '@overrides.yaml'
```

__NOTE__: The __deploy.yaml__ playbook only starts the build, it does not wait for the entire
deployment to finish. You can check the deployment status in the web console or with `oc status`.


## Using OSBS-Box

During deployment, the OpenShift user specified in [group\_vars/all.yaml](group_vars/all.yaml) will
be given cluster admin privileges. This is the user you are going to want to log in as from the
web console / CLI.

### OpenShift console

Located at https://localhost:8443/console/ by default.

You will see all the OSBS-Box namespaces here (by default, they are called `osbs-*`). After
entering a namespace, you will see all the running pods, you can view their logs, open terminals
in them etc.

### OpenShift CLI

Generally, anything you can do in the console, you can do with `oc`.  Just make sure you are in
the right project.

To run a command in a container from the command line (for example, `koji hello` on the client):

```bash
$ oc rsh dc/koji-client koji hello  # dc is short for deploymentconfig
$ oc -n osbs-koji rsh dc/koji-client koji hello  # From a project other than osbs-koji
```

Use `oc rsh <pod name>` or `oc rsh <pod name> bash` to open a remote shell in the specified pod.

### Koji website

The koji-hub OpenShift app provides an external route where you can access the koji website.
You can find the URL in the console or with `oc get route koji-hub`. Here, you can view
information about your Koji instance.

To log in to the website, you will first need to import a client certificate into your browser.
These certificates are generated during deployment and can be found in the koji certificates
directory (__~/.local/share/osbs-box/certificates/koji/__ by default).  There is one for each
koji user (by default, only _kojiadmin_ and _kojiosbs_ are users, but logging in creates a user
automatically).

### Koji CLI (local)

Coming soon<sup>TM</sup>

### Container registry

OSBS-Box deploys a container registry for you. It is used both as the source registry for base
images and the output registry for built images.

You can access it just like any other container registry using its external route. You can find the
URL in the console or with `oc get route osbs-registry`.

Since the certificate used for the registry is signed by our own, untrusted CA, the registry is
considered insecure. To access the registry with various tools you need to:

* `docker`: Add the registry URL to `insecure-registries` in __/etc/docker/daemon.json__
            and restart docker
* `podman`: Use the `--tls-verify=false` option
* `skopeo`: Use the `--tls-verify=false` option (or `--(src|dest)-tls-verify=false` for copying)

### Skopeo-lite

__Starting with `skopeo` release `v0.1.40`, the `copy` command comes with an `--all` flag, which
makes skopeo also copy manifest lists. That renders `skopeo-lite` obsolete.__

Prior to `v0.1.40`, `skopeo` would not copy manifest lists. Builds may work even with base images
missing manifest lists, but they will not use the related OSBS features.

For this purpose, OSBS-Box provides a `skopeo-lite` image.

Use it with `podman`:

```bash
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

```bash
$ docker build skopeo-lite/ --tag skopeo-lite

$ # Get IP of container registry, your firewall will likely prevent docker from accessing the URL
$ REGISTRY_IP=$(oc -n osbs-registry get svc osbs-registry --output jsonpath='{ .spec.clusterIP }')

$ # Copy image to container registry
$ docker run --rm -ti \
      skopeo-lite copy docker://registry.fedoraproject.org/fedora:30 \
                       docker://${REGISTRY_IP}:5000/fedora:30 \
                       --dest-tls-verify=false
```


## Updating OSBS-Box

In general, there are two reasons why you might want to update your OSBS-Box instance:

* Changes in OSBS-Box itself
* Changes in other OSBS components

In both cases, what you want to do is:

1. Specify your overrides in a file
    * e.g. __repo__, __branch__ for the OSBS components you want to test
2. Run the __deploy.yaml__ playbook with your overrides

__NOTE__: When working on OSBS-Box code, to test changes concerning any of the pieces used to
build Docker images, you will need to __push the changes first__ before running the playbook,
because OpenShift gets the code for builds from git. Alternatively, instead of using the playbook,
you can just `oc start-build <the component you changed> --from-dir .`.


## Cleaning up

There are multiple reasons why you might want to clean up OSBS-Box data:

* You need to reset your koji/registry instances to a clean state
* For some reason, updating your OSBS-Box failed (and it is not because of the code)
* You are done with OSBS-Box (forever)

OSBS-Box provides the __cleanup.yaml__ playbook, which does parts of the cleanup for you based
on what `--tags` you specify. In addition to tags related to OpenShift namespaces/applications,
there are extra tags (not run by default) related to local data:

* `openshift_files`: OpenShift files (templates, configs) created during deployment
* `certificates`: certificates created during deployment
* `pvs`: _all of the below, uses `sudo` (run playbook with `--ask-become-pass`)_
    * `registry_pv`: PV for the container registry
    * `koji_pvs`: _all of the below_
        * `koji_db_pv`: koji database PV
        * `koji_files_pv`: PV used by koji-hub and koji-builder for __/mnt/koji/__

When you run the playbook without any tags, all OSBS-Box OpenShift namespaces are deleted, this
also kills the containers running in them. All other data is kept, including persistent volume
directories. If you need to reset your instance to a clean state, you will likely want to use
the `pvs` tag. To get rid of everything, use `everything`.

You may also want to:

* Remove the docker images built/pulled by OpenShift
    * You will find them in your local registry, like normal docker images
* Run `oc cluster down` and remove the data left behind by `oc cluster up`
    * Volumes that were mounted by OpenShift and never unmounted
      ```bash
      $ mount | grep openshift | while read mountpoint; do sudo umount $mountpoint; done
      ```
    * The __openshift.local.clusterup/__ directory created when you ran `oc cluster up`
      (or whatever you passed as the `--base-dir` param to `oc cluster up`)


## Project structure

Coming soon<sup>TM</sup>


## Known issues

### Koji website login bug

__Problem__:

```
An error has occurred in the web interface code. This could be due to a bug or a configuration issue.
koji.AuthError: could not get user for principal: <user>
```

__Reproduce__:

1. Log in to the koji website as a user that is neither _kojiadmin_ nor _kojiosbs_
2. Bring koji down without logging out of the website
3. Remove koji database persistent data
4. Bring koji back up, go to the website
5. Congratulations, koji now thinks a non-existent user is logged in

__Solution__: clear cookies, reload website


### Running deployment playbook triggers multiple deployments in OpenShift

__Problem__:

For some reason, even though the DeploymentConfigs are configured to only trigger deployments
on imageChange, running the deployment playbook against a running OSBS-Box instance triggers
multiple re-deployments of koji components.

__Solution__:

This is not a major issue, just do not be surprised when you see your koji containers getting
restarted 2 or 3 times after each deployment (except for the initial deployment, that works fine).
