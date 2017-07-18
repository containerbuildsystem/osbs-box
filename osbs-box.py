#!/bin/python3
import argparse
import re
import os
from subprocess import CalledProcessError, Popen, PIPE, STDOUT
from time import sleep


def _run(cmd, ignore_exitcode=False, show_print=True):
    if isinstance(cmd, list):
        cmd = " ".join(cmd)
    if show_print:
        print("Running '%s'" % cmd)
    kwargs = {}
    if not show_print:
        kwargs = {'stderr': STDOUT}

    output = ''
    proc = Popen(cmd, stdout=PIPE, shell=True, **kwargs)
    while True:
        line = proc.stdout.readline()
        if line != b'':
            decoded_line = line.rstrip().decode('utf-8')
            if show_print:
                print(decoded_line)
            output += decoded_line
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
    print()
    return output


def _wait_until_container_is_up(container):
    dir_path = os.path.basename(os.path.dirname(os.path.realpath(__file__)))
    dir_path = dir_path.replace('-', '')
    container_is_up = True
    cmd = ["docker", "inspect", "{0}_{1}_1".format(dir_path, container),
           "--format='{{.State.Running}}'"]
    for attempts in range(0, 10):
        try:
            output = _run(cmd, show_print=False)
            if output == 'true':
                container_is_up = True
                break
        except CalledProcessError:
            sleep(1)

    assert container_is_up


def down(args, delete_volumes=False):
    print("osbs-box: down")
    cmd = ['docker-compose', 'down']
    if delete_volumes:
        cmd += ['-v']
    _run(cmd, ignore_exitcode=True)
    _run(['oc', 'cluster', 'down'], ignore_exitcode=True)


def cleanup(args):
    down(args, delete_volumes=True)


def up(args):
    if not args.no_cleanup:
        cleanup(args)
    print("osbs-box: up")

    # Start a cluster
    cmd = ['oc', 'cluster', 'up',
           '--version', 'v1.5.1',
           '--image', 'openshift/origin']
    output = _run(cmd)
    match = re.search(r'Using (\d*.\d*.\d*.\d*) as the server IP', output)
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

    # Build containers
    cmd = ["docker-compose", "build"]
    if args.force_rebuild:
        cmd += ["--no-cache"]
    _run(cmd)

    # Start docker-compose
    cmd = ["docker-compose", "up", "-d"]
    _run(cmd)

    print("Waiting for client to come up")

    # Wait for container to appear
    _wait_until_container_is_up('koji-client')

    # check that init is complete
    client_logs = ''
    client_initialized = False
    dir_path = os.path.basename(os.path.dirname(os.path.realpath(__file__)))
    dir_path = dir_path.replace('-', '')
    cmd = ["docker", "logs", "-f", "{}_koji-client_1".format(dir_path)]
    process = Popen(cmd, stdout=PIPE, stderr=STDOUT)
    while not process.poll():
        line = process.stdout.readline()
        if not line:
            break
        decoded_line = line.decode('utf-8')
        client_logs += decoded_line
        if 'exec sleep infinity' in decoded_line:
            print("Client is up")
            client_initialized = True
            break

    if not client_initialized:
        print(client_logs)
        raise RuntimeError("Client failed to start")

    # Check that other containers are running
    print("Checking that other containers are running")
    _wait_until_container_is_up('koji-db')
    _wait_until_container_is_up('koji-hub')
    _wait_until_container_is_up('koji-builder')

    print("osbs-box is up")

    print("make sure registry certificate from ./certs is copied to "
          "/etc/docker/certs.d/172.17.0.1:5000/ca.crt")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parse_action = parser.add_argument("action", choices=['up', 'down', 'cleanup'])
    parse_action = parser.add_argument("--no-cleanup", action="store_true")
    parse_action = parser.add_argument("--force-rebuild", action="store_true")
    parsed = parser.parse_args()

    {
        'up': up,
        'down': down,
        'cleanup': cleanup,
    }[parsed.action](parsed)
