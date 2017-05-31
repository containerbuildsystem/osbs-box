FROM centos:7
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

COPY yum.repos.d/ /etc/yum.repos.d/

# Latest mock pacakge build's dependencies are broken,
# hard-coded to a previous working version instead.
# Should be removed once resolved.
RUN \
    yum -y install --nogpgcheck \
        mock-1.2.17-1.el7 \
        koji-builder \
        koji-containerbuild-builder \
        osbs-client \
        python-osbs-client \
        python-hashlib \
        python-pip \
    && yum clean all

ADD etc/ /etc/
ADD bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/kojid", "-f", "--force-lock"]
