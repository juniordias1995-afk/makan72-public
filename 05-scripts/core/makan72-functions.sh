#!/usr/bin/env bash
# =============================================================================
# makan72-functions.sh — Funções base do Makan72 (SEM TMUX)
# =============================================================================
# Versão: 2.0 (2026-03-24) — Código tmux removido
# =============================================================================

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"
SLOTS_FILE="$MAKAN72_HOME/04-bus/active_slots.json"
PROJECTS_FILE="$MAKAN72_HOME/01-config/projects.json"
INBOX_DIR="$MAKAN72_HOME/03-inbox"
LOGS_DIR="$MAKAN72_HOME/08-logs"
TEMP_DIR="/tmp/makan72_$$"

# Cores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# =============================================================================
# m72_detect_agent_info — Detecta info do agente pelo CLI
# =============================================================================
m72_detect_agent_info() {
    local CLI="$1"
    if [ -f "$AGENTS_FILE" ]; then
        jq -r --arg cli "$CLI" '.agents[] | select(.cli == $cli) | "\(.code)|\(.model)|\(.cli)|\(.code)"' "$AGENTS_FILE" 2>/dev/null | head -1
    else
        echo "$CLI|unknown|$CLI|$CLI"
    fi
}

# =============================================================================
# m72_count_inbox — Conta tarefas pendentes
# =============================================================================
m72_count_inbox() {
    local AGENT_CODE="$1"
    local PENDING_DIR="$INBOX_DIR/$AGENT_CODE/pending"
    if [ -d "$PENDING_DIR" ]; then
        find "$PENDING_DIR" -name "*.md" 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# =============================================================================
# m72_detect_slot — Detecta slot livre
# =============================================================================
m72_detect_slot() {
    if [ -f "$SLOTS_FILE" ]; then
        local used_slots=$(jq -r '.slots[].slot' "$SLOTS_FILE" 2>/dev/null | sort -n | tr '\n' ' ')
        for i in 1 2 3 4 5; do
            if ! echo "$used_slots" | grep -qw "$i"; then
                echo "$i"
                return 0
            fi
        done
        echo "1"
    else
        echo "1"
    fi
}

# =============================================================================
# m72_build_context — Constrói contexto para agente
# =============================================================================
m72_build_context() {
    local AGENT_CODE="$1"
    local AGENT_NAME="$2"
    local AGENT_MODEL="$3"
    local SLOT="$4"
    local PROJECT_NAME="$5"
    local PROJECT_PATH="$6"
    local INBOX_COUNT="$7"
    
    cat << EOF
# CONTEXTO MAKAN72
# Agente: $AGENT_NAME ($AGENT_CODE)
# Modelo: $AGENT_MODEL
# Slot: $SLOT
# Projeto: $PROJECT_NAME
# Path: $PROJECT_PATH
# Tarefas pendentes: $INBOX_COUNT

EOF
}

# =============================================================================
# m72_write_context_file — Escreve contexto em ficheiro temporário
# =============================================================================
m72_write_context_file() {
    local CONTEXTO="$1"
    local CONTEXT_FILE="$TEMP_DIR/context_$$.md"
    mkdir -p "$TEMP_DIR"
    echo "$CONTEXTO" > "$CONTEXT_FILE"
    echo "$CONTEXT_FILE"
}

# =============================================================================
# m72_cleanup_temp — Limpa temporários
# =============================================================================
m72_cleanup_temp() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"/*
    fi
}


