#!/usr/bin/env bash
# dispatch.sh — Entrega mensagens no terminal de agentes via Zellij
# Módulo do team-bot.sh (carregado automaticamente)
# Autor: QWEN (MC)
# Data: 2026-03-28
#
# LIMITAÇÃO (Zellij 0.43.1): O dispatch muda de tab visivelmente (~0.5s).
# Em Zellij 0.44+ será possível usar --pane-id para escrita invisível.

# === DEPENDÊNCIAS ===
# Requer: zellij (v0.43.1+), jq
# Requer módulos: nenhum (standalone)

# === CONFIGURAÇÃO ===
DISPATCH_ENABLED="${DISPATCH_ENABLED:-true}"
DISPATCH_LOG="$MAKAN72_HOME/08-logs/dispatch.log"
DISPATCH_DELAY="${DISPATCH_DELAY:-0.3}"

# Testar se sessão Zellij responde a comandos (timeout 2s)
_dispatch_session_alive() {
    local session="$1"
    timeout 2 zellij -s "$session" action query-tab-names &>/dev/null
}

# Nome canónico da sessão Makan72 — NUNCA comunicar com outras sessões
MAKAN72_SESSION_NAME="Makan72"

# Descobrir sessão Zellij do Makan72 — APENAS sessão "Makan72"
# REGRA: O Makan72 comunica EXCLUSIVAMENTE dentro do seu próprio sistema.
#        Nunca usar sessões externas (ex: .team, jumping-diplodocus, etc.)
_dispatch_resolve_session() {
    # 1. Variável de ambiente explícita (override de configuração)
    if [[ -n "${MAKAN72_ZELLIJ_SESSION:-}" ]]; then
        if _dispatch_session_alive "$MAKAN72_ZELLIJ_SESSION"; then
            echo "$MAKAN72_ZELLIJ_SESSION"
            return 0
        fi
        _dispatch_log "AVISO: MAKAN72_ZELLIJ_SESSION=$MAKAN72_ZELLIJ_SESSION não responde"
    fi

    # 2. Sessão canónica "Makan72" (nome fixo — sempre usar este)
    if _dispatch_session_alive "$MAKAN72_SESSION_NAME"; then
        # Actualizar cache com o valor correcto
        local session_file="$MAKAN72_HOME/08-logs/cache/zellij_session.txt"
        echo "$MAKAN72_SESSION_NAME" > "$session_file" 2>/dev/null
        echo "$MAKAN72_SESSION_NAME"
        return 0
    fi

    # 3. Se estamos DENTRO da sessão Makan72, usar sessão actual
    if [[ -n "${ZELLIJ_SESSION_NAME:-}" && "$ZELLIJ_SESSION_NAME" == "$MAKAN72_SESSION_NAME" ]]; then
        echo "$ZELLIJ_SESSION_NAME"
        return 0
    fi

    # FALHA: Sessão Makan72 não encontrada — NÃO fazer fallback para outras sessões
    _dispatch_log "ERRO: Sessão '$MAKAN72_SESSION_NAME' não encontrada. Inicia a sessão com: makan72 start"
    return 1
}

ZELLIJ_TARGET=""

# === FUNÇÕES INTERNAS ===

_dispatch_log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] DISPATCH: $*" >> "$DISPATCH_LOG"
}

_dispatch_find_tab() {
    local agent_code="$1"
    local agent_lower="${agent_code,,}"

    local tab_names
    tab_names=$(timeout 2 zellij -s "$ZELLIJ_TARGET" action query-tab-names 2>/dev/null) || return 1

    local match=""
    while IFS= read -r tab; do
        local tab_lower="${tab,,}"
        if [[ "$tab_lower" == *"$agent_lower"* ]]; then
            match="$tab"
            break
        fi
    done <<< "$tab_names"

    if [[ -n "$match" ]]; then
        echo "$match"
        return 0
    fi
    return 1
}

_dispatch_get_current_tab() {
    local state_file="$MAKAN72_HOME/08-logs/cache/dispatch_current_tab.txt"
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
    else
        echo ""
    fi
}

_dispatch_save_current_tab() {
    local tab_name="$1"
    local state_file="$MAKAN72_HOME/08-logs/cache/dispatch_current_tab.txt"
    mkdir -p "$(dirname "$state_file")"
    echo "$tab_name" > "$state_file"
}

