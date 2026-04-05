#!/usr/bin/env bash
# run-tests.sh — Suite de testes integrada
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
LOG_DIR="$MAKAN72_HOME/08-logs/test-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/tests_${TIMESTAMP}.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass=0
fail=0
skip=0

mkdir -p "$LOG_DIR"

log() {
    echo "$*" | tee -a "$LOG_FILE"
}

log_test() {
    local result="$1"
    local name="$2"
    local details="${3:-}"
    
    if [[ "$result" == "OK" ]]; then
        log "  ✅ $name $details"
        pass=$((pass + 1))
    elif [[ "$result" == "SKIP" ]]; then
        log "  ⚠️  $name (SKIP) $details"
        skip=$((skip + 1))
    else
        log "  ❌ $name $details"
        fail=$((fail + 1))
    fi
}

show_help() {
    cat << 'EOF'
Uso: run-tests.sh [--quick|--full]

Suite de testes integrada do Makan72.

MODOS:
  --quick   Apenas syntax check (bash -n) em todos os scripts
  --full    Syntax + health-check + integrity + gate (default)
  --help    Mostrar esta ajuda

SAÍDA:
  Relatório em 08-logs/test-results/tests_YYYYMMDD_HHMM.log
  Exit: 0 se tudo OK, 1 se algum falhou
EOF
}

# Carregar log se disponível
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
fi

MODE="${1:-full}"

case "$MODE" in
    --help|-h)
        show_help
        exit 0
        ;;
    --quick|quick)
        MODE="quick"
        ;;
    --full|full|"")
        MODE="full"
        ;;
    *)
        echo "❌ Modo desconhecido: $MODE"
        echo "Use --help para ver modos disponíveis."
        exit 1
        ;;
esac

log "╔══════════════════════════════════════════════════════════╗"
log "║     MAKAN72 — TESTES AUTOMATIZADOS                      ║"
log "╚══════════════════════════════════════════════════════════╝"
log ""
log "Modo: $MODE"
log "Data: $(portable_date_iso)"
log "Log:  $LOG_FILE"
log ""

# =============================================================================
# TESTE 1: Syntax check em todos os scripts
# =============================================================================
log "=== TESTE 1: Syntax Check (bash -n) ==="

while IFS= read -r -d '' script; do
    if bash -n "$script" 2>/dev/null; then
        log_test "OK" "$(basename "$script")"
    else
        error=$(bash -n "$script" 2>&1 | head -1)
        log_test "FAIL" "$(basename "$script")" "$error"
    fi
done < <(find "$MAKAN72_HOME/05-scripts" -name "*.sh" -print0 2>/dev/null)

# =============================================================================
# TESTE 2: agents.json é JSON válido
# =============================================================================
log ""
log "=== TESTE 2: agents.json ==="

if jq empty "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null; then
    count=$(jq '.agents | length' "$MAKAN72_HOME/01-config/agents.json")
    log_test "OK" "agents.json válido" "($count agentes)"
else
    log_test "FAIL" "agents.json NÃO é JSON válido"
fi

# =============================================================================
# TESTE 3: SESSAO_HOJE.yaml é YAML válido
# =============================================================================
log ""
log "=== TESTE 3: SESSAO_HOJE.yaml ==="

if [[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]]; then
    if command -v python3 &>/dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml'))" 2>/dev/null; then
            log_test "OK" "SESSAO_HOJE.yaml é YAML válido"
        else
            log_test "FAIL" "SESSAO_HOJE.yaml NÃO é YAML válido"
        fi
    else
        # Fallback: heurística
        if grep -qE '^[a-zA-Z_]+:' "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" 2>/dev/null; then
            log_test "OK" "SESSAO_HOJE.yaml parece YAML válido (heurística)"
        else
            log_test "FAIL" "SESSAO_HOJE.yaml NÃO parece YAML"
        fi
    fi
else
    log_test "SKIP" "SESSAO_HOJE.yaml" "não encontrado"
fi

# =============================================================================
# TESTE 4-6: Apenas em modo --full
# =============================================================================
if [[ "$MODE" == "full" ]]; then
    # -------------------------------------------------------------------------
    # TESTE 4: health-check.sh
    # -------------------------------------------------------------------------
    log ""
    log "=== TESTE 4: health-check.sh (quick mode) ==="
    
    if [[ -x "$MAKAN72_HOME/05-scripts/utils/health-check.sh" ]]; then
        if "$MAKAN72_HOME/05-scripts/utils/health-check.sh" quick &>/dev/null; then
            log_test "OK" "health-check.sh quick PASS"
        else
            log_test "FAIL" "health-check.sh quick FAIL"
        fi
    else
        log_test "SKIP" "health-check.sh" "não encontrado"
    fi
    
    # -------------------------------------------------------------------------
    # TESTE 5: integrity-check.sh verify
    # -------------------------------------------------------------------------
    log ""
    log "=== TESTE 5: integrity-check.sh verify ==="
    
    if [[ -x "$MAKAN72_HOME/05-scripts/utils/integrity-check.sh" ]]; then
        if "$MAKAN72_HOME/05-scripts/utils/integrity-check.sh" verify &>/dev/null; then
            log_test "OK" "integrity-check.sh verify PASS"
        else
            log_test "FAIL" "integrity-check.sh verify FAIL"
        fi
    else
        log_test "SKIP" "integrity-check.sh" "não encontrado"
    fi
    
    # -------------------------------------------------------------------------
    # TESTE 6: gate.sh check em scripts core
    # -------------------------------------------------------------------------
    log ""
    log "=== TESTE 6: gate.sh check (scripts core) ==="
    
    if [[ -x "$MAKAN72_HOME/05-scripts/core/gate.sh" ]]; then
        for script in "$MAKAN72_HOME/05-scripts/core"/*.sh; do
            [[ -f "$script" ]] || continue
            base=$(basename "$script")
            if "$MAKAN72_HOME/05-scripts/core/gate.sh" check "$script" &>/dev/null; then
                log_test "OK" "gate.sh check $base"
            else
                log_test "FAIL" "gate.sh check $base"
            fi
        done
    else
        log_test "SKIP" "gate.sh" "não encontrado"
    fi
fi

# =============================================================================
# RESULTADO FINAL
# =============================================================================
log ""
log "╔══════════════════════════════════════════════════════════╗"
log "║                 RESULTADO FINAL                          ║"
log "╠══════════════════════════════════════════════════════════╣"
log "║  Pass:  $pass"
log "║  Fail:  $fail"
log "║  Skip:  $skip"
log "╚══════════════════════════════════════════════════════════╝"
log ""

if [[ $fail -eq 0 ]]; then
    log "✅ TESTES: OK"
    result="OK"
    exit_code=0
else
    log "❌ TESTES: $fail falha(s)"
    result="FAIL"
    exit_code=1
fi

# Registar operacao
if type log_operation &>/dev/null; then
    log_operation "run-tests" "system" "$result" "pass=$pass,fail=$fail,skip=$skip,mode=$MODE"
fi

exit $exit_code
