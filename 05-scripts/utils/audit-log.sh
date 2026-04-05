#!/usr/bin/env bash
# audit-log.sh — Registo de auditoria em JSONL
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
AUDIT_DIR="$MAKAN72_HOME/08-logs/audit"
AUDIT_FILE="$AUDIT_DIR/audit.jsonl"

mkdir -p "$AUDIT_DIR"

show_help() {
    cat << 'EOF'
Uso: audit-log.sh <COMANDO> [ARGUMENTOS]

Comandos:
  log <agent> <action> <target> <result>  Registar operacao
  show [N]                                Mostrar ultimas N entradas (default: 10)
  count                                   Contar total de entradas
  clear                                   Limpar audit log
  --help                                  Mostrar esta ajuda

Exemplos:
  audit-log.sh log QWEN modify gate.sh ok
  audit-log.sh show 20
  audit-log.sh count
EOF
}

audit_log() {
    local agent="$1"
    local action="$2"
    local target="$3"
    local result="${4:-ok}"
    
    local ts
    ts=$(portable_date_iso)
    
    # Escrever em JSONL
    echo "{\"ts\":\"$ts\",\"agent\":\"$agent\",\"action\":\"$action\",\"target\":\"$target\",\"result\":\"$result\"}" >> "$AUDIT_FILE"
}

case "${1:-}" in
    log)
        if [[ $# -lt 5 ]]; then
            echo "❌ Uso: audit-log.sh log <agent> <action> <target> <result>"
            exit 1
        fi
        audit_log "$2" "$3" "$4" "$5"
        echo "✅ Auditoria registada em $AUDIT_FILE"
        ;;
    
    show)
        n="${2:-10}"
        if [[ -f "$AUDIT_FILE" ]]; then
            echo "=== Últimas $n entradas de auditoria ==="
            tail -n "$n" "$AUDIT_FILE" | while IFS= read -r line; do
                echo "$line" | jq -r '"\(.ts) | \(.agent) | \(.action) | \(.target) | \(.result)"' 2>/dev/null || echo "$line"
            done
        else
            echo "⚠️  Audit log vazio"
        fi
        ;;
    
    count)
        if [[ -f "$AUDIT_FILE" ]]; then
            total=$(wc -l < "$AUDIT_FILE")
            echo "Total de entradas: $total"
        else
            echo "Total de entradas: 0"
        fi
        ;;
    
    clear)
        if [[ -f "$AUDIT_FILE" ]]; then
            rm -f "$AUDIT_FILE"
            echo "✅ Audit log limpo"
        else
            echo "⚠️  Audit log já está vazio"
        fi
        ;;
    
    --help|-h)
        show_help
        exit 0
        ;;
    
    "")
        echo "Uso: audit-log.sh <comando> [argumentos]"
        echo "Use --help para mais informacoes."
        exit 1
        ;;
    
    *)
        echo "❌ Comando desconhecido: $1"
        echo "Use --help para ver comandos disponíveis."
        exit 1
        ;;
esac
