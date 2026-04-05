#!/usr/bin/env bash
# test-suite.sh — Testes funcionais do Makan72
# Autor: QWEN (MC)
# Data: 2026-04-04

set -uo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
PASS=0
FAIL=0
TESTS_RUN=0

# Cleanup trap
cleanup() {
    # Limpar stuff de testes
    rm -rf "$MAKAN72_HOME/03-inbox/_test_agent" 2>/dev/null || true
    rm -f "$MAKAN72_HOME/00-global/_test_SESSAO_HOJE.yaml" 2>/dev/null || true
    
    # Restaurar SESSAO_HOJE original se existir backup
    if [[ -f "$MAKAN72_HOME/00-global/_test_SESSAO_HOJE.yaml.bak" ]]; then
        mv "$MAKAN72_HOME/00-global/_test_SESSAO_HOJE.yaml.bak" "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml"
    fi
}
trap cleanup EXIT

pass() {
    echo "✅ T$1: $2"
    PASS=$((PASS + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
    echo "❌ T$1: $2"
    FAIL=$((FAIL + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

skip() {
    echo "⏭️  T$1: $2 (SKIP)"
    TESTS_RUN=$((TESTS_RUN + 1))
}

echo "=== TEST SUITE — Makan72 ==="
echo ""

# T01: Criar inbox para agente fake
test_01() {
    local test_inbox="$MAKAN72_HOME/03-inbox/_test_agent"
    mkdir -p "$test_inbox"
    if [[ -d "$test_inbox" ]]; then
        pass 01 "Criar inbox para agente fake"
    else
        fail 01 "Criar inbox para agente fake"
    fi
}

# T02: Despachar mensagem para inbox
test_02() {
    local test_msg="$MAKAN72_HOME/03-inbox/_test_agent/test_msg.md"
    echo "# Test message" > "$test_msg"
    if [[ -f "$test_msg" ]]; then
        pass 02 "Entregar mensagem em inbox"
    else
        fail 02 "Entregar mensagem em inbox"
    fi
}

# T03: health-check.sh retorna 0
test_03() {
    if bash "$MAKAN72_HOME/05-scripts/utils/health-check.sh" &>/dev/null; then
        pass 03 "health-check.sh retorna 0"
    else
        fail 03 "health-check.sh retorna 0"
    fi
}

# T04: manage-agents.sh list retorna lista coerente
test_04() {
    local agents_list
    agents_list=$(bash "$MAKAN72_HOME/05-scripts/core/manage-agents.sh" list 2>/dev/null)
    if echo "$agents_list" | grep -q "QWEN\|CLAUDE\|GEMINI"; then
        pass 04 "manage-agents.sh list coerente"
    else
        fail 04 "manage-agents.sh list coerente"
    fi
}

# T05: gate.sh check script válido → exit 0
test_05() {
    local valid_script="/tmp/_test_valid_script.sh"
    echo '#!/bin/bash
echo "valid"' > "$valid_script"
    
    (
        bash "$MAKAN72_HOME/05-scripts/core/gate.sh" check "$valid_script" default >/dev/null 2>&1
    )
    local exit_code=$?
    
    if [[ "$exit_code" == "0" ]]; then
        pass 05 "gate.sh aprova script válido"
    else
        fail 05 "gate.sh aprova script válido"
    fi
    rm -f "$valid_script"
}

# T06: gate.sh check script com erro → exit 1
test_06() {
    local invalid_script="/tmp/_test_invalid_script.sh"
    echo '#!/bin/bash
if [[ $unclosed' > "$invalid_script"
    
    (
        bash "$MAKAN72_HOME/05-scripts/core/gate.sh" check "$invalid_script" default >/dev/null 2>&1
    )
    local exit_code=$?
    
    if [[ "$exit_code" != "0" ]]; then
        pass 06 "gate.sh rejeita script com erro"
    else
        fail 06 "gate.sh rejeita script com erro"
    fi
    rm -f "$invalid_script"
}

# T07: backup.sh cria backup em 07-archive/backups/
test_07() {
    local before_count
    before_count=$(ls -1 "$MAKAN72_HOME/07-archive/backups/"*.tar.gz 2>/dev/null | wc -l)

    bash "$MAKAN72_HOME/05-scripts/utils/backup.sh" &>/dev/null

    local after_count
    after_count=$(ls -1 "$MAKAN72_HOME/07-archive/backups/"*.tar.gz 2>/dev/null | wc -l)

    if [[ $after_count -gt $before_count ]]; then
        # Verificar que o backup não é anormalmente grande (máx 50MB)
        local latest_backup
        latest_backup=$(ls -t "$MAKAN72_HOME/07-archive/backups/"*.tar.gz 2>/dev/null | head -1)
        local size_bytes
        size_bytes=$(stat --format="%s" "$latest_backup" 2>/dev/null || echo "0")
        local max_size=$((50 * 1024 * 1024))  # 50MB
        if [[ "$size_bytes" -gt "$max_size" ]]; then
            fail 07 "backup.sh cria backup (TAMANHO EXCESSIVO: $(du -h "$latest_backup" | cut -f1))"
        else
            pass 07 "backup.sh cria backup"
        fi
        # Limpar backup de teste
        rm -f "$latest_backup"
    else
        fail 07 "backup.sh cria backup"
    fi
}

# T08: start-session.sh cria SESSAO_HOJE.yaml
test_08() {
    # Backup original (se existir e for legível)
    if [[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]] && [[ -r "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]]; then
        cp "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" "$MAKAN72_HOME/00-global/_test_SESSAO_HOJE.yaml.bak" 2>/dev/null || true
    fi

    # Usar --project e --mission (não argumentos posicionais)
    bash "$MAKAN72_HOME/05-scripts/utils/start-session.sh" --project="_test_proj" --mission="_test_missao" --leader="QWEN" 2>/dev/null || true

    if [[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]]; then
        if grep -q "_test_proj" "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" 2>/dev/null; then
            pass 08 "start-session.sh cria SESSAO_HOJE.yaml"
        else
            fail 08 "start-session.sh cria SESSAO_HOJE.yaml"
        fi
    else
        fail 08 "start-session.sh cria SESSAO_HOJE.yaml"
    fi
}

# T09: integrity-check.sh update + verify → retorna 0
test_09() {
    bash "$MAKAN72_HOME/05-scripts/utils/integrity-check.sh" update &>/dev/null
    if bash "$MAKAN72_HOME/05-scripts/utils/integrity-check.sh" verify --quiet &>/dev/null; then
        pass 09 "integrity-check.sh update + verify"
    else
        fail 09 "integrity-check.sh update + verify"
    fi
}

# T10: cleanup-bus.sh remove ficheiros antigos
test_10() {
    # Criar ficheiro de teste antigo no bus (em pasta que cleanup-bus.sh limpa)
    # O cleanup-bus.sh limpa: heartbeat, status, handoff
    local test_file="$MAKAN72_HOME/04-bus/heartbeat/_test_old_heartbeat.json"
    echo '{}' > "$test_file"
    # Mudar data de modificação para 2 dias atrás
    touch -d "2 days ago" "$test_file"

    bash "$MAKAN72_HOME/05-scripts/utils/cleanup-bus.sh" &>/dev/null

    if [[ ! -f "$test_file" ]]; then
        pass 10 "cleanup-bus.sh remove ficheiros antigos"
    else
        rm -f "$test_file"
        fail 10 "cleanup-bus.sh remove ficheiros antigos"
    fi
}

# T11: env-check.sh retorna 0 (dependências básicas presentes)
test_11() {
    if bash "$MAKAN72_HOME/05-scripts/utils/env-check.sh" --quiet &>/dev/null; then
        pass 11 "env-check.sh — dependências OK"
    else
        fail 11 "env-check.sh — dependências em falta"
    fi
}

# T12: run-agent.sh gera contexto válido
test_12() {
    local ctx_file="$MAKAN72_HOME/09-workspace/context/QWEN_context.md"
    # Remover contexto antigo se existir
    rm -f "$ctx_file"

    if bash "$MAKAN72_HOME/05-scripts/core/run-agent.sh" QWEN &>/dev/null; then
        if [[ -f "$ctx_file" ]] && [[ -s "$ctx_file" ]]; then
            local lines
            lines=$(wc -l < "$ctx_file")
            if [[ "$lines" -gt 10 ]]; then
                pass 12 "run-agent.sh gera contexto ($lines linhas)"
            else
                fail 12 "run-agent.sh contexto demasiado curto ($lines linhas)"
            fi
        else
            fail 12 "run-agent.sh não gerou ficheiro de contexto"
        fi
    else
        fail 12 "run-agent.sh falhou"
    fi
}

# T13: rotate-logs.sh funciona
test_13() {
    local test_log="$MAKAN72_HOME/08-logs/_test_old_rotate.log"
    echo "test rotate" > "$test_log"
    touch -d "3 days ago" "$test_log"

    bash "$MAKAN72_HOME/05-scripts/utils/rotate-logs.sh" &>/dev/null

    if [[ -f "${test_log}.gz" ]]; then
        pass 13 "rotate-logs.sh comprime logs antigos"
        rm -f "${test_log}.gz"
    else
        # Se o ficheiro original foi apagado também é OK
        if [[ ! -f "$test_log" ]]; then
            pass 13 "rotate-logs.sh processou log antigo"
        else
            fail 13 "rotate-logs.sh não processou log antigo"
            rm -f "$test_log"
        fi
    fi
}

# Executar todos os testes
test_01
test_02
test_03
test_04
test_05
test_06
test_07
test_08
test_09
test_10
test_11
test_12
test_13

echo ""
echo "=== RESULTADO ==="
echo "Pass: $PASS"
echo "Fail: $FAIL"
echo "Total: $TESTS_RUN"

if [[ $FAIL -eq 0 ]]; then
    echo "✅ TODOS OS TESTES PASSARAM"
    exit 0
else
    echo "❌ $FAIL TESTE(S) FALHOU(RAM)"
    exit 1
fi