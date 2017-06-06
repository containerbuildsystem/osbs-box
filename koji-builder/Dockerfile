FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

RUN \
    dnf -y install --nogpgcheck \
        mock \
        koji-builder \
        koji-containerbuild-builder \
        osbs-client \
        python-osbs-client \
        python-hashlib \
        python-pip \
    && dnf clean all

ADD etc/ /etc/
ADD bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/kojid", "-f", "--force-lock"]
