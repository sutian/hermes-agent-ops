# hermes-agent-ops — Specification & Project Plan

## 1. Project Goal

สร้าง centralized observability stack สำหรับ hermes-agent เก็บ logs → วิเคราะห์ → ส่งต่อ SIEM ได้ในอนาคต

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│  hermes-agent (pve11 / 192.168.1.11)                  │
│  Vector Agent ──── tail /var/log/hermes/               │
│    ├── agent.log    (hermes logs)                      │
│    └── mcp.log     (MCP/Proxmox logs)                 │
└────────────────────────┬────────────────────────────────┘
                         │ mTLS / TLS 1.3
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Log Server VM (pve12 / NEW)                           │
│                                                          │
│  ┌──────────┐  ┌───────────┐  ┌────────────┐           │
│  │  Loki    │  │ Grafana   │  │ Prometheus │           │
│  │  :3100   │  │  :3001    │  │   :9090    │           │
│  └──────────┘  └───────────┘  └────────────┘           │
│       │              │                                  │
│       └──────────────┴────── Ceph/NFS storage          │
└─────────────────────────────────────────────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │  SIEM (future)       │
                     │  Splunk / Elastic /   │
                     │  Sentinel / QRadar    │
                     └─────────────────────┘
```

---

## 3. Scalability Design

### Horizontal Scale (out)

- **Vector Agent** — stateless, deploy ทุก hermes host ได้เลย
- **Loki** — distributed mode เพิ่ม read/write nodes ได้
- **Grafana** — read-only replicas ได้
- **Prometheus** — HA mode ได้

### Vertical Scale (up)

- Log Server VM spec เริ่มต้น: 4vCPU / 8GB RAM / 100GB SSD
- ขยายได้เมื่อ log volume เพิ่ม

### Storage

- Loki data อยู่บน Ceph/NFS shared storage
- Grafana dashboards อยู่บน shared volume

---

## 4. Security Design

### Standards

| Standard | Usage |
|----------|-------|
| **MITRE ATT&CK** | Threat modeling |
| **CIS Benchmarks** | VM hardening |
| **NIST SP 800-190** | Container security |
| **OCSF** | Log schema format |
| **TLS 1.3 + mTLS** | Transport encryption |
| **Zero Trust** | Network segmentation |

### Security Controls

| Layer | Control | Implementation |
|-------|---------|----------------|
| **Network** | Firewall | ufw / iptables — allowlist only |
| **Transport** | TLS 1.3 + mTLS | Vector → Loki: cert-based auth |
| **Secrets** | Secret management | `.env` + `docker secrets` |
| **Log integrity** | Signed logs | Loki WAL + checksum |
| **Log injection** | Input validation | Vector: parse & validate JSON |
| **Access control** | RBAC | Grafana: role-based, least-privilege |
| **DoS protection** | Rate limiting | Loki: `ingestion_rate_mb`, Vector: `buffer` |
| **Secrets scanning** | CI/CD gate | TruffleHog scan ก่อน push |
| **Image signing** | Cosign/Syft | Sign Docker images in CI |

### Threat Mitigation (STRIDE-lite)

| Threat | Mitigation |
|--------|------------|
| **Tampering** (log injection) | Vector: parse & validate JSON, reject malformed |
| **Information disclosure** | TLS in transit, no plaintext logs on wire |
| **Denial of service** | Loki: rate limit per tenant, Vector: backpressure |
| **Privilege escalation** | VM: non-root user for containers, cgroups/seccomp |

---

## 5. Performance Design

### Performance Controls

| Component | Tuning |
|-----------|--------|
| **Vector** | `batch_size=1024`, `buffer_type=disk`, `compression=gzip` |
| **Vector → Loki** | HTTP/2, keepalive, gzip compression |
| **Loki ingest** | `ingestion_rate_mb=50`, `ingestion_burst_size_mb=200` |
| **Loki TSDB** | 24h index period, compressed chunks |
| **Storage** | LVM / fast disk for Loki chunks (SSD บน Ceph) |
| **Horizontal scale** | เพิ่ม Vector agents บน hermes hosts หลายตัว |

### Vector Buffer Config

```toml
[sinks.loki]
type = "loki"
...
[sinks.loki.buffer]
  type = "disk"
  max_size = 5368704000   # 5GB disk buffer
  when_full = "block"     # backpressure ถ้า Loki ล่ม
```

---

## 6. Log Format (OCSF-aligned)

### Agent Log Format

```json
{
  "timestamp": "2026-05-05T13:40:00.000Z",
  "level": "INFO",
  "logger": "hermes.agent",
  "message": "Tool executed",
  "service": "hermes-agent",
  "host": "192.168.1.11",
  "agent_id": "main",
  "session_id": "abc123",
  "platform": "telegram",
  "user": "OxTigger",
  "tool_name": "proxmox_vm_create",
  "duration_ms": 234,
  "status": "success",
  "error": null,
  "ip_source": "127.0.0.1",
  "trace_id": "trace-abc123"
}
```

### MCP Log Format

```json
{
  "timestamp": "2026-05-05T13:40:00.000Z",
  "level": "INFO",
  "logger": "mcp.proxmox",
  "message": "Tool called",
  "service": "proxmox-mcp",
  "component": "mcp-server",
  "host": "192.168.1.9",
  "mcp_tool_name": "proxmox_vm_create",
  "mcp_request_id": "req-abc123",
  "mcp_session_id": "sess-xyz",
  "duration_ms": 234,
  "status": "success",
  "error_code": null,
  "user": "OxTigger",
  "ip_source": "127.0.0.1",
  "trace_id": "trace-abc123"
}
```

### Loki Labels

```
# Agent logs
{service="hermes-agent", host="192.168.1.11", level="info", platform="telegram"}

# MCP logs
{service="mcp", component="proxmox-mcp", host="192.168.1.9", status="success"}
```

---

## 7. Components

### Infrastructure Components

| Component | Version | Role |
|-----------|---------|------|
| **Vector Agent** | 0.55.x | Log shipper — tail files, transform, forward |
| **Loki** | 3.7.x | Log aggregation & storage |
| **Grafana** | 13.x | Visualization & dashboards |
| **Prometheus** | latest | Metrics for Loki/Grafana/Vector |

### Log Server VM Spec

| Spec | Value | Notes |
|------|-------|-------|
| vCPU | 4 | Scale up ขึ้นได้ |
| RAM | 8 GB | Loki กิน ~2-4GB |
| Disk | 100 GB | บน Ceph ของ pve12 |
| OS | Debian 12 | เหมือนเครื่องอื่น |
| IP | DHCP → fixed | ต้อง assign static |
| Ports | 3100, 3001, 9090, 22 | Loki, Grafana, Prometheus, SSH |

---

## 8. Project Phases

| Phase | Content | Status |
|-------|---------|--------|
| **Phase 1** | Loki + Grafana + Vector agent (single VM) | 🔲 กำลังจะทำ |
| **Phase 2** | เพิ่ม MCP log monitoring | 🔲 |
| **Phase 3** | Prometheus metrics + alerting | 🔲 |
| **Phase 4** | SIEM forwarding (Splunk/Elastic) | 🔲 |
| **Phase 5** | Horizontal scale — distributed Loki | 🔲 |

---

## 9. Next Steps

| # | Owner | หมายเหตุ |
|---|-------|----------|
| สร้าง VM บน pve12 | คุณ | ให้ IP + SSH access มา |
| Terraform apply → provision VM | ผม | หลังมี IP |
| Deploy: Loki + Grafana + Vector | CI/CD | หลัง provision |
| Verify + import dashboard | ผม | หลัง deploy |
