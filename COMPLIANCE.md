# Compliance & Standards

## Aligned Standards

### MITRE ATT&CK

This project considers MITRE ATT&CK tactics for logging and monitoring:

| Tactic | Technique | Mitigation |
|--------|-----------|------------|
| **TA0001 - Initial Access** | Phishing, credential stuffing | Network segmentation, MFA |
| **TA0002 - Execution** | Log injection | Input validation via Vector |
| **TA0003 - Persistence** | SSH key tampering | Key rotation, monitoring |
| **TA0005 - Defense Evasion** | Log deletion | Log integrity checks, WAL |
| **TA0011 - C2** | Exfiltration prevention | TLS encryption, mTLS |
| **TA0040 - Impact** | DoS | Rate limiting, Vector buffer |

### CIS Benchmarks

Applied to:
- Log server VM OS hardening
- Docker container configuration
- Kubernetes (future) cluster hardening

### NIST SP 800-190

Container security guidance applied to:
- Image provenance (Cosign signing)
- Runtime security (seccomp, cgroups)
- Registry security (image scanning)

### OCSF (Open Cybersecurity Schema)

Log format aligned with OCSF schema:

```json
{
  "timestamp": "2026-05-05T13:40:00.000Z",
  "level": "INFO",
  "service": "hermes-agent",
  "host": "<HERMES_HOST_IP>",
  "message": "Tool executed",
  "user": "<USER_NAME>",
  "status": "success"
}
```

### TLS 1.3 + mTLS

- All log transport encrypted with TLS 1.3
- mTLS for Vector → Loki communication
- Certificate rotation every 90 days

### Zero Trust

- No implicit trust between services
- Every connection authenticated and authorized
- Least-privilege access at every layer
