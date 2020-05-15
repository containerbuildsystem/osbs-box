FROM fedora:32

RUN dnf -y install \
    golang \
    git-core \
    mercurial \
    npm \
    python3-celery \
    python3-GitPython \
    python3-pip \
    python3-requests \
    python3-requests-kerberos \
    python3-semver \
    && dnf clean all

COPY etc/ /etc/
RUN chmod -R a+r /etc/cachito/celery.py

ARG CACHITO_PIP_REF
# Install Cachito from git
ENV PIP_PREFIX="/usr"
RUN pip install "$CACHITO_PIP_REF"

EXPOSE 8080
CMD ["/bin/celery-3", "-A", "cachito.workers.tasks", "worker", "--loglevel=debug"]
