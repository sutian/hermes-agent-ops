# Performance

## Benchmarks

### Loki (single instance)

| Metric | Value |
|--------|-------|
| Ingest rate | Up to 50 MB/s |
| Query latency (p99) | < 2s for 30-day range |
| Storage efficiency | ~30% smaller than ELK (TSDB compression) |
| Memory usage | ~2-4 GB under load |

### Vector Agent

| Metric | Value |
|--------|-------|
| CPU usage | ~1-2% per agent |
| Memory usage | ~50-100 MB |
| Throughput | ~50,000 events/sec |
| Disk buffer | Up to 5 GB |

## Tuning Guide

### Vector

```toml
[sinks.loki]
request.batch_size = 1024
request.concurrency = 10
compression = "gzip"

[sinks.loki.buffer]
type = "disk"
max_size = 5368704000
num_shards = 4
```

### Loki

```yaml
limits_config:
  ingestion_rate_mb: 50
  ingestion_burst_size_mb: 200
  max_streams_per_user: 100
```

### Linux Kernel (on log server)

```bash
echo 65536 > /proc/sys/fs/inotify/max_user_watches
echo 16384 > /proc/sys/fs/inotify/max_queued_instances
ulimit -n 65536
```

## Capacity Planning

| Users | Loki RAM | Loki Storage/day |
|-------|----------|-----------------|
| 1-5   | 2 GB     | ~500 MB         |
| 5-20  | 4 GB     | ~2 GB           |
| 20+   | 8 GB     | ~5 GB+          |

## Monitoring

Key metrics to watch:
- `loki_request_duration_seconds` — query latency
- `loki_ingester_streams` — active log streams
- `vector_buffer_events` — buffered events
- `vector_buffer_bytes` — buffer usage
