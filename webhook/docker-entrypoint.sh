#!/bin/sh

set -e

if [ -d /docker-entrypoint.d/ ]; then
    find /docker-entrypoint.d/ -type f -name "*.sh" \
        -exec echo Running {} \; -exec sh {} \;
fi

args="$@"
su puppet -c "exec /usr/sbin/webhook-go $args"
