FROM rockylinux:9 AS system

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
    --setopt=install_weak_deps=False --nodocs --releasever=9

# install latex
ARG INSTALL_XETEX=false
RUN if [ "$INSTALL_XETEX" = "true" ]; then \
    dnf install -y --installroot /build texlive-xetex \
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

# remove system tools
RUN chroot /build rm -rf /build/usr/sbin/*

# add configuration files
COPY config/indico.conf /build/etc/indico.tmpl.conf
COPY config/logging.yaml /build/opt/indico/logging.yaml
COPY config/uwsgi-indico.ini /build/etc/
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
RUN indico setup create-symlinks /opt/indico

FROM scratch

ENV LANG=en_US.UTF-8
ENV PATH="/opt/indico/.venv/bin:$PATH"
COPY --from=system /build /
COPY --from=build --chown=indico:indico /opt/indico /opt/indico

USER indico
EXPOSE 8080/tcp
ENTRYPOINT ["/entrypoint.sh"]
CMD []
