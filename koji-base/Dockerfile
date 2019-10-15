FROM fedora

# Install koji, make sure docs are not excluded by unsetting tsflags
# (docs include the SQL schema needed to initialize the DB)
RUN dnf --setopt tsflags="" -y install "koji"

# Install git-core, it will be needed when pip-installing packages from git
RUN dnf -y install "git-core" && \
    dnf clean all

COPY bin/ /usr/local/bin/
COPY etc/ /etc/

# Setup for eliminating differences between python versions
ENV PY_VER_MAJOR="3" \
    PY_VER_MAJOR_MINOR="3.7"

ENV PYTHON="python${PY_VER_MAJOR_MINOR}" \
    PIP="pip${PY_VER_MAJOR_MINOR}"

# Pip URLs for osbs-client and koji-containerbuild (git+<repo>[@<version>])
ARG OSBS_CLIENT_PIP_REF
ARG KOJI_CONTAINERBUILD_PIP_REF

ENV OSBS_CLIENT_PIP_REF="$OSBS_CLIENT_PIP_REF" \
    KOJI_CONTAINERBUILD_PIP_REF="$KOJI_CONTAINERBUILD_PIP_REF"
