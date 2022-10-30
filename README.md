# unbound-docker

[Unbound](https://nlnetlabs.nl/projects/unbound/about/) is a validating, recursive, caching DNS resolver.

## What's different with this docker image of Unbound?
Unbound is compiled with the `--enable-cachedb` and `--with-libhiredis` flags, allowing it to use Redis as a second level cache and persist resolved DNS queries across container restarts. More details about this module can be found [here](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html?highlight=cachedb#cache-db-module-options).

## Usage

### Basic command
``` shell
docker run \
  --name unbound \
  -p 53:53/tcp \
  -p 53:53/udp \
  ghcr.io/jeremyrea/unbound-docker:latest
```

### With cachedb module enabled

Inside a directory you will mount containing config files, you would add the following file to connect to your Redis instance:

#### **`cachedb.conf`**
``` conf
server:
  module-config: "validator cachedb iterator"
  
cachedb:
  backend: "redis"
  # secret seed string to calculate hashed keys
  secret-seed: "my-secret"

  # redis server's IP address or host name
  redis-server-host: 127.0.0.1
  # redis server's TCP port
  redis-server-port: 6379
  # timeout (in ms) for communication with the redis server
  redis-timeout: 100
  # set timeout on redis records based on DNS response TTL
  redis-expire-records: yes
```

``` shell
docker run \
  --name unbound \
  -p 53:53/tcp \
  -p 53:53/udp \
  -v /path/to/config:/opt/unbound/etc/unbound/unbound.conf.d \
  ghcr.io/jeremyrea/unbound-docker:latest
```

Any other configs you wish to add or modify from the image defaults can be done by adding more .conf files inside the unbound.conf.d directory. A full list of available settings is available on [Unbound's documentation](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html).
