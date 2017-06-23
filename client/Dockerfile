FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

ARG UPDATES_TESTING

RUN dnf update -y && dnf install -y dnf-plugins-core && \
    if [ $UPDATES_TESTING ]; then dnf config-manager --set-enable updates-testing; fi && \
    dnf -y update && \
    dnf install -y \
      origin-clients \
      iproute \
      koji-containerbuild-cli \
    && dnf clean all

ADD bin/ /usr/local/bin/
ADD configs/ /configs

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
