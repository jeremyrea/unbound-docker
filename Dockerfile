FROM debian:bullseye-slim

ENV UNBOUND_VERSION=1.17.0
ENV UNBOUND_SOURCE=https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz

RUN apt-get update && apt-get install -y \
	wget2 \
	tar \
	make \
        build-essential \
        bison \
        flex \
	openssl \
	libssl-dev \
	libexpat1 \
	libexpat1-dev && \
    wget2 "${UNBOUND_SOURCE}" -O unbound.tar.gz && \
    tar xzf unbound.tar.gz && \
    rm unbound.tar.gz && \
    cd unbound-${UNBOUND_VERSION} && \
    ./configure \
        --disable-dependency-tracking \
    	--prefix=/opt/unbound && \
    make && \
    make install && \
    groupadd -r unbound && \
    useradd -r -g unbound unbound

USER unbound

EXPOSE 53/tcp
EXPOSE 53/udp

#ENTRYPOINT ["tail", "-f", "/dev/null"]	
ENTRYPOINT [ "/opt/unbound/sbin/unbound" ]	

