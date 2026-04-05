#!/usr/bin/env bash
# inbox.sh — Iterar inboxes e contar tarefas pendentes
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: jq
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
INBOX_ENABLED="${INBOX_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
inbox_run() {
    [[ "$INBOX_ENABLED" != "true" ]] && return 0
    
    local total=0
    echo "=== INBOX PROCESSING ==="
    
    # Verificar se agents.json existe
    if [[ ! -f "$MAKAN72_HOME/01-config/agents.json" ]]; then
        echo "ERROR: agents.json não encontrado"
        return 1
    fi
    
    # Listar agentes activos
    local agents
    agents=$(jq -r '.agents[] | select(.status == "active") | .code' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null)
    
    if [[ -z "$agents" ]]; then
        echo "Nenhum agente activo encontrado"
        return 0
    fi
    
    # Para cada agente, contar pendentes
    while IFS= read -r agent; do
        local pending_dir="$MAKAN72_HOME/03-inbox/$agent/pending"
        if [[ -d "$pending_dir" ]]; then
            local count
            count=$(find "$pending_dir" -type f -name "*.md" 2>/dev/null | wc -l)
            if [[ $count -gt 0 ]]; then
                echo "  $agent: $count pendente(s)"
                total=$((total + count))
            fi
        fi
    done <<< "$agents"
    
    echo "TOTAL: $total tarefa(s) pendente(s)"
}

inbox_count() {
    local total=0
    local agents
    agents=$(jq -r '.agents[] | select(.status == "active") | .code' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null)
    
    while IFS= read -r agent; do
        local pending_dir="$MAKAN72_HOME/03-inbox/$agent/pending"
        if [[ -d "$pending_dir" ]]; then
            local count
            count=$(find "$pending_dir" -type f -name "*.md" 2>/dev/null | wc -l)
            total=$((total + count))
        fi
    done <<< "$agents"
    
    echo "$total"
}

inbox_status() {
    echo "inbox: enabled=$INBOX_ENABLED, pending=$(inbox_count)"
}

