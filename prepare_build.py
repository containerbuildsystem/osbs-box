#!/usr/bin/env python3
import argparse
import copy
import json
import subprocess
from typing import Dict, Set, Tuple

import yaml


KOJIHUB_INTERNAL = 'http://localhost/kojihub'
KOJIROOT_INTERNAL = 'http://localhost/kojifiles'

BUILDSPEC_DEFAULTS = {
    'build_target': 'candidate',
    'build_tag': 'build',
    'dest_tag': 'dest',
    'base_images': [],
}


ap = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter
)
ap.add_argument(
    'buildspec',
    nargs='+',
    help='Path to yaml/json build spec'
)
ap.add_argument(
    '--koji-namespace',
    default='osbs-koji',
    help='Koji namespace'
)
ap.add_argument(
    '--registry-namespace',
    default='osbs-registry',
    help='Registry namespace'
)
ap.add_argument(
    '--skopeo-cmd',
    default='skopeo',
    help='Skopeo command'
)


class KojiStateConflict(Exception):
    pass


class OpenshiftKoji:
    def __init__(self, namespace):
        self._namespace = namespace

    def _hub_call(self, cmd, output=True, check=True):
        cmd = ['oc', '-n', self._namespace, 'rsh', 'dc/koji-hub'] + cmd
        return subprocess.run(cmd, capture_output=output, check=check)

    def _xmlrpc_call(self, method, args=None):
        args = args or []
        cmd = ['koji', 'call', '--json-output', method] + args
        return json.loads(self._hub_call(cmd).stdout)

    def get_tags(self):
        return self._xmlrpc_call('listTags')

    def get_packages(self, tag):
        return self._xmlrpc_call('listPackages', [f'tagID={tag}'])

    def get_build_targets(self):
        return self._xmlrpc_call('getBuildTargets')

    def get_builds(self):
        return self._xmlrpc_call('listBuilds')

    def setup_state(self, koji_state):
        import pprint
        pprint.pprint(koji_state.tags)
        pprint.pprint(koji_state.pkgs_by_tag)
        pprint.pprint(koji_state.build_targets)
        pprint.pprint(koji_state.builds)


class KojiState:
    tags: Set[str]
    pkgs_by_tag: Dict[str, Set[str]]   # {tag: set(packages)}
    build_targets: Dict[str, Tuple[str, str]]   # {target: (build, dest)}
    builds: Dict[str, Tuple[str, str]]  # {nvr: (kojihub, kojiroot)}

    def __init__(self, tags, pkgs_by_tag, build_targets, builds):
        self.tags = tags
        self.pkgs_by_tag = pkgs_by_tag
        self.build_targets = build_targets
        self.builds = builds

    @classmethod
    def from_openshift(cls, koji):
        tags = set(t['name'] for t in koji.get_tags())
        pkgs_by_tag = {
            tag: set(p['package_name'] for p in koji.get_packages(tag))
            for tag in tags
        }
        build_targets = {
            t['name']: (t['build_tag_name'], t['dest_tag_name'])
            for t in koji.get_build_targets()
        }
        builds = {
            b['nvr']: (KOJIHUB_INTERNAL, KOJIROOT_INTERNAL)
            for b in koji.get_builds()
        }
        return cls(tags, pkgs_by_tag, build_targets, builds)

    @classmethod
    def from_buildspec(cls, buildspec):
        bs = buildspec
        tags = {bs['build_tag'], bs['dest_tag']}
        pkgs_by_tag = {
            bs['build_tag']: set(),
            bs['dest_tag']: {bs['package_name']}
        }
        build_targets = {
            bs['build_target']: (bs['build_tag'], bs['dest_tag'])
        }
        parent_builds = bs.get('parent_builds')
        builds = {
            nvr: (parent_builds['kojihub'], parent_builds['kojiroot'])
            for nvr in parent_builds['nvrs']
        } if parent_builds is not None else {}
        return cls(tags, pkgs_by_tag, build_targets, builds)

    @classmethod
    def from_buildspecs(cls, buildspecs):
        state = cls.from_buildspec(buildspecs[0])
        for bs in buildspecs[1:]:
            state.update(cls.from_buildspec(bs))
        return state

    def update(self, other):
        self._check_conflicts(other)
        self.tags.update(other.tags)
        for tag, packages in other.pkgs_by_tag.items():
            self.pkgs_by_tag.setdefault(tag, set()).update(packages)
        for target, tags in other.build_targets.items():
            self.build_targets[target] = tags
        for build, urls in other.builds.items():
            self.builds[build] = urls

    def _check_conflicts(self, other):
        self._check_build_target_conflicts(other)
        self._check_build_conflicts(other)

    def _check_build_target_conflicts(self, other):
        for target, tags in other.build_targets.items():
            current_tags = self.build_targets.get(target)
            if current_tags is not None and tags != current_tags:
                msg = f'Build target conflict: {target} (tags do not match)'
                raise KojiStateConflict(msg)

    def _check_build_conflicts(self, other):
        for build, urls in other.builds.items():
            current_urls = self.builds.get(build)
            if current_urls is not None and urls != current_urls:
                msg = f'Build conflict: {build} (urls do not match)'
                raise KojiStateConflict(msg)

    def difference(self, other):
        """
        desired_state.difference(current_state) => what needs to be updated
        """
        self._check_conflicts(other)
        ...


def load_build_specs(paths):
    for path in paths:
        with open(path) as f:
            for bs in yaml.safe_load_all(f):
                yield add_defaults(bs)


def add_defaults(buildspec):
    defaults = copy.deepcopy(BUILDSPEC_DEFAULTS)
    buildspec.update(defaults)
    return buildspec


def copy_base_images(registry_namespace, buildspecs):
    ...


def main():
    args = ap.parse_args()

    koji = OpenshiftKoji(args.koji_namespace)

    build_specs = list(load_build_specs(args.buildspec))
    desired_state = KojiState.from_buildspecs(build_specs)

    koji.setup_state(desired_state)

    copy_base_images(args.registry_namespace, build_specs)


if __name__ == '__main__':
    main()
