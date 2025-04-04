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
chatops:
  enabled: false
  service: slack
  channel: "#general"
  user: r10kbot
  auth_token: 12345
  server_uri: "https://rocketchat.local"
r10k:
  command_path: /usr/local/bin/r10k
  config_path: /etc/puppetlabs/r10k/r10k.yaml
  default_branch: ${DEFAULT_BRANCH}
  allow_uppercase: false
  verbose: ${VERBOSE}
  generate_types: ${GENERATE_TYPES}
EOF
