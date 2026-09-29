FROM rockylinux:9 AS system

# install requirements
RUN dnf install -y 'dnf-command(copr)'

# install image base
RUN dnf install -y --installroot /build \
    rocky-release \
    coreutils-single \
    glibc-minimal-langpack \
    glibc-langpack-en \
    --setopt=install_weak_deps=False --nodocs --releasever=9

# install python and dependencies
RUN dnf install -y --installroot /build \
    python3.12 \
    postgresql \
    postgresql-libs \
    glib2 \
    pango \
    openssl-libs \
    xmlsec1 \
    --setopt=install_weak_deps=False --nodocs --releasever=9

# install latex
ARG INSTALL_XETEX=false
RUN if [ "$INSTALL_XETEX" = "true" ]; then \
    dnf install -y --installroot /build texlive-xetex \
        --setopt=install_weak_deps=False --nodocs --releasever=9; \
    fi;

# add caddy repo
RUN dnf copr enable -y --installroot /build --releasever=9 @caddy/caddy

# add shibboleth repo
COPY <<EOF /build/etc/yum.repos.d/shibboleth.repo
[shibboleth]
name=Shibboleth (rockylinux9)
# Please report any problems to https://shibboleth.atlassian.net/jira
type=rpm-md
mirrorlist=https://shibboleth.net/cgi-bin/mirrorlist.cgi/rockylinux9
gpgcheck=1
gpgkey=https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key
enabled=1
EOF

# install shibboleth
ARG INSTALL_SHIBBOLETH=false
RUN if [ "$INSTALL_SHIBBOLETH" = "true" ]; then \
    dnf install -y --installroot /build httpd-core shibboleth-sp shibboleth \
        --setopt=install_weak_deps=False --nodocs --releasever=9 && \
    mkdir -p /build/run/shibboleth && \
    chmod 755 /build/run/shibboleth ; \
    fi;

# install caddy
RUN if [ "$INSTALL_SHIBBOLETH" = "false" ]; then \
    dnf install -y --installroot /build caddy \
        --setopt=install_weak_deps=False --nodocs --releasever=9; \
    fi;

# dnf clean
RUN dnf clean --installroot /build all

# add indico user
RUN chroot /build groupadd -g 1000 indico && \
    chroot /build useradd -u 1000 -g indico -d /opt/indico -s /sbin/nologin indico

# create directories
RUN chroot /build mkdir -p /data /var/log/indico /var/cache/indico /var/tmp/indico && \
    chroot /build chown -R indico:indico /data /var/log/indico /var/cache/indico /var/tmp/indico

# apache dirs
RUN chroot /build mkdir -p /var/log/httpd && \
    chroot /build chown -R indico:indico /var/log/httpd && \
    chroot /build mkdir -p /etc/httpd/run && \
    chroot /build chown indico:indico /etc/httpd/run && \
    chroot /build chmod 755 /etc/httpd/run

# add configuration files
COPY config/indico.conf /build/etc/indico.tmpl.conf
COPY config/logging.yaml /build/opt/indico/logging.yaml
COPY config/uwsgi-indico.ini /build/etc/
COPY config/Caddyfile /build/etc/caddy/Caddyfile
COPY config/apache.conf /build/etc/httpd/conf.d/99-indico.conf
COPY entrypoint.sh /build

FROM rockylinux:9 AS build

RUN dnf install -y gcc python3.12-devel postgresql-devel

# create virtualenv
RUN python3.12 -m venv /opt/indico/.venv
ENV PATH="/opt/indico/.venv/bin:$PATH"

# instll indico
ARG INDICO_VERSION=">=3.3,<3.4"
RUN pip install setuptools wheel
RUN pip install uwsgi
RUN pip install "indico${INDICO_VERSION}" indico-plugins
RUN pip install python3-saml
RUN indico setup create-symlinks /opt/indico

FROM scratch

ENV LANG=en_US.UTF-8
ENV XDG_CACHE_HOME=/tmp
ENV PATH="/opt/indico/.venv/bin:$PATH"
COPY --from=system /build /
COPY --from=build --chown=indico:indico /opt/indico /opt/indico

USER indico
EXPOSE 8080/tcp
ENTRYPOINT ["/entrypoint.sh"]
CMD []
