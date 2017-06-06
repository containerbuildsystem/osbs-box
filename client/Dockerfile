FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

RUN \
    dnf install -y \
    atomic-openshift-clients \
    iproute \
    koji-containerbuild-cli \
    && dnf clean all

ADD bin/ /usr/local/bin/

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
