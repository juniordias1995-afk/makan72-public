#!/usr/bin/env bash
# backup.sh — Criar backup completo
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
BACKUP_DIR="$MAKAN72_HOME/07-archive/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Carregar log de operacoes
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
fi

mkdir -p "$BACKUP_DIR"

echo "📦 Criando backup..."

BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.tar.gz"

# Criar backup (excluir backups anteriores, logs, cache e modelos grandes)
tar -czf "$BACKUP_FILE" \
    -C "$MAKAN72_HOME" \
    --exclude='07-archive/backups' \
    --exclude='08-logs/logs' \
    --exclude='08-logs/cache' \
    --exclude='10-tools/models/*.safetensors' \
    --exclude='10-tools/models/*.ckpt' \
    --exclude='10-tools/models/*.bin' \
    --exclude='10-tools/comfyui' \
    --exclude='.git' \
    . 2>/dev/null

# Validar backup
if [[ -f "$BACKUP_FILE" ]]; then
    echo "✅ Backup criado: $BACKUP_FILE"
    echo "   Tamanho: $(du -h "$BACKUP_FILE" | cut -f1)"

    # Verificar tamanho razoável (máx 50MB para Makan72 sem modelos)
    SIZE_BYTES=$(stat --format="%s" "$BACKUP_FILE" 2>/dev/null || stat -f "%z" "$BACKUP_FILE" 2>/dev/null || echo "0")
    MAX_SIZE=$((50 * 1024 * 1024))  # 50MB
    if [[ "$SIZE_BYTES" -gt "$MAX_SIZE" ]]; then
        echo "   ⚠️  AVISO: Backup anormalmente grande ($(du -h "$BACKUP_FILE" | cut -f1))!"
        echo "   Possível inclusão recursiva. Verificar excludes do tar."
    fi

    # Verificar integridade do tar.gz
    if tar -tzf "$BACKUP_FILE" &>/dev/null; then
        echo "   ✅ Integridade: OK"
    else
        echo "   ❌ Backup CORROMPIDO!"
        rm -f "$BACKUP_FILE"
        exit 1
    fi
else
    echo "❌ Backup falhou!"
    exit 1
fi

# Rotação — manter apenas os 3 backups mais recentes
echo "  Limpando backups antigos..."
BACKUP_COUNT=$(ls -t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)
if [[ "$BACKUP_COUNT" -gt 3 ]]; then
    REMOVED=$((BACKUP_COUNT - 3))
    ls -t "$BACKUP_DIR"/backup_*.tar.gz | tail -n +4 | xargs rm -f 2>/dev/null || true
    echo "  🗑️  Removidos $REMOVED backups antigos"
else
    echo "  ✅ Backups: $BACKUP_COUNT/3 (OK)"
fi

# Registar operacao
if type log_operation &>/dev/null; then
    log_operation "backup" "system" "OK" "file=$BACKUP_FILE,count=$BACKUP_COUNT"
fi
