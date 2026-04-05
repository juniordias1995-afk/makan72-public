#!/usr/bin/env bash
# test_notify.sh — Teste do módulo notify
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
modulo="notify"
source "$MAKAN72_HOME/02-bots/lib/notify.sh"

TESTS=0
PASS=0
FAIL=0

echo "Testing notify..."

# Test 1: function exists
TESTS=$((TESTS + 1))
if type -t ${modulo}_run &>/dev/null || type -t ${modulo}_status &>/dev/null || type -t ${modulo}_check &>/dev/null; then
    echo "✅ Test 1: ${modulo}_* functions exist"
    PASS=$((PASS + 1))
else
    echo "❌ Test 1: ${modulo}_* functions missing"
    FAIL=$((FAIL + 1))
fi

# Test 2: status returns output
TESTS=$((TESTS + 1))
if ${modulo}_status &>/dev/null; then
    echo "✅ Test 2: ${modulo}_status returns output"
    PASS=$((PASS + 1))
else
    echo "❌ Test 2: ${modulo}_status fails"
    FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "Result: $PASS/$TESTS passed"
exit $FAIL