# =============================================================================
# m72_register_slot — Regista slot activo com flock
# =============================================================================
m72_register_slot() {
    local SLOT="$1"
    local CLI="$2"
    local NAME="$3"
    local PROJECT="$4"
    local SESSION="$5"
    local PID="$6"
    
    mkdir -p "$(dirname "$SLOTS_FILE")"
    [[ -f "$SLOTS_FILE" ]] || echo '{"slots":[]}' > "$SLOTS_FILE"
    
    local TEMP_FILE="/tmp/slots_reg_$$.json"
    local STARTED=$(date -Iseconds)
    
    # Usar flock para evitar race conditions
    (
        flock -x 200
        # UPSERT: remover entradas antigas deste agente antes de adicionar
        local CLEAN_FILE="/tmp/slots_clean_$$.json"
        jq --arg name "$NAME" \
           '{ slots: [.slots[] | select(.name != $name)] }' \
           "$SLOTS_FILE" > "$CLEAN_FILE" 2>/dev/null

        # Adicionar nova entrada
        jq --arg slot "$SLOT" --arg cli "$CLI" --arg name "$NAME" \
           --arg proj "$PROJECT" --arg sess "$SESSION" --arg pid "$PID" \
           --arg started "$STARTED" \
           '.slots += [{"slot":($slot|tonumber),"cli":$cli,"name":$name,"project":$proj,"session":$sess,"pid":($pid|tonumber),"started":$started}]' \
           "$CLEAN_FILE" > "$TEMP_FILE" 2>/dev/null && mv "$TEMP_FILE" "$SLOTS_FILE"

        rm -f "$CLEAN_FILE"
    ) 200>"$SLOTS_FILE.lock"
}

# =============================================================================
# m72_list_sessions — Lista sessões activas (pipe-delimited)
# =============================================================================
m72_list_sessions() {
    if [ ! -f "$SLOTS_FILE" ]; then
        return 0
    fi
    jq -r '.slots[] | "\(.slot)|\(.name)|\(.cli)|\(.project)|\(.started)"' "$SLOTS_FILE" 2>/dev/null
}

# =============================================================================
# m72_kill_agent — Mata agente pelo CLI name (sem tmux, usa PID)
# =============================================================================
m72_kill_agent() {
    local TARGET_CLI="$1"
    
    if [ ! -f "$SLOTS_FILE" ]; then
        echo -e "${RED}ERRO: Sem sessões activas${RESET}"
        return 1
    fi
    
    local PID=$(jq -r --arg cli "$TARGET_CLI" '.slots[] | select(.cli == $cli) | .pid' "$SLOTS_FILE" 2>/dev/null)
    local SLOT=$(jq -r --arg cli "$TARGET_CLI" '.slots[] | select(.cli == $cli) | .slot' "$SLOTS_FILE" 2>/dev/null)
    
    if [[ -z "$PID" || "$PID" == "null" ]]; then
        echo -e "${RED}ERRO: Agente $TARGET_CLI não encontrado.${RESET}"
        return 1
    fi
    
    # Matar processo
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null || true
        sleep 1
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null || true
        fi
    fi
    
    # Remover slot
    m72_unregister_slot "$SLOT"
    echo -e "${GREEN}Agente $TARGET_CLI encerrado com sucesso!${RESET}"
}

# =============================================================================
# m72_unregister_slot — Remove slot do registo
# =============================================================================
m72_unregister_slot() {
    local SLOT="$1"
    if [ ! -f "$SLOTS_FILE" ]; then
        return 0
    fi
    
    local TEMP_FILE="/tmp/slots_unreg_$$.json"
    (
        flock -x 200
        jq --argjson slot "$SLOT" 'del(.slots[] | select(.slot == $slot))' "$SLOTS_FILE" > "$TEMP_FILE" 2>/dev/null && mv "$TEMP_FILE" "$SLOTS_FILE"
    ) 200>"$SLOTS_FILE.lock"
}

# =============================================================================
# m72_get_output — Captura output da sessão (sem tmux, usa log)
# =============================================================================
m72_get_output() {
    local SLOT="$1"
    
    if [ ! -f "$SLOTS_FILE" ]; then
        echo -e "${RED}ERRO: Sem sessões activas${RESET}"
        return 1
    fi
    
    local SESSION=$(jq -r --argjson slot "$SLOT" '.slots[] | select(.slot == $slot) | .session' "$SLOTS_FILE" 2>/dev/null)
    local PID=$(jq -r --argjson slot "$SLOT" '.slots[] | select(.slot == $slot) | .pid' "$SLOTS_FILE" 2>/dev/null)
    
    if [[ -z "$SESSION" || "$SESSION" == "null" ]]; then
        echo -e "${RED}ERRO: Slot $SLOT não encontrado${RESET}"
        return 1
    fi
    
    # Tentar obter output do log
    local LOG_FILE="${LOGS_DIR}/sessions/${SESSION}.log"
    if [[ -f "$LOG_FILE" ]]; then
        tail -n 100 "$LOG_FILE"
    else
        if kill -0 "$PID" 2>/dev/null; then
            echo "(agente a correr, sem log disponível)"
        else
            echo "(sem output — agente pode ter terminado sem log)"
        fi
    fi
}


