#!/usr/bin/env bash
# rotate-logs.sh — Rotação de logs do Makan72
# Mantém últimos 7 dias de logs, comprime logs > 1 dia, apaga > 7 dias
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
LOGS_DIR="$MAKAN72_HOME/08-logs"

# 1. Comprimir logs com mais de 1 dia (que não estejam já comprimidos)
find "$LOGS_DIR" -name "*.log" -mtime +1 -exec gzip -q {} \; 2>/dev/null || true

# 2. Apagar logs comprimidos com mais de 7 dias
find "$LOGS_DIR" -name "*.log.gz" -mtime +7 -delete 2>/dev/null || true

# 3. Apagar logs de start-agent que tenham mais de 3 dias
find "$LOGS_DIR" -name "start-agent-*.log" -mtime +3 -delete 2>/dev/null || true

# 4. Reportar
TOTAL=$(find "$LOGS_DIR" -type f 2>/dev/null | wc -l)
echo "✅ Logs rotacionados. Ficheiros actuais: $TOTAL"