# Detectar ficheiros novos e gerar alertas (com dedup por ficheiro)
inbox_watch() {
    local ALERTS_DIR="$MAKAN72_HOME/04-bus/alerts"
    local CACHE_FILE="$MAKAN72_HOME/08-logs/cache/inbox-state.txt"
    local DISPATCHED_FILE="$MAKAN72_HOME/08-logs/cache/inbox-dispatched.txt"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$ALERTS_DIR"
    mkdir -p "$(dirname "$CACHE_FILE")"

    # Ler ficheiros já despachados (dedup por ficheiro, não por contagem)
    declare -A dispatched_files
    if [[ -f "$DISPATCHED_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && dispatched_files["$line"]=1
        done < "$DISPATCHED_FILE"
    fi

    # Guardar novas contagens
    > "$CACHE_FILE"

    # Verificar cada agente
    if [[ -f "$MAKAN72_HOME/01-config/agents.json" ]]; then
        local agents
        agents=$(jq -r '.agents[] | select(.status == "active") | .code' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null)

        while IFS= read -r agent; do
            local inbox_dir="$MAKAN72_HOME/03-inbox/$agent/pending"
            local new_count=0

            if [[ -d "$inbox_dir" ]]; then
                new_count=$(find "$inbox_dir" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
            fi

            # Guardar contagem no cache (SEMPRE — não só quando aumenta)
            echo "$agent=$new_count" >> "$CACHE_FILE"

            # Verificar ficheiros NOVOS (não despachados) — dedup por nome de ficheiro
            if [[ -d "$inbox_dir" && $new_count -gt 0 ]]; then
                local new_files_to_dispatch=""
                local new_file_count=0

                while IFS= read -r filepath; do
                    [[ -z "$filepath" ]] && continue
                    local filename
                    filename=$(basename "$filepath")
                    local dedup_key="${agent}:${filename}"

                    if [[ -z "${dispatched_files[$dedup_key]:-}" ]]; then
                        # Cap de 500 entradas para evitar memory bloat
                        if [[ ${#dispatched_files[@]} -lt 500 ]]; then
                            # Ficheiro novo — marcar como despachado
                            dispatched_files["$dedup_key"]=1
                            new_files_to_dispatch="${new_files_to_dispatch}${filename} "
                            new_file_count=$((new_file_count + 1))
                        else
                            echo "⚠️ Cap de 500 atingido, ignorando: $dedup_key"
                        fi
                    fi
                done < <(find "$inbox_dir" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null)

                if [[ $new_file_count -gt 0 ]]; then
                    echo "📬 NOVO: $agent tem $new_file_count ficheiro(s) novo(s): $new_files_to_dispatch"

                    # Gerar alerta JSON
                    cat > "$ALERTS_DIR/inbox_${agent}_${timestamp}.json" << ALERT_JSON
{
  "type": "inbox_new",
  "agent": "$agent",
  "count": $new_file_count,
  "total": $new_count,
  "files": "$new_files_to_dispatch",
  "timestamp": "$(date -Iseconds)"
}
ALERT_JSON
                    # Dispatch: notificar agente via Zellij (UMA VEZ por ficheiro novo)
                    if type -t dispatch_to_agent &>/dev/null; then
                        dispatch_to_agent "$agent" "Tens $new_file_count tarefa(s) nova(s) no inbox. Lê e executa: cat ~/.Makan72/03-inbox/$agent/pending/*.md" 2>/dev/null || true
                    fi
                fi
            fi
        done <<< "$agents"
    fi

    # Guardar estado de ficheiros despachados
    printf '%s\n' "${!dispatched_files[@]}" > "$DISPATCHED_FILE"
}


# =============================================================================
# inbox_watch_continuous — Polling contínuo (background) com dedup por ficheiro
# =============================================================================
inbox_watch_continuous() {
    local INTERVAL="${1:-10}"  # Default: 10 segundos
    local ALERTS_DIR="$MAKAN72_HOME/04-bus/alerts"
    local CACHE_FILE="$MAKAN72_HOME/08-logs/cache/inbox-state.txt"
    local DISPATCHED_FILE="$MAKAN72_HOME/08-logs/cache/inbox-dispatched.txt"
    local PID_FILE="$MAKAN72_HOME/08-logs/cache/inbox_watch.pid"

    echo $$ > "$PID_FILE"
    mkdir -p "$ALERTS_DIR"
    mkdir -p "$(dirname "$CACHE_FILE")"

    # Carregar ficheiros já despachados (persistido entre restarts)
    declare -A dispatched_files
    if [[ -f "$DISPATCHED_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && dispatched_files["$line"]=1
        done < "$DISPATCHED_FILE"
    fi

    # Loop contínuo
    while true; do
        sleep "$INTERVAL"

        # Verificar cada agente
        if [[ -f "$MAKAN72_HOME/01-config/agents.json" ]]; then
            local agents
            agents=$(jq -r '.agents[] | select(.status == "active") | .code' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null)

            # Actualizar cache de contagens (SEMPRE)
            > "$CACHE_FILE"

            while IFS= read -r agent; do
                local inbox_dir="$MAKAN72_HOME/03-inbox/$agent/pending"
                local new_count=0

                if [[ -d "$inbox_dir" ]]; then
                    new_count=$(find "$inbox_dir" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
                fi

                # SEMPRE actualizar contagem (FIX: antes só actualizava quando aumentava)
                echo "$agent=$new_count" >> "$CACHE_FILE"

                # Verificar ficheiros NOVOS (dedup por nome — nunca despacha o mesmo ficheiro 2x)
                if [[ -d "$inbox_dir" && $new_count -gt 0 ]]; then
                    local new_files_to_dispatch=""
                    local new_file_count=0

                    while IFS= read -r filepath; do
                        [[ -z "$filepath" ]] && continue
                        local filename
                        filename=$(basename "$filepath")
                        local dedup_key="${agent}:${filename}"

                        if [[ -z "${dispatched_files[$dedup_key]:-}" ]]; then
                            dispatched_files["$dedup_key"]=1
                            new_files_to_dispatch="${new_files_to_dispatch}${filename} "
                            new_file_count=$((new_file_count + 1))
                        fi
                    done < <(find "$inbox_dir" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null)

                    if [[ $new_file_count -gt 0 ]]; then
                        local timestamp=$(date +%Y%m%d_%H%M%S)
                        echo "📬 [WATCH] NOVO: $agent tem $new_file_count ficheiro(s) novo(s): $new_files_to_dispatch"

                        # Gerar alerta
                        cat > "$ALERTS_DIR/watch_${agent}_${timestamp}.json" << ALERT_EOF
{
  "type": "inbox_new",
  "agent": "$agent",
  "count": $new_file_count,
  "total": $new_count,
  "files": "$new_files_to_dispatch",
  "timestamp": "$(date -Iseconds)"
}
ALERT_EOF

                        # Dispatch: notificar agente via Zellij (UMA VEZ por ficheiro novo)
                        if type -t dispatch_to_agent &>/dev/null; then
                            dispatch_to_agent "$agent" "Tens $new_file_count tarefa(s) nova(s) no inbox. Lê e executa: cat ~/.Makan72/03-inbox/$agent/pending/*.md" 2>/dev/null || true
                        fi

                        # Persistir estado de dedup
                        printf '%s\n' "${!dispatched_files[@]}" > "$DISPATCHED_FILE"
                    fi
                else
                    # Limpar ficheiros despachados deste agente se inbox está vazio
                    # (permite re-despachar se alguém enviar o mesmo ficheiro de novo)
                    local keys_to_remove=()
                    for key in "${!dispatched_files[@]}"; do
                        if [[ "$key" == "${agent}:"* ]]; then
                            keys_to_remove+=("$key")
                        fi
                    done
                    for key in "${keys_to_remove[@]}"; do
                        unset dispatched_files["$key"]
                    done
                fi
            done <<< "$agents"
        fi
    done
}

# inbox_watch_stop — Parar polling contínuo
inbox_watch_stop() {
    local PID_FILE="$MAKAN72_HOME/08-logs/cache/inbox_watch.pid"
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null && rm -f "$PID_FILE" && echo "✅ Inbox watch parado (PID: $pid)" || echo "❌ Falha ao parar"
    else
        echo "⚠️  Inbox watch não está a correr"
    fi
}

# inbox_watch_status — Verificar status do polling
inbox_watch_status() {
    local PID_FILE="$MAKAN72_HOME/08-logs/cache/inbox_watch.pid"
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ Inbox watch a correr (PID: $pid)"
        else
            echo "⚠️  Processo morto, a limpar PID file"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Inbox watch não está a correr"
    fi
}
