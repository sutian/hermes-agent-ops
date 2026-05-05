# Threat Model

## Scope

- Log server VM (pve12)
- Vector agents on hermes hosts
- Network communication
- CI/CD pipeline

## Threat Actors

| Actor | Capability | Intent |
|-------|-----------|--------|
| External attacker | Network access | Data exfiltration, DoS |
| Malicious insider | SSH access | Log tampering, credential theft |
| Compromised hermes host | Vector agent | Log injection, lateral movement |
| Supply chain attack | CI/CD | Implant malicious code |

## Attack Surface

### Network
- Port 22: SSH (key-only auth required)
- Port 3100: Loki HTTP (TLS required)
- Port 3001: Grafana (RBAC + strong passwords)
- Port 9090: Prometheus (internal only)

### Vector Agent
- Reads log files only (no write access)
- Cannot execute arbitrary commands
- Runs with systemd sandboxing

### Loki
- No authentication (Phase 1) — network isolation only
- Grafana provides authentication layer

## Mitigation Map

| Attack | Mitigation |
|--------|------------|
| Log injection | Vector: JSON parse validates all fields |
| TLS downgrade | Enforce TLS 1.3 only |
| Secret exposure | TruffleHog in CI, no secrets in repo |
| Container escape | Non-root containers, seccomp, cgroups |
| DoS Loki | Rate limiting, Vector buffer |
| SSH brute force | Key-only auth |
| Credential theft | Rotating tokens |

## STRIDE Analysis

| Threat | Type | Impact | Mitigation |
|--------|------|--------|------------|
| Log injection | Tampering | Log integrity | JSON validation |
| Credential theft | Info disclosure | CIA breach | Key-only SSH |
| DoS Loki | Denial of service | Logging downtime | Rate limits, buffering |
| SSH compromise | Privilege escalation | Full VM access | Key-only auth, least privilege |
| Malicious CI | Supply chain | Backdoor | Code signing, Trivy, OPA |
