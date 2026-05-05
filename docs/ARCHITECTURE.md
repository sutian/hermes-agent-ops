# Architecture

## Overview

hermes-agent-ops provides centralized logging for hermes-agent via a scalable, security-hardened stack.

## Components

### Vector Agent
- **Role**: Log shipper
- **Location**: Deployed on each hermes-agent host
- **Function**: Tail log files, parse JSON, batch, compress, forward to Loki
- **Scale**: Stateless — one per hermes host

### Loki
- **Role**: Log aggregation and storage
- **Location**: Dedicated VM (pve12)
- **Function**: Store indexed logs, serve log queries
- **Scale**: Single-instance for Phase 1; distributed mode for Phase 5

### Grafana
- **Role**: Visualization and dashboards
- **Location**: Same VM as Loki
- **Function**: Query Loki, render dashboards, alerting

### Prometheus
- **Role**: Metrics collection
- **Location**: Same VM as Loki
- **Function**: Scrape metrics from Loki, Grafana, Vector agents

## Data Flow

```
1. hermes-agent writes JSON logs to /var/log/hermes/agent.log
2. Vector agent tails the file (read-only)
3. Vector parses JSON, extracts fields, enriches with hostname/trace_id
4. Vector batches logs (1024 events or 1s interval)
5. Vector compresses with gzip and forwards to Loki via HTTP
6. Loki stores chunks on filesystem with TSDB index
7. Grafana queries Loki via LogQL
8. Analysts view dashboards in browser
```

## Network Topology

```
[hermes-agent hosts] ---- mTLS ---->  [Log Server VM]
                                        |-- Loki   :3100
                                        |-- Grafana:3001
                                        |-- Prometheus:9090
                                              |
                                              +-- (future SIEM)
```

## Storage

- Loki data: Docker named volumes
- Grafana data: Docker named volumes
- Both volumes can be backed by Ceph RBD for persistence
