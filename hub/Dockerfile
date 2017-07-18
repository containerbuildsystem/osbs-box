FROM fedora:25
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

EXPOSE 80 443

ARG UPDATES
ARG UPDATES_TESTING

RUN if [ $UPDATES ]; then dnf update -y; fi && \
    if [ $UPDATES_TESTING ]; then \
            dnf install -y dnf-plugins-core && \
            dnf config-manager --set-enable updates-testing &&\
            dnf -y update; fi && \
    dnf -y install \
        hostname \
        httpd \
        koji-containerbuild-hub \
        koji-hub \
        koji-hub-plugins \
        koji-utils \
        koji-web \
        mod_auth_kerb \
        mod_ssl \
        mod_wsgi \
    && dnf clean all

COPY etc/ /etc/
COPY bin/ /usr/local/bin/

RUN chmod +x /usr/local/bin/* && \
    mkdir -p /mnt/koji/{packages,repos,work,scratch} && \
    chown apache.apache /mnt/koji/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
