#!/bin/bash

/opt/unbound/sbin/unbound-anchor -a /opt/unbound/etc/unbound/var/root.key
/opt/unbound/sbin/unbound-checkconf
/opt/unbound/sbin/unbound
