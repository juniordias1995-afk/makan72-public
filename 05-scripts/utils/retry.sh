#!/usr/bin/env bash
# retry.sh — Executar comando com retry automático ao agente em caso de falha
# Autor: QWEN (MC)
# Data: 2026-04-04

set -uo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
MAX_RETRIES=3
COUNTER_FILE="/tmp/retry_counter_$$.tmp"

show_help() {
    cat << 'EOF'
retry.sh — Executar comando, criar tarefa no inbox do agente se falhar

Uso: retry.sh <agent_code> <comando...>

Exemplo:
  retry.sh QWEN python meu_script.py
  retry.sh CLAUDE bash script.sh --arg1 valor

Se o comando falhar (exit != 0):
  1. Formata o erro como contexto markdown
  2. Cria ficheiro no inbox do agente com: tarefa original + stderr + instrução

Máximo de retries: 3 (controlado por ficheiro temporário)
EOF
}

# Verificar argumentos
if [[ $# -lt 2 ]]; then
    show_help
    exit 1
fi

# Parse argumentos (segundo CLAUDE: $1 = agent_code, ${@:2} = comando)
AGENT_CODE="$1"
shift
COMMAND=("$@")

echo "=== RETRY.SH ==="
echo "Agente: $AGENT_CODE"
echo "Comando: ${COMMAND[*]}"
echo ""

# Contador de retries
if [[ -f "$COUNTER_FILE" ]]; then
    RETRY_COUNT=$(cat "$COUNTER_FILE")
else
    RETRY_COUNT=0
fi

if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
    echo "❌ Máximo de retries ($MAX_RETRIES) atingido"
    echo "Aborting..."
    rm -f "$COUNTER_FILE"
    exit 1
fi

# Executar comando
echo "A executar..."
"${COMMAND[@]}" 2>&1
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo "✅ Comando executado com sucesso"
    rm -f "$COUNTER_FILE"
    exit 0
else
    echo ""
    echo "❌ Comando falhou (exit code: $EXIT_CODE)"
    
    # Incrementar contador
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "$RETRY_COUNT" > "$COUNTER_FILE"
    
    # Obter output de erro
    STDERR_OUTPUT=$("${COMMAND[@]}" 2>&1 || true)
    
    # Criar tarefa no inbox do agente
    INBOX_PATH=""
    if [[ -d "$MAKAN72_HOME/03-inbox/$AGENT_CODE" ]]; then
        INBOX_PATH="$MAKAN72_HOME/03-inbox/$AGENT_CODE"
    elif [[ -d "$HOME/.team/inbox/$AGENT_CODE" ]]; then
        INBOX_PATH="$HOME/.team/inbox/$AGENT_CODE"
    else
        echo "❌ Inbox do agente não encontrado: $AGENT_CODE"
        exit 1
    fi
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    TASK_FILE="$INBOX_PATH/RETRY_ERROR_${TIMESTAMP}.md"
    
    cat > "$TASK_FILE" << EOF
# Retry — Erro ao Executar Comando

**De:** retry.sh
**Para:** $AGENT_CODE
**Data:** $(date +%Y-%m-%d)
**Retry:** $RETRY_COUNT/$MAX_RETRIES

---

## Comando Original

\`\`\`bash
${COMMAND[*]}
\`\`\`

## Erro

\`\`\`
$STDERR_OUTPUT
\`\`\`

## Instrução

Corrige o erro acima e executa o comando novamente.

---

*retry.sh — Makan72*
EOF

    echo ""
    echo "📬 Tarefa criada no inbox do agente: $AGENT_CODE"
    echo "   Ficheiro: $(basename "$TASK_FILE")"
    
    exit $EXIT_CODE
fi