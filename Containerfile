FROM registry.suse.com/bci/bci-base:16.0 AS base

RUN zypper dup -y && zypper install -y \
    awk \
		curl \
		make \
		gcc \
		bison \
		flex \
		openssl \
    libopenssl-devel \
		glibc-devel \
		libexpat-devel \
		libevent-devel \
		ca-certificates && \
    zypper addrepo https://download.opensuse.org/tumbleweed/repo/oss/ tumbleweed && \
    zypper --gpg-auto-import-keys refresh && \
    zypper install -y libhiredis1_3_0 hiredis-devel && \
    zypper removerepo tumbleweed

FROM base AS build

ENV UNBOUND_VERSION=1.24.2
ENV UNBOUND_URL=https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz

WORKDIR /tmp

RUN curl -fsSL "${UNBOUND_URL}" -o unbound.tar.gz && \
    tar -xzf unbound.tar.gz && \
    cd unbound-${UNBOUND_VERSION} && \
    ./configure \
      --prefix=/opt/unbound \
      --with-libevent \
      --with-pthreads \
      --enable-cachedb \
      --with-libhiredis && \
    make && \
    make install && \
    strip /opt/unbound/sbin/unbound \
      /opt/unbound/sbin/unbound-anchor \
      /opt/unbound/sbin/unbound-checkconf \
      /lib64/libssl.so.3 \
      /lib64/libevent-2.1.so.7 \
      /lib64/libexpat.so.1 \
      /lib64/libcrypto.so.3 \
      /lib64/libhiredis.so.1.3.0 \
      /lib64/libjitterentropy.so.3 \
      /lib64/libz.so.1 && \
    rm -rf \
      /opt/unbound/include \
      /opt/unbound/share \
      /opt/unbound/lib/libunbound.a \
      /opt/unbound/lib/libunbound.la \
      /opt/unbound/lib/pkgconfig \
      /opt/unbound/lib/libunbound.so \
      /opt/unbound/sbin/unbound-host \
      /opt/unbound/sbin/unbound-control \
      /opt/unbound/sbin/unbound-control-setup \
      /tmp/unbound-* && \
    groupadd -r unbound && \
    useradd -r -g unbound unbound && \
    mkdir /opt/unbound/etc/unbound/unbound.conf.d && \
    mkdir /opt/unbound/etc/unbound/var && \
    chown unbound:unbound /opt/unbound/etc/unbound/var

COPY data/unbound.conf /opt/unbound/etc/unbound/unbound.conf

FROM registry.suse.com/bci/bci-micro:16.0

COPY --from=build /opt /opt
COPY --from=build /lib64/libssl.so.3 /lib64/
COPY --from=build /lib64/libevent-2.1.so.7 /lib64/
COPY --from=build /lib64/libexpat.so.1 /lib64/
COPY --from=build /lib64/libcrypto.so.3 /lib64/
COPY --from=build /lib64/libhiredis.so.1.3.0 /lib64/
COPY --from=build /lib64/libjitterentropy.so.3 /lib64/
COPY --from=build /lib64/libz.so.1 /lib64/
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY run.sh /run.sh

USER unbound

EXPOSE 53/tcp \
       53/udp

LABEL org.opencontainers.image.source=https://github.com/jeremyrea/unbound-docker \
      org.opencontainers.image.description="Unbound Docker Image" \
      org.opencontainers.image.licenses=MIT

CMD [ "/run.sh" ]	

