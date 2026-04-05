#!/usr/bin/env bash
# cleanup-bus.sh — Limpar bus expirado
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

echo "🧹 Limpando bus..."

# Limpar heartbeats antigos (>24h)
find "$MAKAN72_HOME/04-bus/heartbeat" -name "*.json" -mtime +1 -delete 2>/dev/null || true

# Limpar status antigos
find "$MAKAN72_HOME/04-bus/status" -name "*.json" -mtime +1 -delete 2>/dev/null || true

# Limpar handoffs lidos antigos (>48h)
find "$MAKAN72_HOME/04-bus/handoff" -name "*.json.read" -mtime +2 -delete 2>/dev/null || true

echo "✅ Bus limpo"
