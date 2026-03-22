#!/usr/bin/env bash

set -uo pipefail

mode="${1:-metrics}"

host_name() {
    hostname -s 2>/dev/null || hostname 2>/dev/null || printf '%s' '?'
}

metric_string() {
    local cpu ram gpu now out

    now="$(date +%H:%M)"

    if [[ -f /proc/stat ]]; then
        cpu="$(vmstat 1 2 2>/dev/null | awk 'END{printf "%.0f", 100-$15}')"
        ram="$(free -h 2>/dev/null | awk 'NR==2{gsub(/i/,""); printf "%s/%s", $3, $2}')"
    else
        cpu="$(top -l1 -n0 2>/dev/null | awk '/CPU usage/{gsub(/%|,/,""); printf "%.0f", 100-$NF}')"
        ram="$(top -l1 -n0 2>/dev/null | awk '/PhysMem/{print $2" used"}')"
    fi

    out="CPU ${cpu:-?}% | RAM ${ram:-?}"

    if command -v nvidia-smi &>/dev/null; then
        gpu="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk '{sum+=$1; n++} END{if(n) printf "%.0f", sum/n}')"
        [[ -n "${gpu:-}" ]] && out="${out} | GPU ${gpu}%"
    fi

    printf '%s | %s' "$out" "$now"
}

case "$mode" in
    --host|host)
        host_name
        ;;
    --metrics|metrics|"")
        metric_string
        ;;
    *)
        printf 'usage: %s [--host|--metrics]\n' "${0##*/}" >&2
        exit 1
        ;;
esac
