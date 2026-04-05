#!/usr/bin/env bash
# verify-migration.sh — Verificar migração
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

echo "🔍 Verificando migração..."

# Contar ficheiros migrados
echo ""
echo "Ficheiros em 00-global/:"
ls -la "$MAKAN72_HOME/00-global/" | wc -l

echo ""
echo "Ficheiros em 01-config/:"
ls -la "$MAKAN72_HOME/01-config/" | wc -l

echo ""
echo "Ficheiros em 03-inbox/:"
find "$MAKAN72_HOME/03-inbox" -type f 2>/dev/null | wc -l

# Health check
echo ""
if [[ -x "$MAKAN72_HOME/05-scripts/utils/health-check.sh" ]]; then
    "$MAKAN72_HOME/05-scripts/utils/health-check.sh" --quick
fi

echo ""
echo "✅ Verificação completa"
