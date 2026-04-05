#!/usr/bin/env bash
# log-operation.sh — Registar operações em JSON (caixa negra)
# Autor: QWEN (implementação V3)
# Data: 2026-03-05

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
LOG_FILE="$MAKAN72_HOME/08-logs/audit/operations.jsonl"

log_operation() {
    local op="$1"
    local user="${2:-CEO}"
    local result="${3:-OK}"
    local details="${4:-}"
    
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "{\"timestamp\":\"$(portable_date_iso)\",\"op\":\"$op\",\"user\":\"$user\",\"result\":\"$result\",\"details\":\"$details\"}" >> "$LOG_FILE"
}

# Se chamado directamente (não sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Uso: $0 <op> [user] [result] [details]"
        exit 1
    fi
    log_operation "$@"
    echo "✅ Operação registada em $LOG_FILE"
fi
