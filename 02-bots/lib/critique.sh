#!/usr/bin/env bash
# critique.sh — Verificar CRITIQUE.md em tarefas concluídas
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: nenhum
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
CRITIQUE_ENABLED="${CRITIQUE_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
critique_run() {
    [[ "$CRITIQUE_ENABLED" != "true" ]] && return 0
    
    echo "=== CRITIQUE CHECK ==="
    
    local inbox_dir="$MAKAN72_HOME/03-inbox"
    local total_tasks=0
    local missing_critique=0
    
    if [[ ! -d "$inbox_dir" ]]; then
        echo "WARNING: Pasta inbox não existe"
        return 0
    fi
    
    # Verificar cada agente
    for agent_dir in "$inbox_dir"/*/; do
        [[ -d "$agent_dir" ]] || continue
        local agent
        agent=$(basename "$agent_dir")
        
        # Ignorar pastas especiais
        [[ "$agent" == "archive" || "$agent" == "ceo" ]] && continue
        
        local done_dir="$agent_dir/done"
        if [[ -d "$done_dir" ]]; then
            for task_file in "$done_dir"/*.md; do
                [[ -f "$task_file" ]] || continue
                total_tasks=$((total_tasks + 1))
                
                # Verificar se tem CRITIQUE.md na mesma pasta
                local task_dir
                task_dir=$(dirname "$task_file")
                local critique_file="$task_dir/CRITIQUE.md"
                
                if [[ ! -f "$critique_file" ]]; then
                    echo "  ⚠️  $task_file: Sem CRITIQUE.md"
                    missing_critique=$((missing_critique + 1))
                fi
            done
        fi
    done
    
    echo ""
    echo "Total tarefas em done/: $total_tasks"
    echo "Faltando CRITIQUE.md: $missing_critique"
    
    if [[ $missing_critique -gt 0 ]]; then
        echo "ACÇÃO: Criar CRITIQUE.md para tarefas listadas"
    else
        echo "✅ Todas as tarefas têm CRITIQUE.md"
    fi
}

critique_check() {
    local task_dir="$1"
    
    if [[ ! -d "$task_dir" ]]; then
        echo "REJEITADO: Pasta da tarefa não existe"
        return 1
    fi
    
    local critique_file="$task_dir/CRITIQUE.md"
    
    if [[ ! -f "$critique_file" ]]; then
        echo "REJEITADO: CRITIQUE.md não encontrado"
        return 1
    fi
    
    # Verificar se CRITIQUE.md tem conteúdo
    local lines
    lines=$(wc -l < "$critique_file" 2>/dev/null || echo "0")
    if [[ $lines -lt 5 ]]; then
        echo "AVISO: CRITIQUE.md muito curto ($lines linhas)"
    fi
    
    echo "APROVADO: CRITIQUE.md encontrado"
    return 0
}

critique_status() {
    local inbox_dir="$MAKAN72_HOME/03-inbox"
    local missing=0
    
    if [[ -d "$inbox_dir" ]]; then
        for agent_dir in "$inbox_dir"/*/done/; do
            [[ -d "$agent_dir" ]] || continue
            for task_file in "$agent_dir"/*.md; do
                [[ -f "$task_file" ]] || continue
                local task_dir critique_file
                task_dir=$(dirname "$task_file")
                critique_file="$task_dir/CRITIQUE.md"
                if [[ ! -f "$critique_file" ]]; then
                    missing=$((missing + 1))
                fi
            done
        done
    fi
    
    echo "critique: enabled=$CRITIQUE_ENABLED, missing_critique=$missing"
}
