FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

ARG UPDATES_TESTING

RUN dnf update -y && dnf install -y dnf-plugins-core && \
    if [ $UPDATES_TESTING ]; then dnf config-manager --set-enable updates-testing; fi && \
    dnf -y update && \
    dnf -y install --nogpgcheck \
        mock \
        koji-builder \
        koji-containerbuild-builder \
        osbs-client \
        python-osbs-client \
        python-hashlib \
        python-pip \
        findutils \
    && dnf clean all

ADD etc/ /etc/
ADD bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/kojid", "-d", "-v", "-f", "--force-lock"]
