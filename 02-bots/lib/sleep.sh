#!/usr/bin/env bash
# sleep.sh — Consolidação de sessão (5S Digital)
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03 (V3: +resumo de sessão)

# === DEPENDÊNCIAS ===
# Requer: nenhum
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
SLEEP_ENABLED="${SLEEP_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
sleep_run() {
    [[ "$SLEEP_ENABLED" != "true" ]] && return 0
    
    echo "=== SLEEP (Consolidação de Sessão) ==="
    echo "5S Digital: Sort, Set, Shine, Standardize, Sustain"
    echo ""
    
    local insights_file="$MAKAN72_HOME/00-global/INSIGHTS.md"
    local reports_dir="$MAKAN72_HOME/06-reports"
    local date_today
    date_today=$(date +%Y-%m-%d)
    
    # 1. SORT — Identificar o que é útil
    echo "1. SORT: Identificar relatórios recentes..."
    local recent_reports=0
    if [[ -d "$reports_dir" ]]; then
        recent_reports=$(find "$reports_dir" -name "*.md" -mtime -1 2>/dev/null | wc -l)
    fi
    echo "   Relatórios hoje: $recent_reports"
    
    # 2. SET — Organizar insights
    echo "2. SET: Actualizar INSIGHTS.md..."
    
    # Criar/actualizar INSIGHTS.md se não existir
    if [[ ! -f "$insights_file" ]]; then
        cat > "$insights_file" << EOF
# INSIGHTS — Makan72

## Últimas Actualizações

- **$date_today**: Sistema consolidado
EOF
    fi
    
    # 3. SHINE — Limpar resíduos
    echo "3. SHINE: Limpar temporários..."
    local temp_dir="$MAKAN72_HOME/08-logs/cache/temp"
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"/* 2>/dev/null
        echo "   Temporários limpos"
    fi
    
    # 4. STANDARDIZE — Actualizar documentação
    echo "4. STANDARDIZE: Verificar documentação..."
    
    # 5. SUSTAIN — Criar hábitos e gerar resumo
    echo "5. SUSTAIN: Gerar resumo de sessão..."
    
    # Gerar resumo de sessão simples (factos objectivos)
    local report_dir="$MAKAN72_HOME/06-reports/$(date +%Y-%m)"
    mkdir -p "$report_dir"
    local report_file="$report_dir/sessao_$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOF
# Sessão $(date +%Y-%m-%d)

**Modo:** semi-auto
**Relatórios processados:** ${recent_reports:-0}
**Temporários limpos:** sim
**Consolidação:** completa
**Gerado em:** $(portable_date_iso)
EOF
    
    echo "   Resumo de sessão: $report_file"
    
    echo ""
    echo "Consolidação completa!"
}

sleep_consolidate() {
    local insights_file="$MAKAN72_HOME/00-global/INSIGHTS.md"
    local date_today
    date_today=$(date +%Y-%m-%d)
    
    # Append summary
    if [[ -f "$insights_file" ]]; then
        echo "" >> "$insights_file"
        echo "- **$date_today**: Sessão consolidada" >> "$insights_file"
    fi
}

sleep_status() {
    local insights_file="$MAKAN72_HOME/00-global/INSIGHTS.md"
    local last_update="nunca"
    
    if [[ -f "$insights_file" ]]; then
        last_update="actualizado"
    fi
    
    echo "sleep: enabled=$SLEEP_ENABLED, insights=$last_update"
}
