# NOTA: Referências a ~/.team/ são INTENCIONAIS (script de migração)

#!/usr/bin/env bash
# migrate-from-team.sh — Migrar de ~/.team/ para ~/.Makan72/
set -euo pipefail

OLD_HOME="${HOME}/.team"
NEW_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Migração: ~/.team/ → ~/.Makan72/                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Verificar origem
if [[ ! -d "$OLD_HOME" ]]; then
    echo "❌ ~/.team/ não encontrado"
    exit 1
fi

# Verificar destino
if [[ ! -d "$NEW_HOME" ]]; then
    echo "❌ ~/.Makan72/ não inicializado"
    echo "   Execute: setup.sh primeiro"
    exit 1
fi

echo "Origem: $OLD_HOME"
echo "Destino: $NEW_HOME"
echo ""

# Mapeamento de pastas
declare -A MAPPING=(
    ["memory/TRUTH.md"]="00-global/VERDADE.md"
    ["memory/VACCINES.md"]="00-global/VACINAS.md"
    ["workspace/cvs/"]="00-global/cvs/"
    ["inbox/"]="03-inbox/"
    ["bus/"]="04-bus/"
    ["reports/"]="06-reports/"
    ["config/"]="01-config/"
)

echo "Mapeamento:"
for src in "${!MAPPING[@]}"; do
    echo "  $src → ${MAPPING[$src]}"
done
echo ""

# Confirmar
read -p "Continuar? (s/N): " confirm
if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo "❌ Migração cancelada"
    exit 0
fi

# Copiar ficheiros
echo "📋 Copiando ficheiros..."
for src in "${!MAPPING[@]}"; do
    src_path="$OLD_HOME/$src"
    dst_path="$NEW_HOME/${MAPPING[$src]}"
    
    if [[ -e "$src_path" ]]; then
        echo "  $src → ${MAPPING[$src]}"
        cp -r "$src_path" "$dst_path" 2>/dev/null || true
    fi
done

echo ""
echo "✅ Migração completa!"
echo "   Execute: verify-migration.sh para validar"
