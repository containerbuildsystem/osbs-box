FROM docker.io/golang:buster AS build

RUN go get -v "github.com/openshift/imagebuilder/cmd/imagebuilder"

FROM registry.fedoraproject.org/fedora:30

# Set python version
ARG PY_VER="3"

# Install non-OSBS buildroot components
COPY --from=build "/go/bin/imagebuilder" "/usr/bin/imagebuilder"
RUN dnf -y install "fedpkg-minimal" \
                   "file" \
                   "findutils" \
                   "jq" \
                   "python${PY_VER}-rpm" \
                   "python${PY_VER}-koji" \
                   "python${PY_VER}-libmodulemd" \
                   "skopeo" \
    && dnf clean all

# Install stuff that will be needed for pip-installing OSBS components from git
RUN dnf -y install "git-core" \
                   "python${PY_VER}-devel" \
                   "krb5-devel" \
                   "xz-devel" \
                   "gcc" \
    && dnf clean all

# Pip URLs for OSBS components (git+<repo>[@<version>])
ARG ATOMIC_REACTOR_PIP_REF
ARG OSBS_CLIENT_PIP_REF
ARG DOCKERFILE_PARSE_PIP_REF
ARG DOCKPULP_PIP_REF

# Install OSBS components from git
ENV PIP_PREFIX="/usr"
RUN pip${PY_VER} install "$ATOMIC_REACTOR_PIP_REF" \
                         "$OSBS_CLIENT_PIP_REF" \
                         "$DOCKERFILE_PARSE_PIP_REF" \
                         "$DOCKPULP_PIP_REF"

# Installing atomic-reactor with pip installs both docker and docker-py from
# PyPI (RHEL7 reasons). These packages overwrite each other's files, leaving
# you with an unusable docker module. Workaround below.
RUN pip${PY_VER} install "docker" --prefix="/usr/local" --ignore-installed
ENV PYTHONPATH="/usr/local/lib/python2.7/site-packages/:${PYTHONPATH}"
#               ^ python3 searches this path by default

# Add script for building source container images
RUN curl "https://raw.githubusercontent.com/containers/BuildSourceImage/master/BuildSourceImage.sh" \
          -o /usr/bin/bsi \
    && chmod +x /usr/bin/bsi

CMD ["atomic-reactor", "--verbose", "inside-build"]
