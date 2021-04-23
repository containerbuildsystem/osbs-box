FROM osbs-box/koji-base

EXPOSE 80 443

# Install koji-hub components including the containerbuild plugin
RUN dnf -y install "httpd" \
                   "mod_ssl" \
                   "koji-hub" \
                   "koji-web" \
                   "koji-containerbuild-hub" && \
    dnf clean all

# Update koji-containerbuild and copy the hub plugin to the right location
RUN pip3 --no-cache-dir install -U "$KOJI_CONTAINERBUILD_PIP_REF" && \
    copy-kcb-plugin.sh "hub"

# Certificates are mode 0600 and owned by root, apache needs read access too
RUN chown -R :apache /etc/pki/koji/ && \
    chmod -R g+r /etc/pki/koji/

COPY bin/ /usr/local/bin/
COPY etc/ /etc/

ENV HUB_HOST="localhost"

RUN add-koji-profile.sh "kojiadmin" && \
    pick-koji-profile.sh "kojiadmin"

ENTRYPOINT ["entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
