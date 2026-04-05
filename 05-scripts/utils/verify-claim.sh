#!/usr/bin/env bash
# verify-claim.sh — Verificar afirmações concretas (anti-alucinação)
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
Uso: verify-claim.sh <TIPO> <ALVO> [EXTRA]

Verificar afirmações concretas com evidência.

TIPOS:
  file-exists <PATH>          Verificar se ficheiro existe
  dir-exists <PATH>           Verificar se directório existe e não está vazio
  syntax-ok <PATH>            Verificar se script passa bash -n
  agent-exists <CODE>         Verificar se agente está registado
  count-files <PATH> <NUM>    Verificar contagem de ficheiros
  json-valid <PATH>           Verificar se JSON é válido
  yaml-valid <PATH>           Verificar se YAML é válido (python3)

SAÍDA:
  ✅ CONFIRMADO: <evidência>
  ❌ FALSO: <razão>

EXIT CODE:
  0 = Afirmação confirmada
  1 = Afirmação falsa
EOF
}

log_result() {
    local result="$1"
    local message="$2"
    
    if [[ "$result" == "OK" ]]; then
        echo -e "${GREEN}✅ CONFIRMADO:${NC} $message"
        exit 0
    else
        echo -e "${RED}❌ FALSO:${NC} $message"
        exit 1
    fi
}

# Carregar log se disponível
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
fi

TYPE="${1:-}"
TARGET="${2:-}"
EXTRA="${3:-}"

case "$TYPE" in
    file-exists)
        if [[ -f "$TARGET" ]]; then
            lines=$(wc -l < "$TARGET")
            bytes=$(wc -c < "$TARGET")
            log_result "OK" "$TARGET existe ($lines linhas, $bytes bytes)"
        else
            log_result "FAIL" "$TARGET NÃO existe"
        fi
        ;;
    
    dir-exists)
        if [[ -d "$TARGET" ]]; then
            count=$(find "$TARGET" -type f 2>/dev/null | wc -l)
            if [[ "$count" -gt 0 ]]; then
                log_result "OK" "$TARGET existe ($count ficheiros)"
            else
                log_result "FAIL" "$TARGET existe mas está VAZIO"
            fi
        else
            log_result "FAIL" "$TARGET NÃO existe"
        fi
        ;;
    
    syntax-ok)
        if [[ -f "$TARGET" ]]; then
            if bash -n "$TARGET" 2>/dev/null; then
                log_result "OK" "$TARGET passa bash -n"
            else
                error=$(bash -n "$TARGET" 2>&1 | head -1)
                log_result "FAIL" "$TARGET falha bash -n: $error"
            fi
        else
            log_result "FAIL" "$TARGET NÃO existe"
        fi
        ;;
    
    agent-exists)
        agents_file="$MAKAN72_HOME/01-config/agents.json"
        if [[ -f "$agents_file" ]]; then
            if jq -e ".agents[] | select(.code==\"$TARGET\")" "$agents_file" &>/dev/null; then
                model=$(jq -r ".agents[] | select(.code==\"$TARGET\") | .model" "$agents_file")
                status=$(jq -r ".agents[] | select(.code==\"$TARGET\") | .status" "$agents_file")
                log_result "OK" "$TARGET registado (model: $model, status: $status)"
            else
                log_result "FAIL" "$TARGET não encontrado em agents.json"
            fi
        else
            log_result "FAIL" "agents.json não existe"
        fi
        ;;
    
    count-files)
        if [[ -d "$TARGET" ]]; then
            actual=$(find "$TARGET" -type f 2>/dev/null | wc -l)
            expected="$EXTRA"
            if [[ "$actual" -eq "$expected" ]]; then
                log_result "OK" "$TARGET tem $actual ficheiros (esperado: $expected)"
            else
                diff=$((actual - expected))
                if [[ "$diff" -gt 0 ]]; then
                    log_result "FAIL" "$TARGET tem $actual ficheiros (esperado: $expected, sobram $diff)"
                else
                    log_result "FAIL" "$TARGET tem $actual ficheiros (esperado: $expected, faltam $((-diff)))"
                fi
            fi
        else
            log_result "FAIL" "$TARGET NÃO existe"
        fi
        ;;
    
    json-valid)
        if [[ -f "$TARGET" ]]; then
            if jq empty "$TARGET" 2>/dev/null; then
                log_result "OK" "$TARGET é JSON válido"
            else
                error=$(jq empty "$TARGET" 2>&1 | head -1)
                log_result "FAIL" "$TARGET NÃO é JSON válido: $error"
            fi
        else
            log_result "FAIL" "$TARGET NÃO existe"
        fi
        ;;
    
    yaml-valid)
        if [[ -f "$TARGET" ]]; then
            if command -v python3 &>/dev/null; then
                if python3 -c "import yaml; yaml.safe_load(open('$TARGET'))" 2>/dev/null; then
                    log_result "OK" "$TARGET é YAML válido"
                else
                    log_result "FAIL" "$TARGET NÃO é YAML válido"
                fi
            else
                # Fallback: heurística
                if grep -qE '^[a-zA-Z_]+:' "$TARGET" 2>/dev/null; then
                    log_result "OK" "$TARGET parece YAML válido (heurística)"
                else
                    log_result "FAIL" "$TARGET NÃO parece YAML"
                fi
            fi
        else
            log_result "FAIL" "$TARGET NÃO existe"
        fi
        ;;
    
    --help|-h)
        show_help
        exit 0
        ;;
    
    "")
        echo "Uso: verify-claim.sh <TIPO> <ALVO> [EXTRA]"
        echo "Exemplos:"
        echo "  verify-claim.sh file-exists /path/to/file.sh"
        echo "  verify-claim.sh agent-exists CLAUDE"
        echo "  verify-claim.sh syntax-ok /path/to/script.sh"
        echo ""
        echo "Use --help para mais informações."
        exit 1
        ;;
    
    *)
        echo "❌ Tipo desconhecido: $TYPE"
        echo "Use --help para ver tipos disponíveis."
        exit 1
        ;;
esac
