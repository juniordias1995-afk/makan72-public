#!/usr/bin/env bash
# guardrails.sh — Verificar limites e guardrails
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: jq, yq (opcional)
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
GUARDRAILS_ENABLED="${GUARDRAILS_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
guardrails_run() {
    [[ "$GUARDRAILS_ENABLED" != "true" ]] && return 0
    
    echo "=== GUARDRAILS CHECK ==="
    
    local guardrails_file="$MAKAN72_HOME/01-config/GUARDRAILS.yaml"
    
    if [[ ! -f "$guardrails_file" ]]; then
        echo "WARNING: GUARDRAILS.yaml não encontrado"
        echo "A usar valores padrão"
        
        # Valores padrão
        local max_files_modified=10
        local max_files_created=20
        local max_lines_changed=500
    else
        # Ler valores do GUARDRAILS.yaml
        local max_files_modified max_files_created max_lines_changed
        max_files_modified=$(grep "max_files_modified:" "$guardrails_file" | head -1 | awk '{print $2}' || echo "10")
        max_files_created=$(grep "max_files_created:" "$guardrails_file" | head -1 | awk '{print $2}' || echo "20")
        max_lines_changed=$(grep "max_lines_changed:" "$guardrails_file" | head -1 | awk '{print $2}' || echo "500")
    fi
    
    echo "Limites configurados:"
    echo "  max_files_modified: $max_files_modified"
    echo "  max_files_created: $max_files_created"
    echo "  max_lines_changed: $max_lines_changed"
    echo ""
    echo "Para verificar uma proposta: guardrails_check <ficheiro_proposta>"
}

guardrails_check() {
    local proposal_file="$1"
    
    if [[ ! -f "$proposal_file" ]]; then
        echo "REJEITADO: Ficheiro de proposta não existe"
        return 1
    fi
    
    local guardrails_file="$MAKAN72_HOME/01-config/GUARDRAILS.yaml"
    local max_files_modified=10
    local max_files_created=20
    local max_lines_changed=500
    
    # Ler limites se existir
    if [[ -f "$guardrails_file" ]]; then
        max_files_modified=$(grep "max_files_modified:" "$guardrails_file" | head -1 | awk '{print $2}' || echo "10")
        max_files_created=$(grep "max_files_created:" "$guardrails_file" | head -1 | awk '{print $2}' || echo "20")
        max_lines_changed=$(grep "max_lines_changed:" "$guardrails_file" | head -1 | awk '{print $2}' || echo "500")
    fi
    
    # Contar linhas do ficheiro
    local lines_count
    lines_count=$(wc -l < "$proposal_file" 2>/dev/null || echo "0")
    
    # Verificar extensão
    local ext="${proposal_file##*.}"
    local allowed_extensions="md sh yaml json py js ts"
    
    if [[ ! " $allowed_extensions " =~ " $ext " ]]; then
        echo "REJEITADO: Extensão .$ext não permitida"
        return 1
    fi
    
    # Verificar se é ficheiro protegido
    local protected_paths="00-global/VERDADE.md 00-global/VACINAS.md"
    if [[ " $protected_paths " =~ "$proposal_file" ]]; then
        echo "REJEITADO: Ficheiro protegido não pode ser modificado"
        return 1
    fi
    
    # Verificar limites
    if [[ $lines_count -gt $max_lines_changed ]]; then
        echo "REJEITADO: $lines_count linhas excede limite de $max_lines_changed"
        return 1
    fi
    
    echo "APROVADO: Ficheiro dentro dos limites"
    return 0
}

guardrails_status() {
    local guardrails_file="$MAKAN72_HOME/01-config/GUARDRAILS.yaml"
    local config_status="não encontrado"
    
    if [[ -f "$guardrails_file" ]]; then
        config_status="configurado"
    fi
    
    echo "guardrails: enabled=$GUARDRAILS_ENABLED, config=$config_status"
}
