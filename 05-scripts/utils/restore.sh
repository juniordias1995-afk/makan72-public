#!/usr/bin/env bash
# restore.sh — Restaurar backup
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
BACKUP_DIR="$MAKAN72_HOME/07-archive/backups"

echo "♻️  Restaurar backup"
echo ""

# Listar backups
echo "Backups disponíveis:"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "  (nenhum)"
echo ""

if [[ -n "${1:-}" ]]; then
    restore_file="$BACKUP_DIR/$1"
    if [[ -f "$restore_file" ]]; then
        echo "⚠️  A restaurar $1..."

        # 1. Backup de segurança ANTES de restaurar
        safety_backup="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
        echo "   [1/3] Backup de segurança: $(basename "$safety_backup")"
        tar -czf "$safety_backup" -C "$HOME" .Makan72/ 2>/dev/null || {
            echo "❌ ERRO: Não consegui criar backup de segurança. Abortando."
            exit 1
        }

        # 2. Testar integridade do arquivo ANTES de restaurar
        echo "   [2/3] Verificar integridade do backup..."
        if ! tar -tzf "$restore_file" &>/dev/null; then
            echo "❌ ERRO: Backup corrompido ou inválido: $1"
            exit 1
        fi

        # 3. Restaurar (apenas ficheiros de config e docs — NÃO sobrescrever scripts core)
        echo "   [3/3] Restaurar..."
        tar -xzf "$restore_file" -C "$MAKAN72_HOME/" 2>/dev/null && {
            echo "✅ Restore completo de: $1"
            echo "   (backup de segurança em: $(basename "$safety_backup"))"
        } || {
            echo "❌ ERRO no restore. Sistema pode estar inconsistente."
            echo "   Restaurar manualmente com: tar -xzf $safety_backup -C $HOME/"
            exit 1
        }
    else
        echo "❌ Backup não encontrado: $1"
        echo ""
        echo "Backups disponíveis:"
        ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "  (nenhum)"
        exit 1
    fi
else
    echo "Uso: restore.sh <backup_file>"
    echo "Exemplo: restore.sh backup_20260303_120000.tar.gz"
fi
