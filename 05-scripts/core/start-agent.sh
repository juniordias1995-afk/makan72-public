#!/usr/bin/env bash
# start-agent.sh — Iniciar agente com contexto (terminal limpo)
# Uso: start-agent.sh <AGENT_CODE>
# Resultado: mostra ✓ checks no terminal e abre agente com contexto completo

set -uo pipefail
# NOTA: sem -e para que falha do run-agent.sh não mate o script

export MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
AGENT_CODE="${1:-}"

if [[ -z "$AGENT_CODE" ]]; then
    echo "Uso: start-agent.sh <AGENT_CODE>"
    exit 1
fi

# Converter para MAIÚSCULAS (aceitar "claude", "Claude", "CLAUDE")
AGENT_CODE="${AGENT_CODE^^}"

# === LER CONFIG DO AGENTE A PARTIR DE agents.json ===
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"

if [[ ! -f "$AGENTS_FILE" ]]; then
    echo "❌ ERRO: agents.json não encontrado: $AGENTS_FILE"
    exit 1
fi

CLI=$(jq -r ".agents[] | select(.code==\"$AGENT_CODE\") | .cli // empty" "$AGENTS_FILE" 2>/dev/null || true)
if [[ -z "$CLI" ]]; then
    VALID=$(jq -r '.agents[] | select(.status=="active") | .code' "$AGENTS_FILE" 2>/dev/null | tr '\n' ' ')
    echo "❌ ERRO: Agente '$AGENT_CODE' não encontrado em agents.json"
    echo "   Agentes activos: ${VALID:-nenhum}"
    exit 1
fi

CONTEXT_FLAG=$(jq -r ".agents[] | select(.code==\"$AGENT_CODE\") | .context_flag // \"--prompt-interactive\"" "$AGENTS_FILE")
CLI_FLAGS=$(jq -r ".agents[] | select(.code==\"$AGENT_CODE\") | .cli_flags // \"\"" "$AGENTS_FILE")

if ! command -v "$CLI" &>/dev/null; then
    echo "❌ ERRO: CLI '$CLI' não encontrado no PATH"
    exit 1
fi

# === PRÉ-VERIFICAÇÃO DE AMBIENTE ===
if [[ -f "$MAKAN72_HOME/05-scripts/utils/env-check.sh" ]]; then
    if ! bash "$MAKAN72_HOME/05-scripts/utils/env-check.sh" --quiet 2>/dev/null; then
        echo "⚠️  AVISO: Algumas dependências em falta. Correr: env-check.sh --install"
    fi
fi

