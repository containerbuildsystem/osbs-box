#!/bin/python3
import argparse
import re
import os
from subprocess import CalledProcessError, Popen, PIPE, STDOUT
from time import sleep
from textwrap import dedent

BASEIMAGE = 'osbs-box'
DIRECTORIES = ['base', 'client', 'koji-db', 'hub', 'koji-builder', 'shared-data']
SERVICES = ['shared-data', 'koji-db', 'koji-hub', 'koji-builder', 'koji-client']
dir_path = os.path.basename(os.path.dirname(os.path.realpath(__file__))).replace('-', '')


def _run(cmd, ignore_exitcode=False, show_print=True):
    if isinstance(cmd, list):
        cmd = " ".join(cmd)
    if show_print:
        print("Running '%s'" % cmd)

    output = ''
    proc = Popen(cmd, stdout=PIPE, stderr=STDOUT, shell=True)
    while True:
        line = proc.stdout.readline()
        if line != b'':
            decoded_line = line.rstrip().decode('utf-8')
            if show_print:
                print(decoded_line)
            output += decoded_line + '\n'
        else:
            break
    # Run poll to set returncode
    proc.wait()
    if not ignore_exitcode and proc.returncode != 0:
        # If the command has failed and lines were hidden before now's the time
        # to print them
        if not show_print:
            print(output)
        raise RuntimeError('Command {0} failed with exitcode {1}'.format(
            cmd, proc.returncode))
    # Print an additional empty line
    if show_print:
        print()
    return output.strip()


def _wait_until_container_is_up(container):
    container_is_up = False
    cmd = ["docker", "inspect", "--format='{{.State.Running}}'",
           "{0}_{1}_1".format(dir_path, container)]
    for attempts in range(0, 10):
        try:
            output = _run(cmd, show_print=False)
            if output == 'true':
                container_is_up = True
                break
        except CalledProcessError:
            sleep(1)

    assert container_is_up


def _wait_until_string_is_in_logs(container, str_to_find):
    container_logs = ''
    container_initialized = False
    cmd = ["docker", "logs", "-f", container]
    process = Popen(cmd, stdout=PIPE, stderr=STDOUT)
    while not process.poll():
        line = process.stdout.readline()
        if not line:
            break
        decoded_line = line.decode('utf-8')
        container_logs += decoded_line
        if str_to_find in decoded_line:
            print("Container %s is up" % container)
            container_initialized = True
            break

    if not container_initialized:
        print(container_logs)
        raise RuntimeError("%s failed to start", container)


def os_down(args):
    _run(['oc', 'cluster', 'down'], ignore_exitcode=True)


def down(args, delete_volumes=False):
    print("osbs-box: down")
    cmd = ['docker-compose', 'down']
    if delete_volumes:
        cmd += ['-v']
    _run(cmd, ignore_exitcode=True)
    os_down(args)


def cleanup(args):
    down(args, delete_volumes=True)


def os_up(args):
    cmd = ['oc', 'cluster', 'up',
           '--version', args.ocp_version,
           '--image', args.ocp_image]
    if args.public_hostname:
        cmd += ["--public-hostname", args.public_hostname]
    output = _run(cmd)
    match = re.search(r'https://(\d*.\d*.\d*.\d*):8443', output)
    if not match:
        raise RuntimeError("Failed to find openshift IP in output:\n%s" % output)

    openshift_ip = match.group(1)

    # login
    cmd = ["oc", "login", "-u", "system:admin", "https://{}:8443".format(openshift_ip)]
    _run(cmd)

    # add osbs as cluster admin
    cmd = ["oc", "-n", "osbs", "adm", "policy",
           "add-cluster-role-to-user", "cluster-admin", "osbs"]
    _run(cmd)


def up(args):
    if not args.no_cleanup:
        cleanup(args)
    print("osbs-box: up")

    if not os.path.exists('ssl'):
        print("Generating certificates")
        _run(['./generate-certs'])
    else:
        print("Reusing existing certificates")

    # Start an OpenShift cluster
    cluster_up(args)

    # Copy distro-specific Dockerfile
    filename = "Dockerfile.{}".format(args.distro)
    for directory in DIRECTORIES:
        src_filepath = os.path.abspath('/'.join([directory, filename]))
        destfilepath = os.path.abspath('/'.join([directory, 'Dockerfile']))
        cmd = ["cp", "-rvf", src_filepath, destfilepath]
        _run(cmd)

    # Build containers
    cmd = ["docker", "build"]
    if args.force_rebuild:
        cmd += ["--no-cache"]
    if args.updates:
        cmd += ["--build-arg", "UPDATES=1"]
    if args.updates_testing:
        cmd += ["--build-arg", "UPDATES_TESTING=1"]
    if args.repo_url:
        cmd += ["--build-arg", "REPO_URL={0}".format(args.repo_url)]
    _run(cmd + ['-t', '{0}:{1}'.format(BASEIMAGE, args.distro), 'base'])

    cmd = ["docker-compose", "build"]
    for service in SERVICES:
        _run(cmd + [service])

    # Start docker-compose
    cmd = ["docker-compose", "up", "-d"]
    _run(cmd)

    print("Waiting for client to come up")

    # Wait for container to appear
    _wait_until_container_is_up('koji-client')
    _wait_until_string_is_in_logs("{}_koji-client_1".format(dir_path),
                                  "exec sleep infinity")

    # Check that other containers are running
    print("Checking that other containers are running")
    _wait_until_container_is_up('koji-db')
    _wait_until_container_is_up('koji-hub')
    _wait_until_container_is_up('koji-builder')
    _wait_until_string_is_in_logs("{}_koji-builder_1".format(dir_path),
                                  "exec /usr/sbin/init")
    print("osbs-box is up")

    print("make sure registry certificate from ./ssl/certs/domain.crt is copied to "
          "/etc/docker/certs.d/172.17.0.1:5000/ca.crt")