# =============================================================================
# m72_clean_all — Limpa TODOS os slots e sessões (sem tmux)
# =============================================================================
m72_clean_all() {
    if [ ! -f "$SLOTS_FILE" ]; then
        echo "✓ Nenhuma sessão activa"
        return 0
    fi
    
    local COUNT=$(jq '.slots | length' "$SLOTS_FILE" 2>/dev/null || echo "0")
    
    if [ "$COUNT" -eq 0 ]; then
        echo "✓ Nenhuma sessão activa"
        return 0
    fi
    
    echo "🧹 A limpar $COUNT slot(s)..."
    
    # Matar todos os processos pelos PIDs
    jq -r '.slots[].pid' "$SLOTS_FILE" 2>/dev/null | while read -r PID; do
        if [[ -n "$PID" && "$PID" != "null" ]]; then
            if kill -0 "$PID" 2>/dev/null; then
                kill "$PID" 2>/dev/null || true
                sleep 0.5
                kill -9 "$PID" 2>/dev/null || true
                echo "  ✓ PID $PID terminado"
            fi
        fi
    done
    
    # Limpar active_slots.json
    local TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S)
    echo "{\"updated\":\"$TIMESTAMP\",\"slots\":[]}" > "$SLOTS_FILE"
    
    echo "✓ $COUNT slot(s) limpos"
}

