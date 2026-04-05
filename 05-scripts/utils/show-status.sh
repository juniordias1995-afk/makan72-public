#!/usr/bin/env bash
# show-status.sh — Mostrar status do sistema
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

# Source functions para sessões
source "$MAKAN72_HOME/05-scripts/core/makan72-functions.sh" 2>/dev/null || true

echo "📊 MAKAN72 STATUS — $(date +%Y-%m-%d)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"

# Agentes
echo ""
echo "AGENTES:"
if [[ -f "$MAKAN72_HOME/01-config/agents.json" ]]; then
    active=$(jq '[.agents[] | select(.status=="active")] | length' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null || echo "0")
    echo "  Activos: $active"
fi

# Tarefas
echo ""
echo "TAREFAS:"
pending=$(find "$MAKAN72_HOME/03-inbox" -path "*/pending/*.md" 2>/dev/null | wc -l)
echo "  Pendentes: $pending"

# Sistema
echo ""
echo "SISTEMA:"
echo "  VERSION: $(cat "$MAKAN72_HOME/VERSION" 2>/dev/null || echo "unknown")"
echo "  Saúde: $(if [[ -x "$MAKAN72_HOME/05-scripts/utils/health-check.sh" ]]; then echo "OK"; else echo "unknown"; fi)"

# Sessões activas
echo ""
echo "SESSÕES:"
local_sessions=$(m72_list_sessions 2>/dev/null || true)
if [[ -n "$local_sessions" ]]; then
    echo "$local_sessions" | while IFS='|' read -r slot name cli project started; do
        echo "  🟢 Slot $slot: $name ($cli) — $project [desde $started]"
    done
else
    echo "  Nenhuma sessão activa"
fi

# Detalhe visual das sessões (agents em sessão)
SLOTS_FILE="$MAKAN72_HOME/04-bus/active_slots.json"
if [[ -f "$SLOTS_FILE" ]]; then
    slot_count=$(jq '.slots | length' "$SLOTS_FILE" 2>/dev/null || echo "0")
    if [[ "$slot_count" -gt 0 ]]; then
        echo ""
        echo "AGENTES EM SESSÃO:"
        jq -r '.slots[] | "  🟢 \(.name) (\(.cli)) — \(.project)"' "$SLOTS_FILE" 2>/dev/null
    fi
fi