def status(args):
    # Show Openshift cluster
    try:
        output = _run(["oc", "cluster", "status"], show_print=False)
        match = re.search("(https://.*)\n", output)
        if match:
            print("Openshift URL: {}".format(match.group(1)))
            print("Credentials: osbs/osbs")
            print("Namespaces: 'osbs' for orchestration builds, 'worker' for worker builds")
        else:
            print("Failed to find Openshift URL in the output")
    except RuntimeError:
        print("Openshift is not running")
    print()

    # Show Koji details
    try:
        cmd = ["docker", "logs", "{}_koji-hub_1".format(dir_path)]
        output = _run(cmd, show_print=False)
        match = re.search("(http.*/koji)\n(http.*/kojifiles)\n", output)
        if match:
            print('Koji hub URL: {}'.format(match.group(1)))
            print('Koji files URL: {}'.format(match.group(2)))
        else:
            print("Failed to find Koji Hub URL in the output")
    except RuntimeError:
        pass
    print()

    # Show container status
    for service in SERVICES:
        cmd = ["docker", "inspect", "--format='{{.State.Status}}'",
               "{0}_{1}_1".format(dir_path, service)
               ]
        try:
            status = _run(cmd, show_print=False)
        except RuntimeError:
            status = "not found"
        print("{0}: {1}".format(service, status.strip()))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description=dedent(
            """\
            Setup a new OSBS instance using docker-compose.
            It includes Openshift cluster, Koji and docker registry
            """)
    )
    subparsers = parser.add_subparsers(title='subcommands', help='action to execute')
    parse_up = subparsers.add_parser('up', help='start a new osbs-box')
    parse_up.set_defaults(func=up)
    parse_down = subparsers.add_parser('down', help='destroy existing osbs-box')
    parse_down.set_defaults(func=down)
    parse_os_up = subparsers.add_parser('os-up', help='start openshift cluster for osbs-box')
    parse_os_up.set_defaults(func=os_up)
    parse_os_down = subparsers.add_parser('os-down', help='destroy openshift cluster for osbs-box')
    parse_os_down.set_defaults(func=os_down)
    parse_cleanup = subparsers.add_parser('cleanup', help='remove configuration volumes')
    parse_cleanup.set_defaults(func=cleanup)
    parse_status = subparsers.add_parser('status', help='show openshift, koji and container status')
    parse_status.set_defaults(func=status)

    parse_up.add_argument(
        "--no-cleanup", action="store_true",
        help="Don't remove existing volumes when starting a new box"
    )
    parse_up.add_argument(
        "--force-rebuild", action="store_true",
        help="Force image rebuild"
    )
    parse_up.add_argument(
        "--updates", action="store_true",
        help="Update packages"
    )
    parse_up.add_argument(
        "--updates-testing", action="store_true",
        help="Enable updates-testing repo and update packages"
    )
    parse_up.add_argument(
        "--distro", choices=['fedora', 'rhel7'], default='fedora',
        help="Select a base distro"
    )
    parse_up.add_argument(
        "--repo-url",
        help="URL of the additional repo file to install"
    )
    parse_os_up.add_argument(
        "--ocp-version", default="v3.6.0",
        help="Specify the tag for OpenShift images used in 'oc cluster up'"
    )
    parse_os_up.add_argument(
        "--ocp-image", default="openshift/origin",
        help="Specify the images to use for OpenShift in 'oc cluster up'"
    )
    parse_os_up.add_argument(
        "--public-hostname",
        help="Public hostname for osbs-box services"
    )
    parse_up.add_argument(
        "--ocp-version", default="v3.6.0",
        help="Specify the tag for OpenShift images used in 'oc cluster up'"
    )
    parse_up.add_argument(
        "--ocp-image", default="openshift/origin",
        help="Specify the images to use for OpenShift in 'oc cluster up'"
    )
    parse_up.add_argument(
        "--public-hostname",
        help="Public hostname for osbs-box services"
    )

    parsed = parser.parse_args()
    parsed.func(parsed)
