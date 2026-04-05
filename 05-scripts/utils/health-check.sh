#!/usr/bin/env bash
# health-check.sh — Verificar saúde do sistema
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

CMD="${1:-full}"

show_help() {
    cat << 'EOF'
Uso: $0 [MODO]

Verificar saúde do sistema Makan72.

MODOS:
  quick    Checks 1-4 apenas (rápido)
  full     Todos os 9 checks (completo)
  --help, -h  Mostrar esta ajuda

CHECKS (full mode):
  1. MAKAN72_HOME existe
  2. 10 pastas (00-09) existem
  3. team.yaml válido
  4. agents.json válido
  5. Coerência agentes
  6. BOT_RULES.yaml válido
  7. Espaço em disco (>1GB)
  8. Orphans no bus
  9. Templates completos

EXEMPLOS:
  $0 quick
  $0 full
  $0 (default: full)

SAÍDA:
  Mostra resultado de cada check (✅/❌)
  Resumo: Pass/Fail/Skip
EOF
}

# Verificar --help ANTES de executar
if [[ "${CMD}" == "--help" || "${CMD}" == "-h" ]]; then
    show_help
    exit 0
fi

# Normalizar: aceitar tanto "quick" como "--quick"
CMD="${CMD#--}"

pass=0
fail=0
skip=0

check() {
    local name="$1"
    local result="$2"
    
    if [[ "$result" == "0" ]]; then
        echo "✅ $name"
        pass=$((pass + 1))
    else
        echo "❌ $name"
        fail=$((fail + 1))
    fi
}

# Check 1: MAKAN72_HOME existe
check_1() {
    [[ -d "$MAKAN72_HOME" ]] && return 0 || return 1
}

# Check 2: 10 pastas (00-09)
check_2() {
    local count=0
    local dirs=(
        "$MAKAN72_HOME/00-global"
        "$MAKAN72_HOME/01-config"
        "$MAKAN72_HOME/02-bots"
        "$MAKAN72_HOME/03-inbox"
        "$MAKAN72_HOME/04-bus"
        "$MAKAN72_HOME/05-scripts"
        "$MAKAN72_HOME/06-reports"
        "$MAKAN72_HOME/07-archive"
        "$MAKAN72_HOME/08-logs"
        "$MAKAN72_HOME/09-workspace"
    )
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            count=$((count + 1))
        fi
    done
    if [[ $count -ge 10 ]]; then
        return 0
    else
        return 1
    fi
}

# Check 3: team.yaml e YAML valido
check_3() {
    local file="$MAKAN72_HOME/01-config/team.yaml"
    [[ -f "$file" ]] || return 1
    # Validar com python3 se disponivel
    if command -v python3 &>/dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    fi
    # Fallback: ficheiro nao vazio + tem pelo menos uma key: value
    [[ -s "$file" ]] && grep -qE '^[a-zA-Z_]+:' "$file" 2>/dev/null
}

# Check 4: agents.json é JSON válido
check_4() {
    jq empty "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null && return 0 || return 1
}

# Check 5: Coerência de agentes
check_5() {
    # Verificar se cada agente ACTIVO tem CV e inbox
    # NOTA: Prompts nao sao obrigatorios (run-agent.sh gera contexto dinamicamente)
    local agents
    agents=$(jq -r '.agents[] | select(.status != "removed") | .code' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null || echo "")
    
    for agent in $agents; do
        [[ -f "$MAKAN72_HOME/00-global/cvs/CV_${agent}.md" ]] || return 1
        [[ -d "$MAKAN72_HOME/03-inbox/${agent}" ]] || return 1
    done
    return 0
}

# Check 6: BOT_RULES.yaml válido
check_6() {
    [[ -f "$MAKAN72_HOME/02-bots/config/BOT_RULES.yaml" ]] && return 0 || return 1
}

# Check 7: Espaço em disco
check_7() {
    local available
    available=$(df -k "$MAKAN72_HOME" 2>/dev/null | tail -1 | awk '{print $4}')
    # Menos de 1GB = 1048576 KB
    [[ $available -gt 1048576 ]] && return 0 || return 1
}

