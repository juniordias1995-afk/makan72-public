#!/usr/bin/env bash
# env-check.sh — Verificar e preparar ambiente
# Autor: QWEN (MC)
# Data: 2026-04-04

set -uo pipefail

INSTALL_MODE=false
QUIET_MODE=false
SUMMARY_MODE=false

show_help() {
    cat << 'EOF'
env-check.sh — Verificar ambiente antes de executar agentes

Uso: env-check.sh [OPÇÕES]

OPÇÕES:
  --install    Tentar instalar ferramentas em falta
  --quiet      Modo silencioso (só exit code, sem output)
  --summary    Mostrar apenas resumo (1 linha)
  --help       Mostrar esta ajuda

Verifica:
  - python3 / pip
  - node / npm
  - git
  - jq
  - shellcheck
  - ruff

Exit code:
  0 = Todas as ferramentas OK
  1 = Alguma ferramenta em falta
EOF
}

# Parse argumentos
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            show_help
            exit 0
            ;;
        --install)
            INSTALL_MODE=true
            ;;
        --quiet)
            QUIET_MODE=true
            ;;
        --summary)
            SUMMARY_MODE=true
            ;;
    esac
done

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ "$QUIET_MODE" != "true" && "$SUMMARY_MODE" != "true" ]]; then
    echo "=== ENV CHECK ==="
    echo ""
fi

# Lista de ferramentas a verificar
declare -A TOOLS=(
    ["python3"]="python3"
    ["pip"]="pip3"
    ["node"]="node"
    ["npm"]="npm"
    ["git"]="git"
    ["jq"]="jq"
    ["shellcheck"]="shellcheck"
    ["ruff"]="ruff"
)

MISSING=()
FOUND=0

for tool in "${!TOOLS[@]}"; do
    pkg="${TOOLS[$tool]}"
    if command -v "$tool" &>/dev/null; then
        version=$("$tool" --version 2>&1 | head -1 || echo "unknown")
        if [[ "$QUIET_MODE" != "true" && "$SUMMARY_MODE" != "true" ]]; then
            echo -e "${GREEN}✅${NC} $tool: $version"
        fi
        FOUND=$((FOUND + 1))
    else
        if [[ "$QUIET_MODE" != "true" && "$SUMMARY_MODE" != "true" ]]; then
            echo -e "${RED}❌${NC} $tool: NOT FOUND"
        fi
        MISSING+=("$tool:$pkg")
    fi
done

# Modo summary: output de 1 linha
if [[ "$SUMMARY_MODE" == "true" ]]; then
    echo "env: $FOUND/${#TOOLS[@]} OK, ${#MISSING[@]} em falta"
    exit $([[ ${#MISSING[@]} -eq 0 ]] && echo 0 || echo 1)
fi

if [[ "$QUIET_MODE" != "true" ]]; then
    echo ""
    echo "=== RESUMO ==="
    echo "Ferramentas encontradas: $FOUND/${#TOOLS[@]}"
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${YELLOW}⚠️  Em falta: ${#MISSING[@]}${NC}"
    fi

    if [[ "$INSTALL_MODE" == "true" ]]; then
        if [[ "$QUIET_MODE" != "true" ]]; then
            echo ""
            echo "A tentar instalar..."
        fi

        for item in "${MISSING[@]}"; do
            tool="${item%%:*}"
            pkg="${item##*:}"

            if [[ "$QUIET_MODE" != "true" ]]; then
                echo -n "  $tool: "
            fi
            case "$tool" in
                python3|pip)
                    apt-get install -y "$pkg" 2>/dev/null && echo "OK" || echo "FALHOU"
                    ;;
                node|npm)
                    # Node usually comes with nvm or asdf
                    [[ "$QUIET_MODE" != "true" ]] && echo "Instale manualmente (nvm/asdf)"
                    ;;
                git|jq|shellcheck)
                    apt-get install -y "$pkg" 2>/dev/null && echo "OK" || echo "FALHOU"
                    ;;
                ruff)
                    pip install ruff 2>/dev/null && echo "OK" || echo "FALHOU"
                    ;;
                *)
                    [[ "$QUIET_MODE" != "true" ]] && echo "Não suportado"
                    ;;
            esac
        done
    fi

    exit 1
else
    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${GREEN}✅ Ambiente OK${NC}"
    fi
    exit 0
fi