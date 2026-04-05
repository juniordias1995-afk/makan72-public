#!/usr/bin/env bash
# run-tests.sh — Executar todos os testes
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
TESTS_DIR="$MAKAN72_HOME/02-bots/tests"

cd "$TESTS_DIR"

TOTAL_TESTS=0
TOTAL_PASS=0
TOTAL_FAIL=0

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     MAKAN72 — Testes Automatizados                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

for test in test_*.sh; do
    if [[ -x "$test" ]]; then
        echo "=== $test ==="
        if bash "$test"; then
            TOTAL_PASS=$((TOTAL_PASS + 1))
        else
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        echo ""
    fi
done

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ RESULTADO FINAL                                         ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║ Total: %2d | Pass: %2d | Fail: %2d                            ║\n" "$TOTAL_TESTS" "$TOTAL_PASS" "$TOTAL_FAIL"
echo "╚══════════════════════════════════════════════════════════╝"

if [[ $TOTAL_FAIL -eq 0 ]]; then
    echo "✅ TODOS OS TESTES PASSARAM"
    exit 0
else
    echo "❌ ALGUNS TESTES FALHARAM"
    exit 1
fi
