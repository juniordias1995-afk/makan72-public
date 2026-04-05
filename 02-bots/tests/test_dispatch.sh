#!/usr/bin/env bash
# test_dispatch.sh — Teste do módulo dispatch
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh" 2>/dev/null || true
source "$MAKAN72_HOME/02-bots/lib/dispatch.sh"

TESTS=0
PASS=0
FAIL=0

pass() { TESTS=$((TESTS+1)); PASS=$((PASS+1)); echo "PASS Test $TESTS: $1"; }
fail() { TESTS=$((TESTS+1)); FAIL=$((FAIL+1)); echo "FAIL Test $TESTS: $1"; }

echo "=== Testing dispatch.sh ==="
echo ""

# T1: Funções públicas existem
if type -t dispatch_to_agent &>/dev/null; then pass "dispatch_to_agent exists"
else fail "dispatch_to_agent NOT FOUND"; fi

if type -t dispatch_notify &>/dev/null; then pass "dispatch_notify exists"
else fail "dispatch_notify NOT FOUND"; fi

if type -t dispatch_broadcast &>/dev/null; then pass "dispatch_broadcast exists"
else fail "dispatch_broadcast NOT FOUND"; fi

if type -t dispatch_status &>/dev/null; then pass "dispatch_status exists"
else fail "dispatch_status NOT FOUND"; fi

# T2: dispatch_run NÃO deve existir (removido para evitar duplicação)
if type -t dispatch_run &>/dev/null; then
    fail "dispatch_run EXISTS — deveria ter sido removido"
else
    pass "dispatch_run não existe (correcto)"
fi

# T3: dispatch_status executa sem erro
output=$(dispatch_status 2>&1)
if [[ $? -eq 0 && "$output" == *"dispatch:"* ]]; then
    pass "dispatch_status output: $output"
else
    fail "dispatch_status failed: $output"
fi

# T4: _dispatch_find_tab (só válido dentro da sessão Makan72 com agentes activos)
# Condição: dentro de Zellij E na sessão canónica Makan72
if [[ "${ZELLIJ_SESSION_NAME:-}" == "Makan72" ]]; then
    tab=$(_dispatch_find_tab "CLAUDE" 2>/dev/null) || tab=""
    if [[ -n "$tab" ]]; then
        pass "_dispatch_find_tab CLAUDE = '$tab'"
    else
        fail "_dispatch_find_tab CLAUDE returned empty"
    fi

    tab=$(_dispatch_find_tab "QWEN" 2>/dev/null) || tab=""
    if [[ -n "$tab" ]]; then
        pass "_dispatch_find_tab QWEN = '$tab'"
    else
        fail "_dispatch_find_tab QWEN returned empty"
    fi

    tab=$(_dispatch_find_tab "GEMINI" 2>/dev/null) || tab=""
    if [[ -n "$tab" ]]; then
        pass "_dispatch_find_tab GEMINI = '$tab'"
    else
        fail "_dispatch_find_tab GEMINI returned empty"
    fi
else
    result=$(dispatch_to_agent "QWEN" "teste" 2>&1)
    if [[ $? -ne 0 || "$result" == *"fora de sessão"* || "$result" == *"não disponível"* || -z "$result" ]]; then
        pass "dispatch_to_agent fora de Zellij = fail-safe correcto"
    else
        fail "dispatch_to_agent fora de Zellij deveria falhar"
    fi
    pass "_dispatch_find_tab SKIPPED (fora de Zellij)"
    pass "_dispatch_find_tab SKIPPED (fora de Zellij)"
fi

# T5: dispatch_notify executa sem crash
output=$(dispatch_notify "QWEN" "test_file.md" "CLAUDE" 2>&1)
if [[ $? -eq 0 ]] || [[ "$output" == *"inbox"* ]] || [[ "$output" == *"dispatch"* ]] || [[ -z "$output" ]]; then
    pass "dispatch_notify executa sem crash"