# =============================================================================
# m72_clean_orphan_slots — Remove slots de sessões terminadas (sem tmux)
# =============================================================================
m72_clean_orphan_slots() {
    local SLOTS_FILE="$MAKAN72_HOME/04-bus/active_slots.json"
    local TEMP_FILE="/tmp/slots_clean_$$.json"
    local _clean_lock_fd

    [[ -f "$SLOTS_FILE" ]] || return 0

    # Adquirir lock na shell actual (NÃO em subshell) — preserva scope de CLEANED
    exec {_clean_lock_fd}>"$SLOTS_FILE.lock"
    flock -x "$_clean_lock_fd"
    # Cleanup automático em qualquer saída da função (sucesso ou erro)
    # NOTA: NÃO apagar $SLOTS_FILE.lock — é partilhado com m72_register_slot / m72_unregister_slot
    trap "flock -u $_clean_lock_fd 2>/dev/null; exec {_clean_lock_fd}>&- 2>/dev/null; rm -f '$TEMP_FILE'" RETURN

    cp "$SLOTS_FILE" "$TEMP_FILE"

    local CLEANED=0
    local alive_slots=()

    for slot_json in $(jq -c '.slots[]' "$TEMP_FILE" 2>/dev/null); do
        local pid
        pid=$(echo "$slot_json" | jq -r '.pid' 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            alive_slots+=("$slot_json")
        else
            CLEANED=$((CLEANED + 1))
        fi
    done

    # Escrever slots sobreviventes de volta (atomic move)
    if [[ ${#alive_slots[@]} -gt 0 ]]; then
        printf '%s\n' "${alive_slots[@]}" | jq -s '{"slots": .}' > "$TEMP_FILE"
    else
        echo '{"slots": []}' > "$TEMP_FILE"
    fi
    mv "$TEMP_FILE" "$SLOTS_FILE"

    log "m72_clean_orphan_slots: $CLEANED slot(s) removidos"
    # ATENÇÃO: NÃO fazer rm -f "$SLOTS_FILE.lock" aqui!
    # O lock é partilhado e gerido pelo trap RETURN acima (apenas unlock + close fd)
}

# =============================================================================
# m72_clean_old_heartbeats — Limpa heartbeats antigos (>48h)
# =============================================================================
m72_clean_old_heartbeats() {
    local HEARTBEAT_DIR="$MAKAN72_HOME/04-bus/heartbeat"
    if [ ! -d "$HEARTBEAT_DIR" ]; then
        return 0
    fi
    
    local CLEANED=0
    while read -r f; do
        rm -f "$f"
        CLEANED=$((CLEANED + 1))
    done < <(find "$HEARTBEAT_DIR" -name "*.json" -mmin +2880 2>/dev/null)
    
    if [ "$CLEANED" -gt 0 ]; then
        echo "✓ $CLEANED heartbeat(s) antigo(s) removido(s)"
    fi
}


# =============================================================================
# m72_attach_agent — Anexa a sessão de um agente (abre nova janela)
# =============================================================================
m72_attach_agent() {
    local AGENT_CODE="$1"
    
    if [ ! -f "$AGENTS_FILE" ]; then
        echo -e "${RED}ERRO: agents.json não encontrado${RESET}"
        return 1
    fi
    
    # Obter info do agente
    local AGENT_CLI=$(jq -r --arg code "$AGENT_CODE" '.agents[] | select(.code == $code) | .cli' "$AGENTS_FILE" 2>/dev/null)
    
    if [[ -z "$AGENT_CLI" || "$AGENT_CLI" == "null" ]]; then
        echo -e "${RED}ERRO: Agente $AGENT_CODE não encontrado${RESET}"
        return 1
    fi
    
    # Obter projecto activo
    local PROJECT_PATH="$(pwd)"
    if [ -f "$PROJECTS_FILE" ]; then
        local ACTIVE_PROJECT=$(jq -r '.active_project // empty' "$PROJECTS_FILE" 2>/dev/null)
        if [[ -n "$ACTIVE_PROJECT" ]]; then
            PROJECT_PATH=$(jq -r --arg id "$ACTIVE_PROJECT" '.projects[] | select(.id==$id) | .path // pwd' "$PROJECTS_FILE" 2>/dev/null)
        fi
    fi
    
    echo -e "${CYAN}🔗 A abrir $AGENT_CODE ($AGENT_CLI) em nova janela...${RESET}"
    echo -e "${YELLOW}   Projecto: $PROJECT_PATH${RESET}"
    echo ""
    
    # Executar agente em nova instância
    cd "$PROJECT_PATH" 2>/dev/null || true
    "$AGENT_CLI"
}

# =============================================================================
# m72_broadcast — Envia mensagem a todos os agentes (via inbox)
# =============================================================================
m72_broadcast() {
    local MESSAGE="$1"
    local COUNT=0
    local FAILED=0
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    if [ ! -f "$AGENTS_FILE" ]; then
        echo -e "${RED}ERRO: agents.json não encontrado${RESET}"
        return 1
    fi
    
    echo "📢 Broadcast: $MESSAGE"
    echo ""
    
    # Obter agentes activos e enviar para inbox de cada um
    for agent_code in $(jq -r '.agents[] | select(.status=="active") | .code' "$AGENTS_FILE" 2>/dev/null); do
        local inbox_file="$INBOX_DIR/$agent_code/pending/broadcast_${TIMESTAMP}.md"
        
        # Criar ficheiro de broadcast no inbox do agente
        cat > "$inbox_file" << BCAST_EOF
# Broadcast Recebido

**De:** Sistema Makan72
**Data:** $(date -Iseconds)
**Tipo:** Broadcast Geral

---

## Mensagem

$MESSAGE

---

**Nota:** Este broadcast foi enviado a todos os agentes activos.
BCAST_EOF
        
        if [[ -f "$inbox_file" ]]; then
            echo -e "${GREEN}✓ $agent_code${RESET} — Broadcast entregue"
            COUNT=$((COUNT + 1))
        else
            echo -e "${RED}✗ $agent_code${RESET} — Falha ao entregar"
            FAILED=$((FAILED + 1))
        fi
    done
    
    echo ""
    echo "📊 Broadcast completo: $COUNT entregue(s), $FAILED falha(s)"
    return 0
}

