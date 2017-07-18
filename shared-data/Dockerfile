FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

VOLUME [\
    "/opt/osbs", \
    "/opt/koji-clients", \
    "/etc/pki/koji", \
    "/certs", \
    "/auth"\
]

EXPOSE 80

ARG UPDATES
ARG UPDATES_TESTING

RUN if [ $UPDATES ]; then dnf update -y; fi && \
    if [ $UPDATES_TESTING ]; then \
            dnf install -y dnf-plugins-core && \
            dnf config-manager --set-enable updates-testing &&\
            dnf -y update; fi && \
    dnf -y install \
        openssl \
        hostname \
        httpd \
        httpd-tools \
    && dnf clean all

ADD opt/ /opt/
ADD etc/ /etc/
ADD bin/ /usr/local/bin/
ADD root/ /root/

RUN ls -l /usr/local/bin
RUN /usr/local/bin/setup.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
