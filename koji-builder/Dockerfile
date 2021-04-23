FROM osbs-box/koji-base

# Install koji builder components including
# the containerbuild plugin and osbs-client
RUN dnf -y install "koji-builder" \
                   "koji-containerbuild-builder" \
                   "osbs-client" && \
    dnf clean all

# Update osbs-client and koji-containerbuild,
# copy the builder plugin to the right location
RUN pip3 --no-cache-dir install -U "$OSBS_CLIENT_PIP_REF" && \
    pip3 --no-cache-dir install -U "$KOJI_CONTAINERBUILD_PIP_REF" && \
    copy-kcb-plugin.sh "builder"

COPY bin/ /usr/local/bin/
COPY etc/ /etc/

RUN add-koji-profile.sh "kojiadmin" && \
    pick-koji-profile.sh "kojiadmin"

ENTRYPOINT ["entrypoint.sh"]
CMD ["kojid", "--fg", "--force-lock", "--verbose"]
