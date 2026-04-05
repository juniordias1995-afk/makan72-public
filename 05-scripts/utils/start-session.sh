#!/usr/bin/env bash
# start-session.sh — Iniciar sessão
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03 (V3: +argumentos CLI, --help)

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
PID_FILE="$MAKAN72_HOME/08-logs/cache/pids/session.pid"
SESSAO_FILE="$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml"
MISSAO_FILE="$MAKAN72_HOME/09-workspace/missao-actual.md"
LOG_DIR="$MAKAN72_HOME/08-logs/logs"

# === HELP ===
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES]

Iniciar sessão de trabalho no Makan72.

OPÇÕES:
  --project=PROJECTO    Nome do projecto
  --mission=MISSÃO      Missão da sessão
  --leader=LÍDER        Líder da sessão (default: CEO)
  --help, -h            Mostrar esta ajuda

EXEMPLOS:
  $0 --project="Makan72" --mission="Implementar X" --leader="CEO"
  $0 (interactivo — pergunta projecto, missão, líder)

NOTAS:
  - Se chamado sem argumentos, pergunta interactivamente
  - Preenche SESSAO_HOJE.yaml e missao-actual.md automaticamente
  - Cria PID file para evitar sessões múltiplas
EOF
    exit 0
}

# Verificar --help PRIMEIRO (antes de qualquer lógica)
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
fi

# Argumentos CLI
PROJECT="${PROJECT:-}"
MISSION="${MISSION:-}"
LEADER="${LEADER:-CEO}"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --project=*)
            PROJECT="${1#*=}"
            shift
            ;;
        --mission=*)
            MISSION="${1#*=}"
            shift
            ;;
        --leader=*)
            LEADER="${1#*=}"
            shift
            ;;
        *)
            echo "⚠️  Argumento desconhecido: $1"
            shift
            ;;
    esac
done

echo "=== START SESSION ==="
echo ""

# Se sem argumentos, tentar auto-detectar projecto activo
if [[ -z "$PROJECT" ]]; then
    PROJECTS_FILE="$MAKAN72_HOME/01-config/projects.json"
    if [[ -f "$PROJECTS_FILE" ]]; then
        ACTIVE_PROJECT=$(jq -r '.projects[] | select(.active==true) | .name' "$PROJECTS_FILE" 2>/dev/null | head -1)
        if [[ -n "$ACTIVE_PROJECT" && "$ACTIVE_PROJECT" != "null" ]]; then
            PROJECT="$ACTIVE_PROJECT"
            echo "   Auto-detectado projecto activo: $PROJECT"
        fi
    fi
fi

# Se AINDA sem projecto, perguntar interactivamente
if [[ -z "$PROJECT" ]]; then
    read -p "Projecto: " PROJECT
fi

# Se sem missão, perguntar (mesmo que projecto tenha sido auto-detectado)
if [[ -z "$MISSION" ]]; then
    read -p "Missão: " MISSION
fi

# Se sem líder, perguntar
if [[ -z "$LEADER" ]]; then
    read -p "Líder (default: CEO): " LEADER_INPUT
    if [[ -n "$LEADER_INPUT" ]]; then
        LEADER="$LEADER_INPUT"
    fi
fi

# Validar dados fornecidos
if [[ -z "$PROJECT" || -z "$MISSION" ]]; then
    echo "❌ ERRO: Projecto e Missão são obrigatórios"
    exit 1
fi

# Verificar PID de sessão activa
if [[ -f "$PID_FILE" ]]; then
    echo "⚠️  AVISO: Sessão já activa (PID: $(cat $PID_FILE))"
    echo "Para fechar: end-session.sh"
    echo ""
fi

# Passo 1: Preencher SESSAO_HOJE.yaml
echo "1. Preencher SESSAO_HOJE.yaml..."
DATA_HOJE=$(date +%Y-%m-%d)
INICIO_SESSAO=$(portable_date_iso)

# === AUTO-POPULAR AGENTES A PARTIR DE agents.json ===
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"
ACTIVE_AGENTS=""
PAUSED_AGENTS=""
MODOS_BLOCK=""

