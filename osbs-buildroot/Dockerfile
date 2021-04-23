FROM docker.io/golang:buster AS build

RUN go get -v "github.com/openshift/imagebuilder/cmd/imagebuilder"

FROM registry.fedoraproject.org/fedora:30

# Install non-OSBS buildroot components
COPY --from=build "/go/bin/imagebuilder" "/usr/bin/imagebuilder"
RUN dnf -y install "fedpkg-minimal" \
                   "file" \
                   "findutils" \
                   "jq" \
                   "libmodulemd" \
                   "python3-docker" \
                   "python3-docker-squash" \
                   "python3-gobject-base" \
                   "python3-koji" \
                   "python3-rpm" \
                   "python3-ruamel-yaml" \
                   "python3-setuptools" \
                   "python3-simplejson" \
                   "skopeo" \
    && dnf clean all

# Install stuff that will be needed for pip-installing OSBS components from git
RUN dnf -y install "git-core" \
                   "python3-devel" \
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
RUN pip3 --no-cache-dir install "$ATOMIC_REACTOR_PIP_REF" \
                 "$OSBS_CLIENT_PIP_REF" \
                 "$DOCKERFILE_PARSE_PIP_REF" \
                 "$DOCKPULP_PIP_REF"

# Add script for building source container images
RUN curl "https://raw.githubusercontent.com/containers/BuildSourceImage/master/BuildSourceImage.sh" \
          -o /usr/bin/bsi \
    && chmod +x /usr/bin/bsi

CMD ["atomic-reactor", "--verbose", "inside-build"]
