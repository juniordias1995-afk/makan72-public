#!/usr/bin/env bash
# heartbeat.sh — Verificar heartbeats dos agentes
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: jq
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
HEARTBEAT_ENABLED="${HEARTBEAT_ENABLED:-true}"
HEARTBEAT_TTL_HOURS="${HEARTBEAT_TTL_HOURS:-24}"

# === FUNÇÕES PÚBLICAS ===
heartbeat_run() {
    [[ "$HEARTBEAT_ENABLED" != "true" ]] && return 0
    
    echo "=== HEARTBEAT CHECK ==="
    
    local heartbeat_dir="$MAKAN72_HOME/04-bus/heartbeat"
    if [[ ! -d "$heartbeat_dir" ]]; then
        echo "WARNING: Pasta heartbeat não existe"
        return 0
    fi
    
    local now
    now=$(date +%s)
    local ttl_seconds=$((HEARTBEAT_TTL_HOURS * 3600))
    local dead_agents=0
    
    # Verificar cada heartbeat
    for hb_file in "$heartbeat_dir"/*_heartbeat.json; do
        [[ -f "$hb_file" ]] || continue
        
        local agent timestamp agent_time diff
        agent=$(basename "$hb_file" | sed 's/_heartbeat.json//')
        timestamp=$(jq -r '.timestamp // empty' "$hb_file" 2>/dev/null)
        
        if [[ -z "$timestamp" ]]; then
            echo "  $agent: SEM TIMESTAMP"
            continue
        fi
        
        # Converter timestamp para epoch
        agent_time=$(portable_date_parse "$timestamp" 2>/dev/null || echo "0")
        diff=$((now - agent_time))
        local hours_ago=$((diff / 3600))
        
        if [[ $diff -gt $ttl_seconds ]]; then
            echo "  ❌ $agent: MORTO (${hours_ago}h sem heartbeat)"
            dead_agents=$((dead_agents + 1))
            
            # Criar alerta
            local alert_file="$MAKAN72_HOME/04-bus/alerts/${agent}_dead_alert.json"
            cat > "$alert_file" << EOF
{
  "type": "agent_dead",
  "agent": "$agent",
  "timestamp": "$(portable_date_iso)",
  "message": "Agente $agent sem heartbeat há ${hours_ago}h"
}
EOF
        else
            echo "  ✅ $agent: VIVO (${hours_ago}h atrás)"
        fi
    done
    
    if [[ $dead_agents -gt 0 ]]; then
        echo "ALERTA: $dead_agents agente(s) morto(s)!"
    else
        echo "Todos os agentes estão vivos"
    fi
}

heartbeat_status() {
    local alive=0
    local dead=0
    local now
    now=$(date +%s)
    local ttl_seconds=$((HEARTBEAT_TTL_HOURS * 3600))
    
    for hb_file in "$MAKAN72_HOME/04-bus/heartbeat"/*_heartbeat.json; do
        [[ -f "$hb_file" ]] || continue
        local timestamp
        timestamp=$(jq -r '.timestamp // empty' "$hb_file" 2>/dev/null)
        if [[ -n "$timestamp" ]]; then
            local agent_time
            agent_time=$(portable_date_parse "$timestamp" 2>/dev/null || echo "0")
            if [[ $((now - agent_time)) -gt $ttl_seconds ]]; then
                dead=$((dead + 1))
            else
                alive=$((alive + 1))
            fi
        fi
    done
    
    echo "heartbeat: enabled=$HEARTBEAT_ENABLED, alive=$alive, dead=$dead"
}
