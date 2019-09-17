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
RUN $PIP install -U "$KOJI_CONTAINERBUILD_PIP_REF" && \
    copy-kcb-plugin.sh "hub"

COPY bin/ /usr/local/bin/
COPY etc/ /etc/

ENTRYPOINT ["entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
