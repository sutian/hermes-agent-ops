# hermes-agent-ops

> Observability stack for hermes-agent — log aggregation with Loki, Grafana dashboards, and Vector log shippers.

## Overview

Centralized logging infrastructure for hermes-agent with SIEM-ready architecture.

```
hermes-agent  ──►  Vector Agent  ──►  Loki  ──►  Grafana
                         │
                         └──────────────────────►  SIEM (future)
```

## Features

- **Log Aggregation** — Loki stores and indexes logs from all hermes-agent hosts
- **Visualization** — Grafana dashboards for real-time monitoring
- **MCP Logging** — Monitor Proxmox MCP tool calls
- **SIEM-Ready** — Vector supports Splunk, Elastic, Sentinel, QRadar, and more
- **Security** — TLS encryption, RBAC, secrets scanning in CI/CD
- **Scalable** — Horizontal scale via distributed Loki + multiple Vector agents

## Architecture

| Component | Description |
|-----------|-------------|
| **Vector Agent** | Log shipper per hermes host — tail files, transform, forward |
| **Loki** | Log aggregation server — stores indexed logs |
| **Grafana** | Dashboards — visualize logs, metrics, alerts |
| **Prometheus** | Metrics collection for Loki/Grafana/Vector |

## Documentation

- [SPEC.md](./SPEC.md) — Full specification and project plan
- [docs/](./docs/) — Architecture, threat model, performance notes

## Quick Start

### 1. Provision Log Server

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox credentials
terraform init
terraform apply
```

### 2. Deploy Stack

```bash
# Set environment variables
export LOG_SERVER_HOST=your-log-server-ip
export GRAFANA_ADMIN_PASSWORD=your-secure-password

# Deploy via docker-compose
cd docker
docker compose up -d
```

### 3. Install Vector Agent (per hermes host)

```bash
# On each hermes-agent host
curl -sSL https://raw.githubusercontent.com/sutian/hermes-agent-ops/main/agent/install-agent.sh | bash
```

## Security

See [SECURITY.md](./SECURITY.md) for vulnerability reporting and security controls.

## License

MIT