# === VERIFICAR AGENTE JÁ ACTIVO ===
SLOTS_FILE="$MAKAN72_HOME/04-bus/active_slots.json"
if [[ -f "$SLOTS_FILE" ]]; then
    EXISTING_PID=$(jq -r --arg code "$AGENT_CODE" '.slots[] | select(.name==$code) | .pid' "$SLOTS_FILE" 2>/dev/null || echo "")
    if [[ -n "$EXISTING_PID" ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
        echo "⚠️  AVISO: $AGENT_CODE já está activo (PID $EXISTING_PID)"
        echo "   Continuar mesmo assim? (Ctrl+C para cancelar, Enter para continuar)"
        read -r -t 10 || true
    fi
fi

# === GERAR CONTEXTO (silenciosamente — output vai para log) ===
LOG_FILE="$MAKAN72_HOME/08-logs/start-agent-${AGENT_CODE}.log"
mkdir -p "$MAKAN72_HOME/08-logs"

if ! bash "$MAKAN72_HOME/05-scripts/core/run-agent.sh" "$AGENT_CODE" > "$LOG_FILE" 2>&1; then
    echo "❌ ERRO: Falha ao gerar contexto para $AGENT_CODE"
    echo "   Ver log: $LOG_FILE"
    exit 1
fi

# === LER MÉTRICAS DO CONTEXTO GERADO ===
CONTEXT_FILE="$MAKAN72_HOME/09-workspace/context/${AGENT_CODE}_context.md"

if [[ ! -f "$CONTEXT_FILE" ]]; then
    echo "❌ ERRO: Ficheiro de contexto não encontrado: $CONTEXT_FILE"
    echo "   Ver log: $LOG_FILE"
    exec "$CLI"
fi

CONTEXT_LINES=$(wc -l < "$CONTEXT_FILE")
CONTEXT_BYTES=$(wc -c < "$CONTEXT_FILE")

# === LER MÉTRICAS DOS COMPONENTES INDIVIDUAIS ===
SESSAO_LINES=0
CV_LINES=0
VERDADE_LINES=0
VACINAS_LINES=0

[[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]] && \
    SESSAO_LINES=$(wc -l < "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml")

[[ -f "$MAKAN72_HOME/00-global/cvs/CV_${AGENT_CODE}.md" ]] && \
    CV_LINES=$(wc -l < "$MAKAN72_HOME/00-global/cvs/CV_${AGENT_CODE}.md")

[[ -f "$MAKAN72_HOME/00-global/VERDADE.md" ]] && \
    VERDADE_LINES=$(wc -l < "$MAKAN72_HOME/00-global/VERDADE.md")

[[ -f "$MAKAN72_HOME/00-global/VACINAS.md" ]] && \
    VACINAS_LINES=$(wc -l < "$MAKAN72_HOME/00-global/VACINAS.md")

# Ler projecto activo da sessão (remover aspas se existirem)
PROJECTO=""
if [[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]]; then
    PROJECTO=$(grep "projecto:" "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" 2>/dev/null \
        | head -1 | awk '{print $2}' | tr -d '"' || true)
fi
PROJECTO="${PROJECTO:-(sem projecto)}"

# === DISPLAY — TERMINAL LIMPO (✓ CHECKS) ===
echo ""
echo "═══════════════════════════════════════════════════"
echo " 🚀 Makan72 — ${AGENT_CODE} (Chat Interactivo)"
echo "═══════════════════════════════════════════════════"
echo ""
echo "✓ Projecto activo: ${PROJECTO}"
echo "✓ SESSAO_HOJE injectada (${SESSAO_LINES} linhas)"
echo "✓ CV injectado (${AGENT_CODE} — ${CV_LINES} linhas)"
echo "✓ VERDADE injectada (${VERDADE_LINES} linhas)"
echo "✓ VACINAS injectadas (${VACINAS_LINES} linhas)"
echo ""
echo "📝 Contexto completo: ${CONTEXT_BYTES} bytes / ${CONTEXT_LINES} linhas"
echo ""
echo "═══════════════════════════════════════════════════"
echo " 💬 A abrir ${AGENT_CODE} (${CLI}) em modo CHAT..."
echo "═══════════════════════════════════════════════════"
echo ""

# === INJECTAR CONTEXTO VIA FICHEIRO PARA AGENTES SEM FLAG ===
# Alguns CLIs não aceitam contexto via flag (Gemini usa GEMINI.md, Goose usa .goosehints)
# Para esses, copiamos o contexto para o ficheiro que o CLI espera no directório do projecto

MEMORY_FILE=$(jq -r ".agents[] | select(.code==\"$AGENT_CODE\") | .memory_file // empty" "$AGENTS_FILE")
PROJECT_PATH=""
if [[ -f "$MAKAN72_HOME/01-config/projects.json" ]]; then
    PROJECT_PATH=$(jq -r '.projects[] | select(.active==true) | .path' "$MAKAN72_HOME/01-config/projects.json" 2>/dev/null || true)
fi

if [[ -z "$CONTEXT_FLAG" && -n "$MEMORY_FILE" && -n "$PROJECT_PATH" && -d "$PROJECT_PATH" ]]; then
    # Agente sem flag de contexto — copiar para memory_file no projecto
    # Ex: GEMINI → GEMINI.md, GOOSE → .goosehints (definido em agents.json memory_file)
    TARGET_FILE="$PROJECT_PATH/$MEMORY_FILE"
    cp "$CONTEXT_FILE" "$TARGET_FILE"
    echo "📝 Contexto copiado para: $TARGET_FILE"
    echo "   (${MEMORY_FILE} — lido automaticamente pelo CLI)"

    # OPENCODE especial: também criar CONTEXT.md (usado pelo 2-step identity injection)
    if [[ "$CLI" == "opencode" ]]; then
        cp "$CONTEXT_FILE" "$PROJECT_PATH/CONTEXT.md"
        echo "📝 CONTEXT.md criado para OpenCode 2-step injection"
    fi

    sleep 1
fi

# === ENV VARS POR AGENTE (auto-approve, etc.) ===
# Ler env vars de agents.json (campo "env" opcional)
AGENT_ENV=$(jq -r ".agents[] | select(.code==\"$AGENT_CODE\") | .env // {} | to_entries[] | \"export \\(.key)=\\(.value)\"" "$AGENTS_FILE" 2>/dev/null || true)
if [[ -n "$AGENT_ENV" ]]; then
    while IFS= read -r env_line; do
        eval "$env_line"
    done <<< "$AGENT_ENV"
fi

# === EXECUTAR AGENTE COM CONTEXTO ===
# cli, context_flag e cli_flags lidos de agents.json — sem hardcoded

# FIX #1: Limpar ecrã antes de abrir agente (sem scroll)
sleep 0.3
clear

# Construir e executar comando dinamicamente
CONTEXT_CONTENT="$(cat "$CONTEXT_FILE")"

# Montar array de argumentos (evitar passar strings vazias)
CMD_ARGS=()
if [[ -n "$CONTEXT_FLAG" ]]; then
    # Verificar se existe flag de ficheiro (mais seguro para conteúdo grande)
    CONTEXT_FLAG_FILE=$(jq -r ".agents[] | select(.code==\"$AGENT_CODE\") | .context_flag_file // empty" "$AGENTS_FILE")
    if [[ -n "$CONTEXT_FLAG_FILE" ]]; then
        # Usar flag de ficheiro (ex: --append-system-prompt-file) — evita problemas com conteúdo grande
        CMD_ARGS+=("$CONTEXT_FLAG_FILE" "$CONTEXT_FILE")
    else
        CMD_ARGS+=("$CONTEXT_FLAG" "$CONTEXT_CONTENT")
    fi
fi
if [[ -n "$CLI_FLAGS" ]]; then
    read -ra EXTRA_FLAGS <<< "$CLI_FLAGS"
    CMD_ARGS+=("${EXTRA_FLAGS[@]}")
fi

# Mudar para o directório do projecto activo (se existir)
if [[ -n "$PROJECT_PATH" && -d "$PROJECT_PATH" ]]; then
    cd "$PROJECT_PATH"
fi

# === REGISTAR SESSÃO em active_slots.json (para peek/stop/status) ===
SLOTS_FILE="$MAKAN72_HOME/04-bus/active_slots.json"
SLOT_NUM=$(jq -r --arg code "$AGENT_CODE" '.agents[] | select(.code == $code) | .tab // 0' "$AGENTS_FILE" 2>/dev/null || echo "0")
SESSION_ID="m72_${AGENT_CODE}_$$"

# Source register function
source "$MAKAN72_HOME/05-scripts/core/makan72-functions.sh" 2>/dev/null || true

# Registar (usa flock, seguro para concorrência)
if type -t m72_register_slot &>/dev/null; then
    m72_register_slot "$SLOT_NUM" "$CLI" "$AGENT_CODE" "${PROJECT_PATH:-$PWD}" "$SESSION_ID" "$$"
else
    # Fallback manual se source falhar
    mkdir -p "$(dirname "$SLOTS_FILE")"
    [[ -f "$SLOTS_FILE" ]] || echo '{"slots":[]}' > "$SLOTS_FILE"
    tmp_reg="/tmp/m72_reg_$$.json"
    jq --arg slot "$SLOT_NUM" --arg cli "$CLI" --arg name "$AGENT_CODE" \
       --arg proj "${PROJECT_PATH:-$PWD}" --arg sess "$SESSION_ID" --arg pid "$$" \
       --arg started "$(date -Iseconds)" \
       '.slots += [{"slot":($slot|tonumber),"cli":$cli,"name":$name,"project":$proj,"session":$sess,"pid":($pid|tonumber),"started":$started}]' \
       "$SLOTS_FILE" > "$tmp_reg" 2>/dev/null && mv "$tmp_reg" "$SLOTS_FILE"
fi

# === CASO ESPECIAL: OPENCODE (2-step identity injection) ===
# O OpenCode CLI não lê system prompts externos. Solução confirmada (54 testes):
# Passo 1: opencode run "Lê o CONTEXT.md..." → estabelece identidade
# Passo 2: opencode run -c → sessão interactiva que mantém a identidade
# Ref: RELATORIO_OPENCODE_CONTEXTO_2026-03-24.md

if [[ "$CLI" == "opencode" && -n "$PROJECT_PATH" ]]; then
    # OpenCode lê CONTEXT.md automaticamente do directório do projecto
    # Basta abrir sessão nova — sem -c (evita carregar DB pesado e demora)
    if [[ -f "$PROJECT_PATH/CONTEXT.md" ]]; then
        echo "📝 CONTEXT.md presente — OpenCode vai ler automaticamente"
        echo ""
    fi
    opencode
    EXIT_CODE=$?
else
    # Executar agente normalmente (SEM exec — para cleanup automático correr depois)
    "$CLI" "${CMD_ARGS[@]}"
    EXIT_CODE=$?
fi

# Cleanup — remover slot quando agente sai
m72_unregister_slot "$SLOT_NUM" 2>/dev/null || true
exit $EXIT_CODE
