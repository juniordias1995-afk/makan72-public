#!/usr/bin/env bash
# setup-hooks.sh — Instalar Git Hooks do Makan72
# Uso: bash ~/.Makan72/05-scripts/utils/setup-hooks.sh
# Executar após: git clone ou fresh install

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
HOOKS_SRC="$MAKAN72_HOME/05-scripts/utils/hooks"
HOOKS_DST="$MAKAN72_HOME/.git/hooks"

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🔧 Makan72 — Instalar Git Hooks${NC}"
echo ""

if ! git -C "$MAKAN72_HOME" rev-parse --git-dir &>/dev/null 2>&1; then
    echo -e "${RED}❌ Não é um repositório git: $MAKAN72_HOME${NC}"
    exit 1
fi

if [[ ! -d "$HOOKS_SRC" ]]; then
    echo -e "${RED}❌ Pasta de hooks não encontrada: $HOOKS_SRC${NC}"
    exit 1
fi

if [[ -f "$HOOKS_SRC/commit-msg" ]]; then
    cp "$HOOKS_SRC/commit-msg" "$HOOKS_DST/commit-msg"
    chmod +x "$HOOKS_DST/commit-msg"
    echo -e "  ${GREEN}✅ commit-msg instalado${NC} → valida Conventional Commits"
fi

echo ""
echo -e "${GREEN}✅ Hooks instalados!${NC}"
echo "  💡 Usa 'makan72 commit' para commits interactivos guiados."
echo ""
