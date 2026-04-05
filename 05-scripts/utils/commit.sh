#!/usr/bin/env bash
# commit.sh — Conventional Commit Helper para Makan72
# Uso: makan72 commit  OU  bash ~/.Makan72/05-scripts/utils/commit.sh

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Tipos
TYPE_KEYS=("feat" "fix" "refactor" "docs" "style" "test" "chore" "perf" "revert")
TYPE_DESCS=(
    "feat     → Nova funcionalidade"
    "fix      → Correcção de bug"
    "refactor → Refactoring (sem bug/feature)"
    "docs     → Apenas documentação"
    "style    → Formatação, sem mudança lógica"
    "test     → Adição/actualização de testes"
    "chore    → Manutenção, configuração"
    "perf     → Melhoria de performance"
    "revert   → Reverter commit anterior"
)

# Scopes — 9 pastas + extras
SCOPE_KEYS=("00-global" "01-config" "02-bots" "03-inbox" "04-bus" "05-scripts" "06-reports" "07-archive" "08-logs" "09-workspace" "system" "agent" "session" "setup")
SCOPE_DESCS=(
    "00-global    → Regras, memória, framework"
    "01-config    → Configurações, agentes, templates"
    "02-bots      → Team-bot e módulos"
    "03-inbox     → Sistema de inbox"
    "04-bus       → Comunicação inter-agentes"
    "05-scripts   → Scripts core e utils"
    "06-reports   → Relatórios e documentação"
    "07-archive   → Arquivo histórico"
    "08-logs      → Logs e auditoria"
    "09-workspace → Workspace activo"
    "system       → Sistema global (múltiplas áreas)"
    "agent        → Gestão de agentes"
    "session      → Gestão de sessão"
    "setup        → Instalação e configuração inicial"
)

# Verificar repositório git
if ! git -C "$MAKAN72_HOME" rev-parse --git-dir &>/dev/null 2>&1; then
    echo -e "${RED}❌ Não é um repositório git: $MAKAN72_HOME${NC}"
    exit 1
fi

# Verificar se há alterações
if git -C "$MAKAN72_HOME" diff --quiet 2>/dev/null && \
   git -C "$MAKAN72_HOME" diff --cached --quiet 2>/dev/null && \
   [ -z "$(git -C "$MAKAN72_HOME" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    echo ""
    echo -e "  ${YELLOW}ℹ️  Sem alterações para commitar.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🚀  Makan72 — Conventional Commit Helper       ${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Mostrar alterações pendentes
echo -e "${CYAN}📁 Alterações pendentes:${NC}"
git -C "$MAKAN72_HOME" status --short | head -20
echo ""

# PASSO 1: Tipo
echo -e "${CYAN}📌 Tipo de commit:${NC}"
for i in "${!TYPE_DESCS[@]}"; do
    printf "  ${YELLOW}[%2d]${NC} %s\n" "$((i+1))" "${TYPE_DESCS[$i]}"
done
echo ""
while true; do
    read -rp "  Escolha (1-${#TYPE_KEYS[@]}): " type_idx
    if [[ "$type_idx" =~ ^[0-9]+$ ]] && (( type_idx >= 1 && type_idx <= ${#TYPE_KEYS[@]} )); then
        TYPE="${TYPE_KEYS[$((type_idx-1))]}"
        break
    fi
    echo -e "  ${RED}Inválido.${NC}"
done

# PASSO 2: Scope
echo ""
echo -e "${CYAN}🔧 Scope (área afectada):${NC}"
for i in "${!SCOPE_DESCS[@]}"; do
    printf "  ${YELLOW}[%2d]${NC} %s\n" "$((i+1))" "${SCOPE_DESCS[$i]}"
done
printf "  ${YELLOW}[ 0]${NC} sem scope\n"
echo ""
while true; do
    read -rp "  Escolha (0-${#SCOPE_KEYS[@]}): " scope_idx
    if [[ "$scope_idx" == "0" ]]; then
        SCOPE=""
        break
    elif [[ "$scope_idx" =~ ^[0-9]+$ ]] && (( scope_idx >= 1 && scope_idx <= ${#SCOPE_KEYS[@]} )); then
        SCOPE="(${SCOPE_KEYS[$((scope_idx-1))]})"
        break
    fi
    echo -e "  ${RED}Inválido.${NC}"
done

# PASSO 3: Breaking change
echo ""
read -rp "  💥 Breaking change? (y/N): " IS_BREAKING
[[ "${IS_BREAKING:-}" =~ ^[Yy]$ ]] && BANG="!" || BANG=""

# PASSO 4: Descrição
echo ""
echo -e "${CYAN}📝 Descrição curta (máx 72 chars):${NC}"
while true; do
    read -rp "  > " DESC
    if [[ -z "$DESC" ]]; then
        echo -e "  ${RED}Descrição obrigatória.${NC}"
    elif [[ ${#DESC} -gt 72 ]]; then
        echo -e "  ${RED}Demasiado longa (${#DESC} chars). Máx 72.${NC}"
    else
        break
    fi
done

# PASSO 5: Body (opcional)
echo ""
echo -e "${CYAN}📄 Corpo — detalhe extra (Enter para saltar):${NC}"
read -rp "  > " BODY

# PASSO 6: Footer (opcional)
echo ""
echo -e "${CYAN}🔗 Rodapé — ex: 'Closes #42' (Enter para saltar):${NC}"
read -rp "  > " FOOTER

# Montar mensagem
HEADER="${TYPE}${SCOPE}${BANG}: ${DESC}"
FULL_MSG="$HEADER"
[[ -n "${BODY:-}" ]] && FULL_MSG="${FULL_MSG}

${BODY}"
[[ -n "${FOOTER:-}" ]] && FULL_MSG="${FULL_MSG}

${FOOTER}"

# Preview
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  📋 Preview:${NC}"
echo ""
echo -e "  ${GREEN}${FULL_MSG}${NC}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -rp "  ✅ Confirmar commit? (Y/n): " CONFIRM
[[ "${CONFIRM:-}" =~ ^[Nn]$ ]] && echo "  Cancelado." && exit 0

cd "$MAKAN72_HOME"
git add -A
git commit -m "$FULL_MSG

Co-authored-by: Qwen-Coder <qwen-coder@alibabacloud.com>"

echo ""
echo -e "  ${GREEN}✅ Commit criado!${NC}"
git log --oneline -3
echo ""
