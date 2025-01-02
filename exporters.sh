#!/bin/bash

# Step 1: Start Node Exporter
echo "Starting Node Exporter..."
/usr/local/bin/node_exporter --web.listen-address=":9100" > /workspace/node_exporter.log 2>&1 &
NODE_EXPORTER_PID=$!

# Step 2: Start Blackbox Exporter
echo "Starting Blackbox Exporter..."
cat <<EOF > /workspace/blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 5s
EOF
/usr/local/bin/blackbox_exporter --config.file=/workspace/blackbox.yml --web.listen-address=":9115" > /workspace/blackbox_exporter.log 2>&1 &
BLACKBOX_EXPORTER_PID=$!

# Step 3: Start Prometheus Aggregate Exporter
echo "Starting Prometheus Aggregate Exporter..."
/usr/local/bin/prometheus-aggregate-exporter \
  -targets http://localhost:9100/metrics,http://localhost:9115/metrics \
  -server.bind ":9095" > /workspace/prometheus_aggregate_exporter.log 2>&1 &
AGGREGATE_EXPORTER_PID=$!

# Wait for all processes
echo "Monitoring services are starting. Waiting for processes to stay active..."
wait $NODE_EXPORTER_PID $BLACKBOX_EXPORTER_PID $AGGREGATE_EXPORTER_PID
