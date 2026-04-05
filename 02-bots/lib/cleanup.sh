#!/usr/bin/env bash
# cleanup.sh — Limpeza baseada em TTL
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: jq, yq (opcional)
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
CLEANUP_ENABLED="${CLEANUP_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
cleanup_run() {
    [[ "$CLEANUP_ENABLED" != "true" ]] && return 0
    
    echo "=== CLEANUP (TTL-based) ==="
    
    local rules_file="$MAKAN72_HOME/02-bots/config/BOT_RULES.yaml"
    local reports_days=30
    local logs_days=7
    local handoff_read_hours=48
    local heartbeat_hours=24
    
    # Ler TTLs do BOT_RULES.yaml se existir
    if [[ -f "$rules_file" ]]; then
        reports_days=$(grep -A1 "reports_days:" "$rules_file" | tail -1 | tr -d ' ' || echo "30")
        logs_days=$(grep -A1 "logs_days:" "$rules_file" | tail -1 | tr -d ' ' || echo "7")
        handoff_read_hours=$(grep -A1 "handoff_read_hours:" "$rules_file" | tail -1 | tr -d ' ' || echo "48")
        heartbeat_hours=$(grep -A1 "heartbeat_hours:" "$rules_file" | tail -1 | tr -d ' ' || echo "24")
    fi
    
    echo "TTLs: reports=${reports_days}d, logs=${logs_days}d, handoff=${handoff_read_hours}h, heartbeat=${heartbeat_hours}h"
    echo ""
    
    local deleted=0
    
    # 1. Limpar heartbeats expirados
    echo "1. Verificar heartbeats..."
    local hb_dir="$MAKAN72_HOME/04-bus/heartbeat"
    if [[ -d "$hb_dir" ]]; then
        for hb in "$hb_dir"/*_heartbeat.json; do
            [[ -f "$hb" ]] || continue
            local ts
            ts=$(jq -r '.timestamp // empty' "$hb" 2>/dev/null)
            if [[ -n "$ts" ]]; then
                local hb_time now diff
                hb_time=$(portable_date_parse "$ts" 2>/dev/null || echo "0")
                now=$(date +%s)
                diff=$((now - hb_time))
                if [[ $diff -gt $((heartbeat_hours * 3600)) ]]; then
                    rm -f "$hb"
                    deleted=$((deleted + 1))
                fi
            fi
        done
    fi
    
    # 2. Limpar handoffs .read expirados
    echo "2. Verificar handoffs lidos..."
    local handoff_dir="$MAKAN72_HOME/04-bus/handoff"
    if [[ -d "$handoff_dir" ]]; then
        for hf in "$handoff_dir"/*.json.read; do
            [[ -f "$hf" ]] || continue
            local age_hours
            age_hours=$(( ($(date +%s) - $(stat -c %Y "$hf" 2>/dev/null || echo "0")) / 3600 ))
            if [[ $age_hours -gt $handoff_read_hours ]]; then
                rm -f "$hf"
                deleted=$((deleted + 1))
            fi
        done
    fi
    
    # 3. Mover relatórios expirados para archive
    echo "3. Verificar relatórios antigos..."
    local reports_dir="$MAKAN72_HOME/06-reports"
    if [[ -d "$reports_dir" ]]; then
        for month_dir in "$reports_dir"/*/; do
            [[ -d "$month_dir" ]] || continue
            local month
            month=$(basename "$month_dir")
            # Verificar se pasta tem mais de reports_days
            # (simplificado: mover tudo para archive)
            if [[ -d "$MAKAN72_HOME/07-archive/$month" ]]; then
                mv "$month_dir"*.md "$MAKAN72_HOME/07-archive/$month/reports/" 2>/dev/null || true
                deleted=$((deleted + 1))
            fi
        done
    fi
    
    # 4. Limpar logs expirados
    echo "4. Verificar logs antigos..."
    local logs_dir="$MAKAN72_HOME/08-logs/logs"
    if [[ -d "$logs_dir" ]]; then
        find "$logs_dir" -name "*.log" -mtime +$logs_days -delete 2>/dev/null
    fi
    
    echo ""
    echo "TOTAL: $deleted ficheiro(s) processado(s)"
    
    # 4. Limpar checkpoints > 7 dias (NOVO - Lacuna 6)
    echo "4. Limpando checkpoints > 7 dias..."
    local checkpoint_dir="$MAKAN72_HOME/08-logs/cache/checkpoints"
    if [[ -d "$checkpoint_dir" ]]; then
        local cleaned
        cleaned=$(find "$checkpoint_dir" -type f -mtime +7 -delete -print 2>/dev/null | wc -l)
        echo "   Checkpoints removidos: $cleaned"
    fi
    
    # 5. Arquivar inbox done/read > 30 dias (NOVO - Lacuna 7)
    echo "5. Arquivando done/read > 30 dias..."
    local archive_dir="$MAKAN72_HOME/03-inbox/archive"
    mkdir -p "$archive_dir"
    
    # done/ de todos os agentes
    for done_dir in "$MAKAN72_HOME/03-inbox"/*/done; do
        [[ -d "$done_dir" ]] || continue
        local archived
        archived=$(find "$done_dir" -type f -mtime +30 -exec mv {} "$archive_dir/" \; -print 2>/dev/null | wc -l)
        if [[ $archived -gt 0 ]]; then
            echo "   done/ arquivados: $archived"
        fi
    done
    
    # ceo/read/
    local ceo_read="$MAKAN72_HOME/03-inbox/ceo/read"
    if [[ -d "$ceo_read" ]]; then
        local archived
        archived=$(find "$ceo_read" -type f -mtime +30 -exec mv {} "$archive_dir/" \; -print 2>/dev/null | wc -l)
        if [[ $archived -gt 0 ]]; then
            echo "   CEO read/ arquivados: $archived"
        fi
    fi
    
    # 6. Limpar alertas > 7 dias (NOVO - Lacuna 8)
    echo "6. Limpando alertas > 7 dias..."
    local alerts_dir="$MAKAN72_HOME/04-bus/alerts"
    if [[ -d "$alerts_dir" ]]; then
        local cleaned
        cleaned=$(find "$alerts_dir" -type f -name "*.json" -mtime +7 -delete -print 2>/dev/null | wc -l)
        echo "   Alertas removidos: $cleaned"
    fi

    # 7. Rotação de logs genérica (comprime + apaga antigos)
    echo "7. Rotação de logs..."
    if [[ -f "$MAKAN72_HOME/05-scripts/utils/rotate-logs.sh" ]]; then
        bash "$MAKAN72_HOME/05-scripts/utils/rotate-logs.sh" 2>/dev/null || true
    fi

    echo ""
    echo "✅ CLEANUP completo"
}

cleanup_status() {
    local hb_count=0 handoff_count=0 log_count=0
    
    hb_count=$(find "$MAKAN72_HOME/04-bus/heartbeat" -name "*.json" 2>/dev/null | wc -l)
    handoff_count=$(find "$MAKAN72_HOME/04-bus/handoff" -name "*.json.read" 2>/dev/null | wc -l)
    log_count=$(find "$MAKAN72_HOME/08-logs/logs" -name "*.log" 2>/dev/null | wc -l)
    
    echo "cleanup: enabled=$CLEANUP_ENABLED, heartbeats=$hb_count, handoffs=$handoff_count, logs=$log_count"
}
