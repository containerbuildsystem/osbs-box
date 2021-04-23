FROM registry.fedoraproject.org/fedora:33

# The `python` symlink is not installed by default -_-
RUN dnf -y install python "python3-pip" \
    && dnf clean all

# Install koji, make sure docs are not excluded by unsetting tsflags
# (docs include the SQL schema needed to initialize the DB)
RUN dnf --setopt tsflags="" -y install "koji" \
    && dnf clean all

# Install git-core, it will be needed when pip-installing packages from git
RUN dnf -y install "git-core" && \
    dnf clean all

COPY bin/ /usr/local/bin/
COPY etc/ /etc/

# By default, pip3 installs stuff in /usr/local/
ENV PIP_PREFIX="/usr"

# Pip URLs for osbs-client and koji-containerbuild (git+<repo>[@<version>])
ARG OSBS_CLIENT_PIP_REF
ARG KOJI_CONTAINERBUILD_PIP_REF

ENV OSBS_CLIENT_PIP_REF="$OSBS_CLIENT_PIP_REF" \
    KOJI_CONTAINERBUILD_PIP_REF="$KOJI_CONTAINERBUILD_PIP_REF"