# _dispatch_goto_agent — Navegar para o terminal de um agente
# Estrategia 1: active_slots.json (registo dinamico — preferido)
# Estrategia 2: Fallback por nome de tab (compatibilidade)
_dispatch_goto_agent() {
    local agent_code="$1"

    # --- ESTRATEGIA 1: active_slots.json (dinamico) ---
    local slots_file="$MAKAN72_HOME/04-bus/active_slots.json"
    if [[ -f "$slots_file" ]] && command -v jq &>/dev/null; then
        # Obter entradas do agente (mais recente primeiro)
        local entries
        entries=$(jq -r --arg code "$agent_code" \
            '[.slots[] | select(.name == $code)] | sort_by(.started) | reverse | .[] | "\(.pid)|\(.slot)"' \
            "$slots_file" 2>/dev/null)

        while IFS='|' read -r pid slot; do
            [[ -z "$pid" || -z "$slot" ]] && continue
            # Verificar se o processo ainda esta vivo
            if kill -0 "$pid" 2>/dev/null; then
                _dispatch_log "Encontrado $agent_code vivo: slot=$slot, pid=$pid"
                if timeout 2 zellij -s "$ZELLIJ_TARGET" action go-to-tab "$slot" 2>/dev/null; then
                    return 0
                fi
            fi
        done <<< "$entries"

        _dispatch_log "AVISO: $agent_code nao encontrado vivo em active_slots.json"
    fi

    # --- ESTRATEGIA 2: Fallback — procurar nome do agente nos nomes de tabs ---
    local tab_names
    tab_names=$(timeout 2 zellij -s "$ZELLIJ_TARGET" action query-tab-names 2>/dev/null) || return 1

    local agent_lower="${agent_code,,}"
    while IFS= read -r tab; do
        local tab_lower="${tab,,}"
        if [[ "$tab_lower" == *"$agent_lower"* ]]; then
            _dispatch_log "Fallback: $agent_code encontrado em tab '$tab'"
            timeout 2 zellij -s "$ZELLIJ_TARGET" action go-to-tab-name "$tab" 2>/dev/null && return 0
        fi
    done <<< "$tab_names"

    return 1
}

# === FUNÇÕES PÚBLICAS ===

# dispatch_to_agent — Entregar mensagem no terminal de um agente
# Uso: dispatch_to_agent <agent_code> <message> [from_tab]
dispatch_to_agent() {
    [[ "$DISPATCH_ENABLED" != "true" ]] && return 0

    local agent_code="${1:?Uso: dispatch_to_agent <agent_code> <message> [from_tab]}"
    local message="${2:?Falta message}"
    local from_tab="${3:-}"

    # Verificar que Zellij está disponível
    if ! command -v zellij &>/dev/null; then
        _dispatch_log "ERRO: zellij não encontrado no PATH"
        return 1
    fi

    # Resolver sessão Zellij (funciona dentro E fora)
    ZELLIJ_TARGET=$(_dispatch_resolve_session)
    if [[ -z "$ZELLIJ_TARGET" ]]; then
        _dispatch_log "ERRO: nenhuma sessão Zellij encontrada"
        return 1
    fi
    _dispatch_log "Sessão Zellij: $ZELLIJ_TARGET"

    # Guardar tab de origem ANTES de saltar
    if [[ -z "$from_tab" ]]; then
        from_tab=$(_dispatch_get_current_tab)
    fi

    _dispatch_log "Entregando a $agent_code (return: ${from_tab:-DESCONHECIDO})..."

    # 1. Navegar para o agente destino (active_slots.json -> fallback nome)
    if ! _dispatch_goto_agent "$agent_code"; then
        _dispatch_log "AVISO: nao foi possivel encontrar $agent_code"
        return 1
    fi
    sleep "$DISPATCH_DELAY"

    # 2. Escrever a mensagem no terminal do agente
    timeout 5 zellij -s "$ZELLIJ_TARGET" action write-chars "$message" 2>/dev/null || {
        _dispatch_log "ERRO: falha ao escrever mensagem (timeout ou erro)"
        return 1
    }
    sleep 0.1

    # 3. Enviar Enter para submeter a mensagem
    # Nota: Alguns CLIs esperam CR (13), outros LF (10). Enviar CR para máxima compatibilidade.
    timeout 5 zellij -s "$ZELLIJ_TARGET" action write 13 2>/dev/null || {
        _dispatch_log "ERRO: falha ao enviar Enter (timeout ou erro)"
        return 1
    }

    _dispatch_log "OK: mensagem entregue a $agent_code"

    # 4. Voltar à tab de origem (se conhecida)
    if [[ -n "$from_tab" ]]; then
        sleep "$DISPATCH_DELAY"
        timeout 3 zellij -s "$ZELLIJ_TARGET" action go-to-tab-name "$from_tab" 2>/dev/null || true
        _dispatch_log "OK: voltou para tab $from_tab"
    else
        _dispatch_log "AVISO: tab de origem desconhecida"
    fi

    return 0
}