if [[ -f "$AGENTS_FILE" ]]; then
    # Agentes activos (status=active)
    ACTIVE_LIST=$(jq -r '.agents[] | select(.status=="active") | .code' "$AGENTS_FILE" 2>/dev/null || true)
    if [[ -n "$ACTIVE_LIST" ]]; then
        ACTIVE_AGENTS=""
        while IFS= read -r agent_code; do
            [[ -z "$agent_code" ]] && continue
            ACTIVE_AGENTS="${ACTIVE_AGENTS}  - ${agent_code}"$'\n'
            # Ler modos_possiveis do agents.json
            MODOS=$(jq -r ".agents[] | select(.code==\"$agent_code\") | .modos_possiveis // [] | @json" "$AGENTS_FILE" 2>/dev/null || echo "[]")
            if [[ "$MODOS" != "[]" && "$MODOS" != "null" ]]; then
                MODOS_BLOCK="${MODOS_BLOCK}  ${agent_code}: ${MODOS}"$'\n'
            fi
        done <<< "$ACTIVE_LIST"
    fi

    # Agentes pausados/removidos
    PAUSED_LIST=$(jq -r '.agents[] | select(.status=="paused" or .status=="inactive") | .code' "$AGENTS_FILE" 2>/dev/null || true)
    if [[ -n "$PAUSED_LIST" ]]; then
        while IFS= read -r agent_code; do
            [[ -z "$agent_code" ]] && continue
            PAUSED_AGENTS="${PAUSED_AGENTS}  - ${agent_code}"$'\n'
        done <<< "$PAUSED_LIST"
    fi
fi

# Defaults se vazio
[[ -z "$ACTIVE_AGENTS" ]] && ACTIVE_AGENTS="  # nenhum agente activo em agents.json"$'\n'
[[ -z "$PAUSED_AGENTS" ]] && PAUSED_AGENTS="  # nenhum agente pausado"$'\n'
[[ -z "$MODOS_BLOCK" ]] && MODOS_BLOCK="  # sem modos definidos em agents.json"$'\n'

# Ler path do projecto activo
PROJECT_PATH=""
if [[ -f "$MAKAN72_HOME/01-config/projects.json" ]]; then
    PROJECT_PATH=$(jq -r ".projects[] | select(.active==true) | .path" "$MAKAN72_HOME/01-config/projects.json" 2>/dev/null || true)
fi
PROJECT_PATH="${PROJECT_PATH:-(desconhecido)}"

# === AUTO-POPULAR SLOTS A PARTIR DE agents.json (campo "tab") ===
SLOTS_BLOCK=""
if [[ -f "$AGENTS_FILE" ]]; then
    for slot_n in 1 2 3 4 5; do
        SLOT_AGENT=$(jq -r --argjson tab "$slot_n" \
            '.agents[] | select(.status=="active" and .tab==$tab) | .code' \
            "$AGENTS_FILE" 2>/dev/null | head -1)
        if [[ -n "$SLOT_AGENT" && "$SLOT_AGENT" != "null" ]]; then
            SLOTS_BLOCK="${SLOTS_BLOCK}  ${slot_n}: ${SLOT_AGENT}"$'\n'
        else
            SLOTS_BLOCK="${SLOTS_BLOCK}  ${slot_n}: ~  # livre"$'\n'
        fi
    done
fi
[[ -z "$SLOTS_BLOCK" ]] && SLOTS_BLOCK="  # sem slots definidos"$'\n'

cat > "$SESSAO_FILE" << EOFSESSAO
# SESSAO_HOJE.yaml — Sessão em curso
# Gerado automaticamente por start-session.sh
# Agentes, MODOs e Slots populados de agents.json

sessao:
  data: "$DATA_HOJE"
  projecto: "$PROJECT"
  projecto_path: "$PROJECT_PATH"
  missao: "$MISSION"
  leader: "$LEADER"
  inicio: "$INICIO_SESSAO"
  tipo_execucao: "semi-auto"
  verbosidade: "COMPACTO"

slots:
${SLOTS_BLOCK}
modos_desta_sessao:
${MODOS_BLOCK}
agentes_activos:
${ACTIVE_AGENTS}
agentes_pausados:
${PAUSED_AGENTS}
tarefas: []

estado: "EM_CURSO"
EOFSESSAO

echo "   ✅ SESSAO_HOJE.yaml preenchido"

