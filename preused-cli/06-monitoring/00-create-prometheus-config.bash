#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../mcli.bash"
mcli admin prometheus generate lab > monitoring/prometheus.generated.yml
printf '\nrule_files:\n  - /etc/prometheus/alerts.yml\n' >> monitoring/prometheus.generated.yml