#!/bin/sh

case "${PROTECTED}" in
  true|false) ;;
  *)
    echo "ERROR: PROTECTED must be 'true' or 'false', got '${PROTECTED}'" >&2
    exit 1
    ;;
esac

# Quote a value as a YAML single-quoted scalar, so characters such as '#', ':'
# or a leading '*' in a secret cannot change the meaning of the file.
yaml_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"
}

secrets=""
add_secret() {
  if [ -n "$2" ]; then
    # YAML would fold a newline into a space and silently change the secret
    if [ "$(printf '%s' "$2" | wc -l)" -gt 0 ]; then
      echo "ERROR: the secret for $1 must not contain a newline" >&2
      exit 1
    fi
    secrets="${secrets}  $1: $(yaml_quote "$2")
"
  fi
}
add_secret github "${SECRETS_GITHUB}"
add_secret gitlab "${SECRETS_GITLAB}"
add_secret bitbucket "${SECRETS_BITBUCKET}"
add_secret bitbucket_server "${SECRETS_BITBUCKET_SERVER}"
add_secret gitea "${SECRETS_GITEA}"
add_secret azure_devops "${SECRETS_AZURE_DEVOPS}"

if [ "${PROTECTED}" = "false" ] && [ -z "${secrets}" ]; then
  echo "WARNING: PROTECTED=false and no SECRETS_* set: anyone who can reach the port can trigger deployments" >&2
fi

cat > /etc/voxpupuli/webhook/webhook.yml << EOF
server:
  protected: ${PROTECTED}
  user: ${USER}
  password: ${PASSWORD}
  port: ${PORT}
  deploy_on_success_only: ${DEPLOY_ON_SUCCESS_ONLY}
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

# Only providers with a secret are written, an unset one keeps verification off.
if [ -n "${secrets}" ]; then
  printf 'secrets:\n%s' "${secrets}" >> /etc/voxpupuli/webhook/webhook.yml
fi

# The file may now hold secrets, keep it away from other users.
chmod 0660 /etc/voxpupuli/webhook/webhook.yml