# dispatch_notify — Notificar agente de nova tarefa no inbox
# Uso: dispatch_notify <agent_code> <filename> [from_agent]
dispatch_notify() {
    local agent_code="${1:?Uso: dispatch_notify <agent_code> <filename> [from]}"
    local filename="${2:?Falta filename}"
    local from_agent="${3:-SISTEMA}"

    local message="Nova tarefa no teu inbox de $from_agent. Ficheiro: $filename — Lê e executa conforme as instruções."

    dispatch_to_agent "$agent_code" "$message"
}

# dispatch_broadcast — Enviar mensagem a TODOS os agentes activos
# Uso: dispatch_broadcast <message> [except_agent]
dispatch_broadcast() {
    local message="${1:?Uso: dispatch_broadcast <message> [except]}"
    local except="${2:-}"
    local agents_file="$MAKAN72_HOME/01-config/agents.json"

    if [[ ! -f "$agents_file" ]]; then
        _dispatch_log "ERRO: agents.json não encontrado"
        return 1
    fi

    local agents
    agents=$(jq -r '.agents[] | select(.status == "active") | .code' "$agents_file" 2>/dev/null)

    local sent=0
    local failed=0

    while IFS= read -r agent; do
        [[ -z "$agent" ]] && continue
        if [[ -n "$except" && "${agent,,}" == "${except,,}" ]]; then
            continue
        fi
        if dispatch_to_agent "$agent" "$message"; then
            sent=$((sent + 1))
        else
            failed=$((failed + 1))
        fi
        sleep "$DISPATCH_DELAY"
    done <<< "$agents"

    _dispatch_log "Broadcast: sent=$sent, failed=$failed"
    echo "dispatch broadcast: $sent entregues, $failed falharam"
}

# dispatch_cleanup_stale — Remover entradas mortas do active_slots.json
dispatch_cleanup_stale() {
    local slots_file="$MAKAN72_HOME/04-bus/active_slots.json"
    [[ -f "$slots_file" ]] || { echo "dispatch cleanup: ficheiro nao existe"; return 0; }
    command -v jq &>/dev/null || { echo "ERRO: jq nao encontrado"; return 1; }

    local pids
    pids=$(jq -r '.slots[].pid' "$slots_file" 2>/dev/null | sort -u)
    [[ -z "$pids" ]] && { echo "dispatch cleanup: 0 (vazio)"; return 0; }

    local dead_pids=""
    local removed=0

    while IFS= read -r pid; do
        [[ -z "$pid" ]] && continue
        if ! kill -0 "$pid" 2>/dev/null; then
            dead_pids="${dead_pids}${pid} "
            removed=$((removed + 1))
        fi
    done <<< "$pids"

    if [[ $removed -gt 0 ]]; then
        local tmp_file="${slots_file}.tmp"
        (
            flock -x 200
            local filter=""
            for dp in $dead_pids; do
                filter="${filter} and .pid != ${dp}"
            done
            filter="${filter# and }"
            jq "{ slots: [.slots[] | select($filter)] }" "$slots_file" > "$tmp_file" 2>/dev/null \
                && mv "$tmp_file" "$slots_file"
        ) 200>"$slots_file.lock"
        _dispatch_log "Limpeza: $removed entradas mortas removidas"
    fi

    echo "dispatch cleanup: $removed removidos"
}

# dispatch_status — Estado do módulo
dispatch_status() {
    local zellij_ok="false"
    if command -v zellij &>/dev/null && _dispatch_resolve_session &>/dev/null; then
        zellij_ok="true"
    fi

    local slots_alive=0
    local slots_file="$MAKAN72_HOME/04-bus/active_slots.json"
    if [[ -f "$slots_file" ]] && command -v jq &>/dev/null; then
        local pids
        pids=$(jq -r '.slots[].pid' "$slots_file" 2>/dev/null | sort -u)
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            kill -0 "$pid" 2>/dev/null && slots_alive=$((slots_alive + 1))
        done <<< "$pids"
    fi

    echo "dispatch: enabled=$DISPATCH_ENABLED, zellij=$zellij_ok, agentes_vivos=$slots_alive"
}
