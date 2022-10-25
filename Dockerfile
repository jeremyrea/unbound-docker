FROM debian:bullseye-slim as unbound

ENV UNBOUND_VERSION=1.17.0
ENV UNBOUND_SOURCE=https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz

WORKDIR /tmp

RUN build_packages="\
	wget2 \
        make \
	gcc \
	bison \
	flex \
	openssl \
	libssl-dev \
	libc6-dev \
	libexpat1-dev \
	libevent-dev \
	libhiredis-dev" && \
    apt-get update && apt-get install -y --no-install-recommends \
	${build_packages} \
	ca-certificates \
	libc6 \
	libexpat1 \
	libevent-2.1-7 \
	libhiredis0.14 && \
    wget2 "${UNBOUND_SOURCE}" -O unbound.tar.gz && \
    tar xzf unbound.tar.gz && \
    cd unbound-${UNBOUND_VERSION} && \
    ./configure \
	--disable-dependency-tracking \
	--prefix=/opt/unbound \
	--with-libevent \
	--with-pthreads \
	--enable-cachedb \
	--with-libhiredis && \
    make && \
    make install && \
    groupadd -r unbound && \
    useradd -r -g unbound unbound && \
    mkdir /opt/unbound/etc/unbound/unbound.conf.d && \
    mkdir /opt/unbound/etc/unbound/var && \
    chown unbound:unbound /opt/unbound/etc/unbound/var && \
    apt-get purge --auto-remove -y ${build_packages} && \
    rm -rf \
	/var/lib/apt/lists/* \
	/tmp/*


FROM debian:bullseye-slim

COPY --from=unbound /opt /opt

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libc6 \
        libexpat1 \
        libevent-2.1-7 \
        libhiredis0.14 && \
    groupadd -r unbound && \
    useradd -r -g unbound unbound && \
    apt-get purge --auto-remove -y && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh 

RUN chmod +x /run.sh 

USER unbound

EXPOSE 53/tcp
EXPOSE 53/udp

LABEL org.opencontainers.image.source=https://github.com/jeremyrea/unbound-docker \
      org.opencontainers.image.description="Unbound Docker Image" \
      org.opencontainers.image.licenses=MIT

#ENTRYPOINT ["tail", "-f", "/dev/null"]	
CMD [ "/run.sh" ]	