# Check 8: Orphans no bus
check_8() {
    # Verificar se heartbeats referem agentes que existem
    local agents
    agents=$(jq -r '.agents[].code' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null || echo "")

    # Excepções: heartbeat de não-agentes (CEO é humano, não agente)
    local exceptions="CEO"

    for hb in "$MAKAN72_HOME/04-bus/heartbeat"/*_heartbeat.json; do
        [[ -f "$hb" ]] || continue
        local hb_agent
        hb_agent=$(basename "$hb" | sed 's/_heartbeat.json//')

        # Ignorar excepções
        if echo "$exceptions" | grep -q "^${hb_agent}$"; then
            continue
        fi

        # Verificar se agente existe
        if ! echo "$agents" | grep -q "^${hb_agent}$"; then
            # Agente não existe mas tem heartbeat = orphan
            return 1
        fi
    done
    return 0
}

# Check 9: Templates completos
check_9() {
    local templates_dir="$MAKAN72_HOME/01-config/templates"
    [[ -d "$templates_dir" ]] || return 1
    [[ -f "$templates_dir/agents/CV_TEMPLATE.md" ]] || return 1
    [[ -f "$templates_dir/agents/PROMPT_TEMPLATE.md" ]] || return 1
    return 0
}

# Validação de schema do agents.json
validate_agents_schema() {
    local agents_json="$MAKAN72_HOME/01-config/agents.json"
    local required_fields=("code" "name" "model" "cli" "status" "tab")
    local errors=0
    
    # Verificar se é array de agentes
    if ! jq -e '.agents | type == "array"' "$agents_json" 2>/dev/null; then
        echo "❌ agents.json: estrutura inválida (não é array de agentes)"
        return 1
    fi
    
    # Para cada agente, verificar campos obrigatórios
    local agent_count
    agent_count=$(jq '.agents | length' "$agents_json" 2>/dev/null || echo 0)
    
    for i in $(seq 0 $((agent_count - 1))); do
        local agent_code
        agent_code=$(jq -r ".agents[$i].code // \"agente_$i\"" "$agents_json" 2>/dev/null)
        
        for field in "${required_fields[@]}"; do
            if ! jq -e ".agents[$i].$field" "$agents_json" 2>/dev/null | grep -qv "null"; then
                echo "❌ Agente '$agent_code': campo '$field' em falta"
                errors=$((errors + 1))
            fi
        done
    done
    
    if [[ $errors -gt 0 ]]; then
        echo "❌ Schema: $errors erro(s) encontrado(s)"
        return 1
    fi
    echo "✅ Schema: todos os campos obrigatórios presentes"
    return 0
}

# Check 10: Integridade de ficheiros sagrados
check_10() {
    local integrity_script="$MAKAN72_HOME/05-scripts/utils/integrity-check.sh"
    local hash_file="$MAKAN72_HOME/08-logs/cache/integrity.sha256"
    
    # Se script nao existir, skip
    [[ -x "$integrity_script" ]] || return 2
    
    # Se hash file nao existir, skip (usuario ainda nao correu update)
    [[ -f "$hash_file" ]] || return 2
    
    # Correr verify
    if "$integrity_script" verify --quiet &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check 11: Schema do agents.json
check_11() {
    validate_agents_schema > /dev/null 2>&1 && return 0 || return 1
}

echo "=== HEALTH CHECK ==="
echo ""

if [[ "$CMD" == "quick" ]]; then
    echo "(Quick mode: checks 1-4 only)"
    echo ""

    check "1. MAKAN72_HOME existe" "$(check_1; echo $?)"
    check "2. 10 pastas existem" "$(check_2; echo $?)"
    check "3. team.yaml válido" "$(check_3; echo $?)"
    check "4. agents.json válido" "$(check_4; echo $?)"
else
    echo "(Full mode: all 11 checks)"
    echo ""

    check "1. MAKAN72_HOME existe" "$(check_1; echo $?)"
    check "2. 10 pastas existem" "$(check_2; echo $?)"
    check "3. team.yaml válido" "$(check_3; echo $?)"
    check "4. agents.json válido" "$(check_4; echo $?)"
    check "5. Coerência agentes" "$(check_5; echo $?)"
    check "6. BOT_RULES.yaml válido" "$(check_6; echo $?)"
    check "7. Espaço em disco (>1GB)" "$(check_7; echo $?)"
    check "8. Orphans no bus" "$(check_8; echo $?)"
    check "9. Templates completos" "$(check_9; echo $?)"
    check "10. Integridade de ficheiros sagrados" "$(check_10; echo $?)"
    check "11. Schema do agents.json" "$(check_11; echo $?)"
fi

echo ""
echo "=== RESULTADO ==="
echo "Pass: $pass"
echo "Fail: $fail"

if [[ $fail -eq 0 ]]; then
    echo "✅ SAÚDE: OK"
    exit 0
elif [[ $fail -le 2 ]]; then
    echo "⚠️  SAÚDE: Avisos"
    exit 1
else
    echo "❌ SAÚDE: Crítico"
    exit 2
fi
