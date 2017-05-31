FROM centos:7
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

VOLUME [\
    "/opt/osbs", \
    "/opt/koji-clients", \
    "/etc/pki/koji"\
]

EXPOSE 80

COPY yum.repos.d/ /etc/yum.repos.d/

RUN \
    yum -y install \
		openssl \
		hostname \
        httpd \
    && yum clean all

ADD opt/ /opt/
ADD etc/ /etc/
ADD bin/ /usr/local/bin/
ADD root/ /root/

RUN ls -l /usr/local/bin
RUN /usr/local/bin/setup.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
