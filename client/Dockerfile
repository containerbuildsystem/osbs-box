FROM centos:7
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

COPY yum.repos.d/ /etc/yum.repos.d/

RUN \
    yum install -y \
    atomic-openshift-clients \
    iproute \
    koji-containerbuild-cli \
    && yum clean all

ADD bin/ /usr/local/bin/

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