# Criar PID file
echo $$ > "$PID_FILE"
echo "   ✅ PID criado: $PID_FILE"

# Passo 2: Actualizar missao-actual.md
echo "2. Actualizar missao-actual.md..."
cat > "$MISSAO_FILE" << EOFMISSAO
# Missão Actual

**Estado:** EM CURSO
**Projecto:** $PROJECT
**Missão:** $MISSION
**Líder:** $LEADER
**Data de início:** $DATA_HOJE

---

## Objectivo

$MISSION

## Tarefas

Ver \`03-inbox/\` para lista de tarefas activas.

## Notas

Sessão iniciada em modo semi-auto (CEO controla estratégico, bot organiza técnico).
EOFMISSAO

echo "   ✅ missao-actual.md actualizado"

# Passo 3: Verificar saúde
echo "3. Verificar saúde do sistema..."
if [[ -x "$MAKAN72_HOME/05-scripts/utils/health-check.sh" ]]; then
    if bash "$MAKAN72_HOME/05-scripts/utils/health-check.sh" --quick; then
        echo "   ✅ Health check OK"
    else
        echo "   ⚠️  Health check com avisos"
    fi
else
    echo "   ⚠️  health-check.sh não encontrado"
fi

# Passo 4: Limpar resíduos
echo "4. Limpar resíduos da sessão anterior..."
if [[ -x "$MAKAN72_HOME/05-scripts/utils/cleanup-bus.sh" ]]; then
    bash "$MAKAN72_HOME/05-scripts/utils/cleanup-bus.sh" --dry-run || echo "   (dry-run)"
fi

# Passo 5: Inicializar bus
echo "5. Inicializar bus para agentes activos..."
mkdir -p "$MAKAN72_HOME/04-bus/heartbeat"
mkdir -p "$MAKAN72_HOME/04-bus/status"

# Criar heartbeat inicial para o líder
cat > "$MAKAN72_HOME/04-bus/heartbeat/${LEADER}_heartbeat.json" << EOFHEART
{
  "agent": "$LEADER",
  "timestamp": "$INICIO_SESSAO",
  "status": "alive",
  "current_task": "Iniciando sessão: $MISSION",
  "pid": $$
}
EOFHEART
echo "   ✅ Heartbeat $LEADER criado"
# Passo 5b: Arrancar daemon do team-bot em background
echo "5b. Arrancar team-bot daemon em background..."
if [[ -x "$MAKAN72_HOME/02-bots/team-bot.sh" ]]; then
    # IMPORTANTE: Limpar ZELLIJ_SESSION_NAME para que o daemon use o cache
    # (evita herdar a sessão do terminal que lançou — VACCINE dispatch bug)
    (
        unset ZELLIJ_SESSION_NAME
        unset ZELLIJ_PANE_ID
        unset ZELLIJ
        nohup bash "$MAKAN72_HOME/02-bots/team-bot.sh" daemon >> "$MAKAN72_HOME/08-logs/team-bot-daemon.log" 2>&1 &
        echo $! > "$MAKAN72_HOME/08-logs/cache/pids/daemon.pid"
    )
    DAEMON_PID=$(cat "$MAKAN72_HOME/08-logs/cache/pids/daemon.pid" 2>/dev/null || echo "?")
    echo "   ✅ Daemon arrancado (PID $DAEMON_PID) — sem ZELLIJ env herdado"
    echo "      Log: 08-logs/team-bot-daemon.log"
    echo "      Parar: bash 02-bots/team-bot.sh daemon-stop"
else
    echo "   ⚠️  team-bot.sh não encontrado ou sem permissões"
fi


# Passo 6: Mostrar resumo
echo "6. Resumo da sessão"
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│ SESSÃO INICIADA                             │"
echo "├─────────────────────────────────────────────┤"
echo "│ Projecto: $PROJECT"
echo "│ Missão: $MISSION"
echo "│ Líder: $LEADER"
echo "│ Data: $DATA_HOJE"
echo "│ Modo: semi-auto"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "✅ SESSÃO PRONTA!"

# Registar operacao
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
    if type log_operation &>/dev/null; then
        log_operation "start-session" "$LEADER" "OK" "project=$PROJECT,mission=$MISSION"
    fi
fi
exit 0