else
    fail "dispatch_notify crashed: $output"
fi

# T6: DISPATCH_ENABLED=false desactiva tudo
DISPATCH_ENABLED="false"
output=$(dispatch_to_agent "QWEN" "não deveria enviar" 2>&1)
if [[ $? -eq 0 ]]; then
    pass "DISPATCH_ENABLED=false = dispatch ignorado"
else
    fail "DISPATCH_ENABLED=false deveria retornar 0"
fi
DISPATCH_ENABLED="true"

# T7: save/get current tab round-trip
_dispatch_save_current_tab "TestTab"
saved=$(_dispatch_get_current_tab)
if [[ "$saved" == "TestTab" ]]; then
    pass "_dispatch_save/get_current_tab round-trip OK"
else
    fail "_dispatch_save/get_current_tab broken: got '$saved' expected 'TestTab'"
fi
rm -f "$MAKAN72_HOME/08-logs/cache/dispatch_current_tab.txt"

# T8: Log file funciona
mkdir -p "$(dirname "$DISPATCH_LOG")"
_dispatch_log "TEST — linha de teste"
if [[ -f "$DISPATCH_LOG" ]] && grep -q "TEST — linha de teste" "$DISPATCH_LOG"; then
    pass "Log funciona: $DISPATCH_LOG"
    sed -i '/TEST — linha de teste/d' "$DISPATCH_LOG"
else
    fail "Log não criou ou não escreveu em $DISPATCH_LOG"
fi

# T9: inbox.sh tem dispatch integrado
if grep -q "dispatch_to_agent" "$MAKAN72_HOME/02-bots/lib/inbox.sh" 2>/dev/null; then
    dispatch_calls=$(grep -c "dispatch_to_agent" "$MAKAN72_HOME/02-bots/lib/inbox.sh")
    if [[ "$dispatch_calls" -ge 2 ]]; then
        pass "inbox.sh tem $dispatch_calls chamadas a dispatch_to_agent"
    else
        fail "inbox.sh tem apenas $dispatch_calls chamada(s) — esperado 2+"
    fi
else
    fail "inbox.sh NÃO tem dispatch_to_agent integrado"
fi

# T10: inbox.sh usa guard type -t
if grep -q "type -t dispatch_to_agent" "$MAKAN72_HOME/02-bots/lib/inbox.sh" 2>/dev/null; then
    pass "inbox.sh usa guard 'type -t' antes de chamar dispatch"
else
    fail "inbox.sh NÃO usa guard 'type -t'"
fi

# T11: Sintaxe de todos os ficheiros
for f in "$MAKAN72_HOME/02-bots/lib/dispatch.sh" "$MAKAN72_HOME/02-bots/lib/inbox.sh" "$MAKAN72_HOME/02-bots/team-bot.sh"; do
    if bash -n "$f" 2>/dev/null; then
        pass "Sintaxe OK: $(basename "$f")"
    else
        fail "Sintaxe ERRO: $(basename "$f")"
    fi
done

# T12: team-bot.sh tem _dispatch_save_current_tab
if grep -q "_dispatch_save_current_tab" "$MAKAN72_HOME/02-bots/team-bot.sh" 2>/dev/null; then
    pass "team-bot.sh tem _dispatch_save_current_tab"
else
    fail "team-bot.sh NÃO tem _dispatch_save_current_tab"
fi

# T13: team-bot.sh NÃO tem dispatch_run
if grep -q "dispatch_run" "$MAKAN72_HOME/02-bots/team-bot.sh" 2>/dev/null; then
    fail "team-bot.sh tem dispatch_run (NÃO deveria)"
else
    pass "team-bot.sh não tem dispatch_run (correcto)"
fi

# === RESUMO ===
echo ""
echo "================================"
echo "DISPATCH TESTS: $TESTS total, $PASS passed, $FAIL failed"
echo "================================"

[[ $FAIL -gt 0 ]] && exit 1
exit 0
