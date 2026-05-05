# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability within hermes-agent-ops, please report it responsibly.

**Do NOT** report security vulnerabilities through public GitHub issues.

### Private Reporting

1. Create a private vulnerability report via GitHub Security Advisories
2. Or contact the maintainers directly

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes (optional)

### Response Timeline

- **Acknowledgement**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Fix Timeline**: Varies by severity

---

## Security Controls

### Network

- Firewall: allowlist only (ports 22, 3100, 3001, 9090)
- TLS 1.3 for all inter-service communication
- mTLS between Vector agents and Loki

### Secrets Management

- Secrets stored in `.env` — never committed to repo
- Docker secrets for production deployments
- CI/CD: TruffleHog scan prevents secret leaks

### Container Security

- Non-root users in all containers
- Read-only root filesystems where possible
- Image scanning with Trivy in CI
- Signed images with Cosign

### Access Control

- Grafana RBAC: least-privilege
- SSH keys only, no password authentication
- Rotate credentials regularly

### Log Integrity

- Loki WAL prevents data loss
- Checksums on stored chunks
- Vector backpressure prevents log drops

---

## Dependency Security

Dependencies are scanned in CI/CD:

| Tool | Purpose |
|------|---------|
| Trivy | Container vulnerability scanning |
| TruffleHog | Secrets scanning |
| Semgrep | Static code analysis |
| OPA | Policy enforcement |

---

## Compliance

This project follows security best practices aligned with:

- MITRE ATT&CK
- CIS Benchmarks
- NIST SP 800-190
- OCSF (Open Cybersecurity Schema)
