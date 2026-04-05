#!/usr/bin/env bash
# visualizer.sh — Gerar visualização do estado do sistema
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: jq
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
VISUALIZER_ENABLED="${VISUALIZER_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
visualizer_run() {
    [[ "$VISUALIZER_ENABLED" != "true" ]] && return 0
    
    echo "=== MAKAN72 SYSTEM VISUALIZER ==="
    echo ""
    
    # 1. Agentes
    echo "┌─────────────────────────────────────────────┐"
    echo "│ AGENTES                                     │"
    echo "├─────────────────────────────────────────────┤"
    
    local agents_file="$MAKAN72_HOME/01-config/agents.json"
    if [[ -f "$agents_file" ]]; then
        jq -r '.agents[] | "│ \(.code): \(.status) (\(.model))"' "$agents_file" 2>/dev/null | head -10
    else
        echo "│ agents.json não encontrado"
    fi
    echo "└─────────────────────────────────────────────┘"
    echo ""
    
    # 2. Tarefas por agente
    echo "┌─────────────────────────────────────────────┐"
    echo "│ TAREFAS POR AGENTE                          │"
    echo "├─────────────────────────────────────────────┤"
    
    local inbox_dir="$MAKAN72_HOME/03-inbox"
    if [[ -d "$inbox_dir" ]]; then
        for agent_dir in "$inbox_dir"/*/; do
            [[ -d "$agent_dir" ]] || continue
            local agent
            agent=$(basename "$agent_dir")
            [[ "$agent" == "archive" ]] && continue
            
            local pending in_progress done
            pending=$(find "$agent_dir/pending" -name "*.md" 2>/dev/null | wc -l)
            in_progress=$(find "$agent_dir/in_progress" -name "*.md" 2>/dev/null | wc -l)
            done_count=$(find "$agent_dir/done" -name "*.md" 2>/dev/null | wc -l)
            
            printf "│ %-10s │ pend: %2d │ prog: %2d │ done: %2d │\n" "$agent" "$pending" "$in_progress" "$done_count"
        done
    fi
    echo "└─────────────────────────────────────────────┘"
    echo ""
    
    # 3. Handoffs
    echo "┌─────────────────────────────────────────────┐"
    echo "│ HANDOFFS                                    │"
    echo "├─────────────────────────────────────────────┤"
    
    local handoff_dir="$MAKAN72_HOME/04-bus/handoff"
    local handoff_pending=0
    if [[ -d "$handoff_dir" ]]; then
        handoff_pending=$(find "$handoff_dir" -name "*.json" ! -name "*.read" 2>/dev/null | wc -l)
    fi
    echo "│ Pendentes: $handoff_pending"
    echo "└─────────────────────────────────────────────┘"
    echo ""
    
    # 4. Alertas
    echo "┌─────────────────────────────────────────────┐"
    echo "│ ALERTAS ACTIVOS                             │"
    echo "├─────────────────────────────────────────────┤"
    
    local alerts_dir="$MAKAN72_HOME/04-bus/alerts"
    local alerts_count=0
    if [[ -d "$alerts_dir" ]]; then
        alerts_count=$(find "$alerts_dir" -name "*.json" 2>/dev/null | wc -l)
    fi
    echo "│ Total: $alerts_count"
    echo "└─────────────────────────────────────────────┘"
    echo ""
    
    echo "=== FIM DA VISUALIZAÇÃO ==="
}

visualizer_generate() {
    local reports_dir="$MAKAN72_HOME/06-reports"
    local output_d2="$reports_dir/system_$(date +%Y%m%d).d2"
    local output_mmd="$reports_dir/system_$(date +%Y%m%d).mmd"
    
    # Gerar D2 (simplificado)
    cat > "$output_d2" << 'EOF'
# Makan72 System Diagram
agents: {
  shape: class
}
bus: {
  shape: class
}
agents -> bus: heartbeat/status
EOF
    
    # Gerar Mermaid (simplificado)
    cat > "$output_mmd" << 'EOF'
graph TD
    A[Agentes] --> B[04-bus]
    B --> C[Heartbeat]
    B --> D[Status]
    B --> E[Handoff]
EOF
    
    echo "Diagramas gerados:"
    echo "  D2: $output_d2"
    echo "  Mermaid: $output_mmd"
}

visualizer_status() {
    echo "visualizer: enabled=$VISUALIZER_ENABLED"
}
