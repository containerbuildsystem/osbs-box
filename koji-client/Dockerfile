FROM osbs-box/koji-base

# Install koji-containerbuild cli plugin
RUN dnf install -y "python3-koji-containerbuild-cli" && \
    dnf clean all

# Update koji-containerbuild and copy the cli plugin to the right location
RUN pip3 --no-cache-dir install -U "$KOJI_CONTAINERBUILD_PIP_REF" && \
    copy-kcb-plugin.sh "cli"

COPY bin/ /usr/local/bin/

ENV CLI_PLUGINS="runroot cli_containerbuild"

RUN add-koji-profile.sh "kojiadmin" && \
    pick-koji-profile.sh "kojiadmin"

ENTRYPOINT ["entrypoint.sh"]
CMD ["sleep", "infinity"]
