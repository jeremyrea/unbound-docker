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
		ca-certificates

FROM base AS build-hiredis
ENV VER_HIREDIS=1.3.0
RUN curl -sSL https://github.com/redis/hiredis/archive/refs/tags/v${VER_HIREDIS}.tar.gz | tar xz -C /tmp
RUN cd /tmp/hiredis-${VER_HIREDIS} && \
    make && \
    make PREFIX=/usr/local install

FROM base AS build
COPY --from=build-hiredis /usr/local /usr/local

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
      --with-libhiredis \
      --enable-cachedb && \
    make && \
    make install && \
    strip /opt/unbound/sbin/unbound \
      /opt/unbound/sbin/unbound-anchor \
      /opt/unbound/sbin/unbound-checkconf \
      /lib64/libssl.so.3 \
      /lib64/libevent-2.1.so.7 \
      /lib64/libexpat.so.1 \
      /lib64/libcrypto.so.3 \
      /lib64/libjitterentropy.so.3 \
      /lib64/libz.so.1 \
      /usr/local/lib/libhiredis.so.1.3.0 && \
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
COPY --from=build /lib64/libjitterentropy.so.3 /lib64/
COPY --from=build /lib64/libz.so.1 /lib64/
COPY --from=build /usr/local/lib/libhiredis.so.1.3.0 /lib64/
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

