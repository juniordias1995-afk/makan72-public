#!/usr/bin/env bash
# =============================================================================
# test_integration.sh — Teste de Integração Completo
# =============================================================================
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
BOT_DIR="$MAKAN72_HOME/02-bots"
TESTS=0
PASS=0
FAIL=0

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Makan72 — Teste de Integração                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Test 1: team-bot.sh existe e é executável
TESTS=$((TESTS + 1))
if [[ -x "$BOT_DIR/team-bot.sh" ]]; then
    echo "✅ Test 1: team-bot.sh executável"
    PASS=$((PASS + 1))
else
    echo "❌ Test 1: team-bot.sh não executável"
    FAIL=$((FAIL + 1))
fi

# Test 2: team-bot.sh help funciona
TESTS=$((TESTS + 1))
if "$BOT_DIR/team-bot.sh" help &>/dev/null; then
    echo "✅ Test 2: team-bot.sh help funciona"
    PASS=$((PASS + 1))
else
    echo "❌ Test 2: team-bot.sh help falha"
    FAIL=$((FAIL + 1))
fi

# Test 3: team-bot.sh modules funciona
TESTS=$((TESTS + 1))
if "$BOT_DIR/team-bot.sh" modules &>/dev/null; then
    echo "✅ Test 3: team-bot.sh modules funciona"
    PASS=$((PASS + 1))
else
    echo "❌ Test 3: team-bot.sh modules falha"
    FAIL=$((FAIL + 1))
fi

# Test 4: team-bot.sh status funciona
TESTS=$((TESTS + 1))
if "$BOT_DIR/team-bot.sh" status &>/dev/null; then
    echo "✅ Test 4: team-bot.sh status funciona"
    PASS=$((PASS + 1))
else
    echo "❌ Test 4: team-bot.sh status falha"
    FAIL=$((FAIL + 1))
fi

# Test 5: Todos os módulos em lib/ são source-áveis
TESTS=$((TESTS + 1))
MODULES_OK=true
for module in "$BOT_DIR/lib"/*.sh; do
    if [[ -f "$module" ]]; then
        if ! source "$module" 2>/dev/null; then
            MODULES_OK=false
            echo "  ⚠️  Módulo falha: $(basename "$module")"
        fi
    fi
done

if [[ "$MODULES_OK" == "true" ]]; then
    echo "✅ Test 5: Todos módulos source-áveis"
    PASS=$((PASS + 1))
else
    echo "❌ Test 5: Alguns módulos falham"
    FAIL=$((FAIL + 1))
fi

# Test 6: mock_agents.json existe
TESTS=$((TESTS + 1))
if [[ -f "$BOT_DIR/tests/fixtures/mock_agents.json" ]]; then
    echo "✅ Test 6: mock_agents.json existe"
    PASS=$((PASS + 1))
else
    echo "❌ Test 6: mock_agents.json não existe"
    FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  RESULTADO: $PASS/$TESTS testes passaram"
if [[ $FAIL -eq 0 ]]; then
    echo "  STATUS: ✅ TODOS OS TESTES PASSARAM"
else
    echo "  STATUS: ❌ $FAIL testes falharam"
fi
echo "══════════════════════════════════════════════════════════"

exit $FAIL
