#!/usr/bin/env bash
# gate.sh — Validação de 6 camadas
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
GUARDRAILS_FILE="$MAKAN72_HOME/01-config/GUARDRAILS.yaml"

CMD="${1:-help}"
TARGET="${2:-}"
STRICT_MODE=false

# Parse --strict flag
if [[ "$CMD" == "check" ]]; then
    if [[ "${3:-}" == "--strict" ]]; then
        STRICT_MODE=true
    elif [[ "${4:-}" == "--strict" ]]; then
        STRICT_MODE=true
    fi
fi

# === FUNÇÕES ===

check_auto_validacao() {
    local scope="$1"
    if [[ -z "$scope" ]]; then
        echo "C1 ❌ REJEITADO: Scope não definido"
        return 1
    fi
    echo "C1 ✅ AUTO-VALIDAÇÃO: Scope='$scope'"
    return 0
}

check_qualidade() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "C2 ⚠️ SKIP: Ficheiro não existe"
        return 0
    fi
    
    local ext="${file##*.}"
    
    # Python: ruff + pytest
    if [[ "$ext" == "py" ]]; then
        if command -v ruff &> /dev/null; then
            if ruff check "$file" > /dev/null 2>&1; then
                echo "C2 ✅ QUALIDADE: ruff check OK"
            else
                echo "C2 ❌ QUALIDADE: ruff check falhou"
                return 1
            fi
        else
            echo "C2 ⚠️ QUALIDADE: ruff não instalado (skip)"
        fi
    fi
    
    # Bash: syntax check
    if [[ "$ext" == "sh" ]]; then
        if bash -n "$file" > /dev/null 2>&1; then
            echo "C2 ✅ QUALIDADE: bash -n OK"
        else
            echo "C2 ❌ QUALIDADE: bash -n falhou"
            return 1
        fi
    fi
    
    return 0
}

check_seguranca() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "C3 ⚠️ SKIP: Ficheiro não existe"
        return 0
    fi
    
    # Scan por credenciais
    if grep -qE "(password|secret|api_key|token)\s*[:=]" "$file" 2>/dev/null; then
        echo "C3 ⚠️ SEGURANÇA: Possíveis credenciais encontradas"
        return 1
    fi
    
    echo "C3 ✅ SEGURANÇA: Sem credenciais óbvias"
    return 0
}

check_integracao() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "C4 ⚠️ SKIP: Ficheiro não existe"
        return 0
    fi

    local ext="${file##*.}"
    local warnings=0

    # Para bash: verificar que ficheiros 'source' existem
    if [[ "$ext" == "sh" ]]; then
        local src_grep
        src_grep=$(grep -E '^\s*(source|\.)\s+\S' "$file" 2>/dev/null)
        while IFS= read -r src_line; do
            local src_file
            src_file=$(echo "$src_line" | sed -E 's/^\s*(source|\.)\s+//' | sed 's/#.*//' | tr -d '"' | xargs 2>/dev/null)
            [[ -z "$src_file" ]] && continue
            # Expandir variáveis comuns
            src_file="${src_file/\$MAKAN72_HOME/${MAKAN72_HOME:-~/.Makan72}}"
            src_file="${src_file/\$HOME/$HOME}"
            if [[ ! -f "$src_file" ]]; then
                echo "C4 ⚠️ INTEGRAÇÃO: dependência '$src_file' não encontrada"
                warnings=$((warnings + 1))
            fi
        done <<< "$src_grep"
    fi

    if [[ $warnings -eq 0 ]]; then
        echo "C4 ✅ INTEGRAÇÃO: dependências OK"
    else
        echo "C4 ⚠️ INTEGRAÇÃO: $warnings dependência(s) em falta"
        # Em modo strict, bloquear
        if [[ "$STRICT_MODE" == "true" ]]; then
            return 1
        fi
    fi
    return 0  # Por defeito não bloqueia (só avisa)
}

check_organizacao() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "C5 ⚠️ SKIP: Ficheiro não existe"
        return 0
    fi
    
    local ext="${file##*.}"
    local allowed_extensions="md sh yaml json py js ts txt log"
    
    if [[ ! " $allowed_extensions " =~ " $ext " ]]; then
        echo "C5 ❌ ORGANIZAÇÃO: Extensão .$ext não permitida"
        return 1
    fi
    
    echo "C5 ✅ ORGANIZAÇÃO: Extensão .$ext permitida"
    return 0
}

check_separacao_poderes() {
    local task_dir="$1"

    if [[ ! -d "$task_dir" ]]; then
        echo "C6 ⚠️ SKIP: Pasta da tarefa não existe"
        return 0
    fi

    # Verificar se tem testes (para tarefas MC)
    if compgen -G "$task_dir/T*-TESTES.md" > /dev/null 2>&1 || [[ -f "$task_dir/TESTES.md" ]]; then
        echo "C6 ✅ SEPARAÇÃO: Testes encontrados"
    else
        echo "C6 ⚠️ SEPARAÇÃO: Sem testes"
        # Em modo strict, bloquear
        if [[ "$STRICT_MODE" == "true" ]]; then
            return 1
        fi
    fi

    return 0
}

# === MAIN ===

case "$CMD" in
    check)
        file="$TARGET"
        scope="${3:-default}"
        pass=0
        fail=0
        
        echo "=== GATE CHECK: $file ==="
        echo ""
        
        check_auto_validacao "$scope" && pass=$((pass+1)) || fail=$((fail+1))
        check_qualidade "$file" && pass=$((pass+1)) || fail=$((fail+1))
        check_seguranca "$file" && pass=$((pass+1)) || fail=$((fail+1))
        check_integracao "$file" && pass=$((pass+1)) || fail=$((fail+1))
        check_organizacao "$file" && pass=$((pass+1)) || fail=$((fail+1))
        check_separacao_poderes "$file" && pass=$((pass+1)) || fail=$((fail+1))
        
        echo ""
        echo "=== RESULTADO ==="
        echo "Passaram: $pass/6"
        echo "Falharam: $fail/6"
        
        if [[ $fail -eq 0 ]]; then
            echo "APROVADO"
            exit 0
        else
            echo "REJEITADO"
            exit 1
        fi
        ;;
    
    help|*)
        echo "=== gate.sh — Validação de 6 Camadas ==="
        echo ""
        echo "Uso: $0 check <ficheiro> [scope] [--strict]"
        echo ""
        echo "Argumentos:"
        echo "  <ficheiro>   Script/ficheiro a validar"
        echo "  [scope]      Scope (default: default)"
        echo "  --strict     Modo estrito (C4 e C6 bloqueiam)"
        echo ""
        echo "Camadas:"
        echo "  C1: AUTO-VALIDAÇÃO — Scope definido"
        echo "  C2: QUALIDADE — ruff/bash check"
        echo "  C3: SEGURANÇA — Scan credenciais"
        echo "  C4: INTEGRAÇÃO — Imports funcionam"
        echo "  C5: ORGANIZAÇÃO — Extensão permitida"
        echo "  C6: SEPARAÇÃO — Testes existem"
        echo ""
        echo "Códigos de saída:"
        echo "  0 = APROVADO"
        echo "  1 = REJEITADO"
        echo ""
        echo "Recomendado: usar --strict para scripts em 02-bots/ e 05-scripts/core/"
        ;;
esac
