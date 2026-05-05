#!/bin/bash
# install-agent.sh — Install Vector agent on hermes-agent host
# Usage: ./install-agent.sh <LOKI_HOST> <AGENT_ID> <PLATFORM> <COMPONENT>
set -euo pipefail

LOKI_HOST="${1:?Usage: $0 <LOKI_HOST> <AGENT_ID> <PLATFORM> [COMPONENT]}"
AGENT_ID="${2:?}"
PLATFORM="${3:?}"
COMPONENT="${4:-proxmox-mcp}"

ARCH="$(uname -m)"
VECTOR_VERSION="0.55.1"

case "$ARCH" in
  x86_64)  ARCH_STR="x86_64-unknown-linux-musl" ;;
  aarch64) ARCH_STR="aarch64-unknown-linux-musl" ;;
  *)       echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

echo "[*] Installing Vector $VECTOR_VERSION for hermes-agent-ops"
echo "    LOKI_HOST=$LOKI_HOST"
echo "    AGENT_ID=$AGENT_ID"
echo "    PLATFORM=$PLATFORM"
echo "    COMPONENT=$COMPONENT"

# Create vector user and group
if ! id -u vector >/dev/null 2>&1; then
  echo "[*] Creating vector user"
  useradd --system --no-create-home --shell /usr/sbin/nologin vector
fi

# Download and install Vector binary
echo "[*] Downloading Vector binary"
TMPDIR="$(mktemp -d)"
curl -fsSL \
  "https://github.com/vectordotdev/vector/releases/download/v${VECTOR_VERSION}/vector-${VECTOR_VERSION}-${ARCH_STR}.tar.gz" \
  -o "$TMPDIR/vector.tar.gz"

echo "[*] Extracting Vector"
tar -xzf "$TMPDIR/vector.tar.gz" -C "$TMPDIR"
install -o root -g root -m 0755 "$TMPDIR/vector/bin/vector" /usr/local/bin/vector

# Create directories
echo "[*] Creating directories"
mkdir -p /var/lib/vector /etc/vector /var/log/hermes
chown vector:vector /var/lib/vector /var/log/hermes

# Install Vector config from template
echo "[*] Generating /etc/vector/vector.toml"
sed -e "s/\${LOKI_HOST}/$LOKI_HOST/g" \
    -e "s/\${AGENT_ID}/$AGENT_ID/g" \
    -e "s/\${PLATFORM}/$PLATFORM/g" \
    /opt/hermes-agent-ops/agent/vector.toml.template > /etc/vector/vector.toml

echo "[*] Generating /etc/vector/mcp-vector.toml"
sed -e "s/\${LOKI_HOST}/$LOKI_HOST/g" \
    -e "s/\${COMPONENT}/$COMPONENT/g" \
    /opt/hermes-agent-ops/agent/mcp-vector.toml.template > /etc/vector/mcp-vector.toml

chown vector:vector /etc/vector/*.toml
chmod 0640 /etc/vector/*.toml

# Install systemd units
echo "[*] Installing systemd units"
cp /opt/hermes-agent-ops/agent/systemd/vector-agent.service /etc/systemd/system/
cp /opt/hermes-agent-ops/agent/systemd/mcp-vector-agent.service /etc/systemd/system/
systemd-run --systemd-unit=vector-agent.service systemctl daemon-reload || true
systemctl daemon-reload

echo "[*] Starting vector-agent service"
systemctl enable vector-agent --now
systemctl enable mcp-vector-agent --now

echo "[*] Verifying installation"
sleep 2
systemctl status vector-agent --no-pager
systemctl status mcp-vector-agent --no-pager

# Verify Vector API is responding
if curl -sf http://127.0.0.1:9001/health > /dev/null; then
  echo "[+] Vector agent API is healthy"
else
  echo "[!] Warning: Vector agent API not responding"
fi

echo ""
echo "[+] Vector agent installed successfully"
echo "    Logs: journalctl -u vector-agent -f"
echo "    Metrics: curl http://127.0.0.1:9090/metrics"
rm -rf "$TMPDIR"
