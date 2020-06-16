FROM fedora:32

RUN dnf -y install \
    httpd \
    mod_auth_gssapi \
    mod_ssl \
    python3-celery \
    python3-flask \
    python3-flask-login \
    python3-flask-migrate \
    python3-flask-sqlalchemy \
    python3-GitPython \
    python3-mod_wsgi \
    python3-pip \
    python3-psycopg2 \
    python3-requests \
    python3-requests-kerberos \
    python3-semver \
    && dnf clean all

COPY bin/ /usr/local/bin/
COPY etc/ /etc/
RUN chmod -R a+r /etc/cachito/settings.py
RUN chmod -R a+r /etc/cachito/celery.py
COPY cachito-httpd.conf /etc/httpd/conf/httpd.conf

ARG CACHITO_PIP_REF
# Install Cachito from git
ENV PIP_PREFIX="/usr"
RUN pip install "$CACHITO_PIP_REF"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /src && ln -s "$(pip show cachito | grep Location | cut -d ' ' -f2)"/cachito /src/cachito

EXPOSE 8080
ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
