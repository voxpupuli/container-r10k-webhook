#!/bin/sh

set -e

# set group-writable
umask 0002

for f in /container-entrypoint.d/*.sh; do
	echo "Running $f"
	"$f"
done

exec /usr/sbin/webhook-go "$@"
