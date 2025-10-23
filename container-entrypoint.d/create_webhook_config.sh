#!/bin/sh

cat > /etc/webhook.yml << EOF
server:
  protected: true
  user: ${USER}
  password: ${PASSWORD}
  port: ${PORT}
  tls:
    enabled: ${TLS}
    certificate: ${TLS_CERT:-""}
    key: ${TLS_KEY:-""}
  queue:
    enabled: ${ENABLE_QUEUE}
    max_concurrent_jobs: ${MAX_CONCURRENT_JOBS}
    max_history_items: ${MAX_HISTORY_ITEMS}
chatops:
  enabled: ${CHAT}
  service: ${CHAT_SERVICE}
  channel: ${CHAT_CHANNEL}
  user: ${CHAT_USER}
  auth_token: ${CHAT_TOKEN}
  server_uri: ${CHAT_URL}
r10k:
  command_path: /usr/local/bin/r10k
  config_path: /etc/puppetlabs/r10k/r10k.yaml
  default_branch: ${DEFAULT_BRANCH}
  allow_uppercase: false
  verbose: ${VERBOSE}
  generate_types: ${GENERATE_TYPES}
EOF
