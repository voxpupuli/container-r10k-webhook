#!/bin/sh

set -e

for f in /container-entrypoint.d/*.sh; do
	echo "Running $f"
	"$f"
done

exec /usr/sbin/webhook-go "$@"
