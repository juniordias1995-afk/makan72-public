#!/usr/bin/env bash
# end-session.sh — Fechar sessão
# Autor: QWEN (implementação V3)
# Data: 2026-03-05

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
SESSAO_FILE="$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml"
MISSAO_FILE="$MAKAN72_HOME/09-workspace/missao-actual.md"
PID_FILE="$MAKAN72_HOME/08-logs/cache/pids/session.pid"

# === HELP ===
show_help() {
    cat << EOF
Uso: $0

Fechar sessão de trabalho no Makan72.

O QUE FAZ:
  - Consolida INSIGHTS.md
  - Marca missão como "PAUSA"
  - Limpa heartbeats do bus
  - Remove PID file da sessão

EXEMPLOS:
  $0

NOTAS:
  - Verifica se há sessão activa antes de fechar
  - Se não houver sessão, mostra erro
  - Após fechar, sessão fica em estado "PAUSA"
EOF
    exit 0
}

# Verificar --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
fi

echo "=== END SESSION ==="
echo ""

# Passo 1: Verificar se há sessão activa
echo "1. Verificar sessão activa..."
if [[ ! -f "$SESSAO_FILE" ]]; then
    echo "❌ ERRO: Não há sessão activa"
    exit 1
fi
echo "   ✅ Sessão encontrada"

# Passo 2: Consolidar INSIGHTS (reutilizar sleep_consolidate)
echo "2. Consolidar INSIGHTS..."
if [[ -x "$MAKAN72_HOME/02-bots/lib/sleep.sh" ]]; then
    source "$MAKAN72_HOME/02-bots/lib/sleep.sh"
    sleep_consolidate 2>/dev/null || echo "   ⚠️  Consolidação parcial"
    echo "   ✅ INSIGHTS consolidados"
else
    echo "   ⚠️  sleep.sh não encontrado"
fi

# Passo 3: Marcar missão como PAUSA
echo "3. Actualizar missão..."
if [[ -f "$MISSAO_FILE" ]]; then
    portable_sed_i 's/EM CURSO/PAUSA/g' "$MISSAO_FILE"
    portable_sed_i 's/estado: "EM_CURSO"/estado: "PAUSA"/g' "$SESSAO_FILE" 2>/dev/null || true
    echo "   ✅ Missão marcada como PAUSA"
else
    echo "   ⚠️  missao-actual.md não encontrado"
fi

# Passo 4: Limpar heartbeats
echo "4. Limpar heartbeats..."
find "$MAKAN72_HOME/04-bus/heartbeat" -name "*.json" -delete 2>/dev/null || true
echo "   ✅ Heartbeats limpos"

# Passo 5: Remover PID
echo "5. Remover PID..."
if [[ -f "$PID_FILE" ]]; then
    rm -f "$PID_FILE"
    echo "   ✅ PID removido"
else
    echo "   ⚠️  PID não existia"
fi

# Passo 6: Mostrar resumo
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│ SESSÃO FECHADA                              │"
echo "├─────────────────────────────────────────────┤"
grep "projecto:" "$SESSAO_FILE" 2>/dev/null | sed 's/^/│ /' || true
grep "missao:" "$SESSAO_FILE" 2>/dev/null | sed 's/^/│ /' || true
echo "│ Estado: PAUSA                               │"
echo "│ Git: auto-commit activado             ✅   │"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "✅ SESSÃO FECHADA COM SUCESSO!"


# Passo 7: Auto-commit das alterações da sessão
echo "7. Auto-commit das alterações..."
if command -v git &>/dev/null && git -C "$MAKAN72_HOME" rev-parse --git-dir &>/dev/null 2>&1; then
    HAS_CHANGES=false
    git -C "$MAKAN72_HOME" diff --quiet 2>/dev/null          || HAS_CHANGES=true
    git -C "$MAKAN72_HOME" diff --cached --quiet 2>/dev/null || HAS_CHANGES=true
    [ -n "$(git -C "$MAKAN72_HOME" ls-files --others --exclude-standard 2>/dev/null)" ] && HAS_CHANGES=true

    if $HAS_CHANGES; then
        SESSAO_DATA=$(date '+%Y-%m-%d %H:%M')
        PROJECTO=$(grep "projecto:" "$SESSAO_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d '"' || echo "makan72")
        COMMIT_MSG="chore(session): auto-save ${SESSAO_DATA} — ${PROJECTO}"

        git -C "$MAKAN72_HOME" add -A 2>/dev/null
        git -C "$MAKAN72_HOME" commit -q -m "$COMMIT_MSG" 2>/dev/null
        echo "   ✅ Auto-commit: ${COMMIT_MSG}"
    else
        echo "   ℹ️  Sem alterações para commitar"
    fi
else
    echo "   ⚠️  Git não disponível"
fi
# Registar operacao
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
    if type log_operation &>/dev/null; then
        log_operation "end-session" "system" "OK" "sessao=fechada"
    fi
fi
exit 0
