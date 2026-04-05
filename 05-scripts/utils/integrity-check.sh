#!/usr/bin/env bash
# integrity-check.sh — Verificar integridade de ficheiros sagrados (SHA256)
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
CACHE_DIR="$MAKAN72_HOME/08-logs/cache"
HASH_FILE="$CACHE_DIR/integrity.sha256"

# Ficheiros sagrados a proteger
SACRED_FILES=(
    "00-global/VERDADE.md"
    "00-global/VACINAS.md"
    "00-global/VISAO_MAKAN72.md"
    "01-config/agents.json"
    "01-config/team.yaml"
    "01-config/GUARDRAILS.yaml"
    "VERSION"
)

mkdir -p "$CACHE_DIR"

show_help() {
    cat << 'EOF'
Uso: integrity-check.sh [MODO]

MODOS:
  update   Gerar hashes SHA256 dos ficheiros sagrados
  verify   Verificar se hashes actuais coincidem com guardados
  --help   Mostrar esta ajuda
EOF
}

generate_hashes() {
    echo "🔐 Gerando hashes de integridade..."
    > "$HASH_FILE"
    
    local count=0
    for file in "${SACRED_FILES[@]}"; do
        local path="$MAKAN72_HOME/$file"
        if [[ -f "$path" ]]; then
            local hash
            hash=$(sha256sum "$path" | cut -d' ' -f1)
            echo "$hash  $file" >> "$HASH_FILE"
            echo "  ✅ $file"
            count=$((count + 1))
        else
            echo "  ⚠️  $file (não encontrado)"
        fi
    done
    
    echo "✅ Hashes gerados: $count ficheiros"
    echo "   Guardado em: $HASH_FILE"
}

verify_hashes() {
    echo "🔍 Verificando integridade..."
    
    if [[ ! -f "$HASH_FILE" ]]; then
        echo "❌ Ficheiro de hashes não existe: $HASH_FILE"
        echo "   Execute: integrity-check.sh update"
        exit 1
    fi
    
    local ok=0
    local fail=0
    local missing=0
    
    while IFS= read -r line; do
        local stored_hash="${line%%  *}"
        local file="${line#*  }"
        local path="$MAKAN72_HOME/$file"
        
        if [[ ! -f "$path" ]]; then
            echo "  ❌ $file (ficheiro não encontrado)"
            missing=$((missing + 1))
            continue
        fi
        
        local current_hash
        current_hash=$(sha256sum "$path" | cut -d' ' -f1)
        
        if [[ "$stored_hash" == "$current_hash" ]]; then
            echo "  ✅ $file"
            ok=$((ok + 1))
        else
            echo "  ❌ $file (INTEGRIDADE COMPROMETIDA)"
            echo "     Esperado: $stored_hash"
            echo "     Actual:   $current_hash"
            fail=$((fail + 1))
        fi
    done < "$HASH_FILE"
    
    echo ""
    echo "=== RESULTADO ==="
    echo "  OK:       $ok"
    echo "  Falhou:   $fail"
    echo "  Missing:  $missing"
    
    if [[ $fail -gt 0 ]]; then
        echo ""
        echo "❌ INTEGRIDADE COMPROMETIDA"
        return 1
    elif [[ $missing -gt 0 ]]; then
        echo ""
        echo "⚠️  Ficheiros em falta"
        return 1
    else
        echo ""
        echo "✅ INTEGRIDADE: OK"
        return 0
    fi
}

# Main
CMD="${1:-}"

case "$CMD" in
    update)
        generate_hashes
        ;;
    verify)
        verify_hashes
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    "")
        echo "Uso: integrity-check.sh [update|verify|--help]"
        exit 1
        ;;
    *)
        echo "❌ Modo desconhecido: $CMD"
        show_help
        exit 1
        ;;
esac
