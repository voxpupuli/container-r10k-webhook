#!/bin/sh

set -e

find /docker-entrypoint.d/ -type f -name "*.sh" -exec echo Running {} \; -exec {} \;

args="$@"
su puppet -c "exec /usr/sbin/webhook-go $args"
