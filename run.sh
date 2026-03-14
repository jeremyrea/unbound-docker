#!/bin/bash
set -euo pipefail

/opt/unbound/sbin/unbound-anchor -a /opt/unbound/etc/unbound/var/root.key || true
/opt/unbound/sbin/unbound-checkconf
/opt/unbound/sbin/unbound -d
