FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

RUN dnf update -y && \
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
