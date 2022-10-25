FROM debian:bullseye-slim

LABEL org.opencontainers.image.source=https://github.com/jeremyrea/unbound-docker
LABEL org.opencontainers.image.description="Unbound Docker Image"
LABEL org.opencontainers.image.licenses=MIT

ENV UNBOUND_VERSION=1.17.0
ENV UNBOUND_SOURCE=https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz

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
    rm -f unbound.tar.gz && \
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
    rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh 

RUN chmod +x /run.sh 

USER unbound

EXPOSE 53/tcp
EXPOSE 53/udp

#ENTRYPOINT ["tail", "-f", "/dev/null"]	
CMD [ "/run.sh" ]	

