#!/usr/bin/env bash
# validar.sh — Validar estrutura do Makan72
# Autor: QWEN (implementação V3)
# Data: 2026-03-05

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

PASS=0
FAIL=0

check_dir() {
    local name="$1"
    if [[ -d "$1" ]]; then
        echo "✅ $name"
        PASS=$((PASS + 1))
    else
        echo "❌ $name"
        FAIL=$((FAIL + 1))
    fi
}

check_file() {
    local name="$1"
    if [[ -f "$1" ]]; then
        echo "✅ $name"
        PASS=$((PASS + 1))
    else
        echo "❌ $name"
        FAIL=$((FAIL + 1))
    fi
}

check_exec() {
    local name="$1"
    if [[ -x "$1" ]]; then
        echo "✅ $name (executável)"
        PASS=$((PASS + 1))
    else
        echo "❌ $name (não executável)"
        FAIL=$((FAIL + 1))
    fi
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     MAKAN72 — Validação de Estrutura                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

echo "=== PASTAS (00-09) ==="
for dir in 00-global 01-config 02-bots 03-inbox 04-bus 05-scripts 06-reports 07-archive 08-logs 09-workspace; do
    check_dir "$MAKAN72_HOME/$dir"
done

echo ""
echo "=== FICHEIROS CRÍTICOS ==="
check_file "$MAKAN72_HOME/00-global/VERDADE.md"
check_file "$MAKAN72_HOME/00-global/VACINAS.md"
check_file "$MAKAN72_HOME/01-config/agents.json"
check_file "$MAKAN72_HOME/01-config/team.yaml"
check_file "$MAKAN72_HOME/01-config/GUARDRAILS.yaml"

echo ""
echo "=== SCRIPTS CORE ==="
check_exec "$MAKAN72_HOME/05-scripts/core/manage-agents.sh"
check_exec "$MAKAN72_HOME/05-scripts/core/gate.sh"
check_exec "$MAKAN72_HOME/05-scripts/core/run-agent.sh"
check_exec "$MAKAN72_HOME/05-scripts/core/shield.sh"

echo ""
echo "=== SCRIPTS UTILS ==="
check_exec "$MAKAN72_HOME/05-scripts/utils/start-session.sh"
check_exec "$MAKAN72_HOME/05-scripts/utils/end-session.sh"
check_exec "$MAKAN72_HOME/05-scripts/utils/health-check.sh"
check_exec "$MAKAN72_HOME/05-scripts/utils/backup.sh"

echo ""
echo "=== RESULTADO ==="
echo "Pass: $PASS | Fail: $FAIL"
if [[ $FAIL -eq 0 ]]; then
    echo "✅ ESTRUTURA OK"
    exit 0
else
    echo "❌ ESTRUTURA COM PROBLEMAS"
    exit 1
fi
