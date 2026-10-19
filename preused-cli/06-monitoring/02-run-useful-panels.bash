#!/usr/bin/env bash
q() { curl -sS --data-urlencode "query=$1" http://127.0.0.1:9090/api/v1/query; echo; }
q 'minio_cluster_capacity_usable_total_bytes'
q 'minio_cluster_capacity_usable_free_bytes'
q 'minio_cluster_capacity_usable_total_bytes - minio_cluster_capacity_usable_free_bytes'
q 'minio_cluster_usage_total_bytes'
q 'minio_cluster_nodes_online_total'
q 'minio_cluster_drive_online_total'
q 'sum(rate(minio_s3_requests_total[1m]))'
q 'sum(rate(minio_s3_requests_errors_total[1m]))'
q 'minio_cluster_health_erasure_set_healing_drives'
q 'minio_cluster_health_status'
