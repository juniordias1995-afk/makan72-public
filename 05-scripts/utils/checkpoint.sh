#!/usr/bin/env bash
# checkpoint.sh — Time-travel snapshots
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
CHECKPOINT_DIR="$MAKAN72_HOME/08-logs/cache/checkpoints"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$CHECKPOINT_DIR"

create_checkpoint() {
    local desc="${1:-auto}"
    local safe_desc=$(echo "$desc" | tr -cd '[:alnum:]_-')
    local cp_name="CP_${TIMESTAMP}_${safe_desc}.tar.gz"
    
    echo "📦 Criando checkpoint: $cp_name..."
    
    tar -czf "$CHECKPOINT_DIR/$cp_name" \
        -C "$MAKAN72_HOME" \
        09-workspace/ \
        03-inbox/ \
        2>/dev/null
    
    echo "✅ Checkpoint criado"
    
    # Limpar checkpoints antigos (manter últimos 10)
    ls -t "$CHECKPOINT_DIR"/CP_*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
}

restore_checkpoint() {
    local cp_id="$1"
    local cp_path="$CHECKPOINT_DIR/$cp_id"
    
    if [[ ! -f "$cp_path" ]]; then
        echo "❌ Checkpoint não encontrado: $cp_id"
        exit 1
    fi
    
    echo "⏪ Restaurando: $cp_id..."
    tar -xzf "$cp_path" -C "$MAKAN72_HOME"
    echo "✅ Restaurado"
}

list_checkpoints() {
    echo "📋 Checkpoints (últimos 10):"
    ls -lht "$CHECKPOINT_DIR"/CP_*.tar.gz 2>/dev/null | head -10 || echo "  (nenhum)"
}

case "${1:-help}" in
    create) shift; create_checkpoint "$*" ;;
    restore) restore_checkpoint "${2:-}" ;;
    list) list_checkpoints ;;
    *) echo "Uso: checkpoint.sh [create <desc>|restore <id>|list]" ;;
esac
