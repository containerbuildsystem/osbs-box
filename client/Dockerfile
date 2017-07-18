FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

ARG UPDATES
ARG UPDATES_TESTING

RUN if [ $UPDATES ]; then dnf update -y; fi && \
    if [ $UPDATES_TESTING ]; then \
            dnf install -y dnf-plugins-core && \
            dnf config-manager --set-enable updates-testing &&\
            dnf -y update; fi && \
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
