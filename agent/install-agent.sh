#!/usr/bin/env bash
set -euo pipefail

LOKI_HOST="${LOKI_HOST:-CHANGE_ME}"
ENV="${ENV:-production}"

echo "==> Installing Vector Agent for hermes-agent-ops"
echo "    Loki host: ${LOKI_HOST}"
echo "    Env: ${ENV}"

if [ ! -f /etc/debian_version ]; then
  echo "ERROR: This script only supports Debian/Ubuntu"
  exit 1
fi

VECTOR_VERSION="0.55.0"
echo "==> Downloading Vector ${VECTOR_VERSION}"

curl -fsSL \
  "https://github.com/vectordotdev/vector/releases/download/v${VECTOR_VERSION}/vector-${VECTOR_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
  -o /tmp/vector.tar.gz

mkdir -p /opt/vector
tar -xzf /tmp/vector.tar.gz -C /opt/vector --strip-components=1
ln -sf /opt/vector/bin/vector /usr/local/bin/vector
rm -f /tmp/vector.tar.gz

echo "==> Vector installed: $(vector --version)"

mkdir -p /var/log/hermes /etc/vector /var/lib/vector

curl -fsSL \
  "https://raw.githubusercontent.com/sutian/hermes-agent-ops/main/agent/vector.toml.template" \
  -o /etc/vector/vector.toml

sed -i "s/\${LOKI_HOST}/${LOKI_HOST}/g" /etc/vector/vector.toml
sed -i "s/\${ENV}/${ENV}/g" /etc/vector/vector.toml

curl -fsSL \
  "https://raw.githubusercontent.com/sutian/hermes-agent-ops/main/agent/systemd/vector-agent.service" \
  -o /etc/systemd/system/vector-agent.service

systemctl daemon-reload
systemctl enable vector-agent
systemctl restart vector-agent

echo "==> Vector agent started"
echo ""
echo "==> Installation complete"
echo "    Config: /etc/vector/vector.toml"
echo "    Logs:   journalctl -u vector-agent -f"
