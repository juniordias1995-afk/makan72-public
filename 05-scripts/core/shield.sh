#!/usr/bin/env bash
# shield.sh — Escudo de Segurança (read-only para ficheiros sagrados)
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

# Carregar log de operacoes
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
fi

SACRED_TARGETS=(
    "00-global/"
    "01-config/"
    "README.md"
    "VERSION"
    "setup.sh"
)

lock_shield() {
    echo "🔒 Escudo de Segurança ACTIVADO"
    
    # Guardar permissões originais
    local perms_file="$MAKAN72_HOME/08-logs/cache/shield_perms.txt"
    mkdir -p "$(dirname "$perms_file")"
    > "$perms_file"
    
    for target in "${SACRED_TARGETS[@]}"; do
        local path="$MAKAN72_HOME/$target"
        if [[ -e "$path" ]]; then
            # Guardar permissões actuais
            if [[ -d "$path" ]]; then
                find "$path" -type f -exec stat -c "%n %a" {} \; >> "$perms_file" 2>/dev/null
            else
                stat -c "%n %a" "$path" >> "$perms_file" 2>/dev/null
            fi
            
            chmod -R a-w "$path" 2>/dev/null || true
            echo "  ✅ Protegido: $target"
        fi
    done
    echo "🛡️  Ficheiros sagrados em READ-ONLY"
    echo "   Permissões guardadas em: $perms_file"
    
    # Registar operacao
    if type log_operation &>/dev/null; then
        log_operation "shield-lock" "system" "OK" "targets=${#SACRED_TARGETS[@]}"
    fi
}

unlock_shield() {
    echo "🔓 Escudo DESACTIVADO"
    
    # Restaurar permissões originais
    local perms_file="$MAKAN72_HOME/08-logs/cache/shield_perms.txt"
    
    if [[ -f "$perms_file" ]]; then
        echo "📋 Restaurando permissões originais..."
        while IFS= read -r line; do
            local file="${line%% *}"
            local perms="${line##* }"
            if [[ -e "$file" ]]; then
                chmod "$perms" "$file" 2>/dev/null || true
            fi
        done < "$perms_file"
        echo "   ✅ Permissões restauradas"
    else
        echo "   ⚠️  Sem permissões guardadas (usando padrão)"
        for target in "${SACRED_TARGETS[@]}"; do
            local path="$MAKAN72_HOME/$target"
            if [[ -e "$path" ]]; then
                if [[ -d "$path" ]]; then
                    chmod -R u+w,a+rX "$path" 2>/dev/null || true
                else
                    chmod u+w,a+r "$path" 2>/dev/null || true
                fi
            fi
        done
    fi
    
    for target in "${SACRED_TARGETS[@]}"; do
        local path="$MAKAN72_HOME/$target"
        if [[ -e "$path" ]]; then
            echo "  ✅ Desbloqueado: $target"
        fi
    done
    echo "⚠️  CEO tem permissões totais"
    
    # Registar operacao
    if type log_operation &>/dev/null; then
        log_operation "shield-unlock" "system" "OK" "targets=${#SACRED_TARGETS[@]}"
    fi
}

status_shield() {
    local truth="$MAKAN72_HOME/00-global/VERDADE.md"
    if [[ -f "$truth" ]]; then
        if [[ -w "$truth" ]]; then
            echo "🔴 ESCUDO DESLIGADO"
        else
            echo "🟢 ESCUDO LIGADO"
        fi
    else
        echo "❓ VERDADE.md não encontrado"
    fi
}

case "${1:-help}" in
    lock) lock_shield ;;
    unlock) unlock_shield ;;
    status) status_shield ;;
    *) echo "Uso: shield.sh [lock|unlock|status]" ;;
esac
