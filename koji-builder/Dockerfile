FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

ARG UPDATES
ARG UPDATES_TESTING

RUN if [ $UPDATES ]; then dnf update -y; fi && \
    if [ $UPDATES_TESTING ]; then \
            dnf install -y dnf-plugins-core && \
            dnf config-manager --set-enable updates-testing &&\
            dnf -y update; fi && \
    dnf -y install \
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
CMD ["/usr/sbin/init"]
