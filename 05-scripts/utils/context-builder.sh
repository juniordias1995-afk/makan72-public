#!/usr/bin/env bash
# context-builder.sh — Compilar contexto de um projeto para o agente
# Autor: QWEN (MC)
# Data: 2026-04-04

set -uo pipefail

OUTPUT_FILE=""

show_help() {
    cat << 'EOF'
context-builder.sh — Compilar contexto de projeto para agente

Uso: context-builder.sh <project_path> [-o output_file]

Argumentos:
  <project_path>   Caminho para o directório do projeto
  -o, --output    Ficheiro de output (default: stdout)

Output inclui:
  - Árvore de ficheiros (tree -L 2)
  - Versões instaladas (python, node, etc.)
  - Estado do git (branch, último commit)
  - README.md do projeto (se existir)
  - Último log de erro (se existir em 08-logs/)
EOF
}

# Parse argumentos
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL[@]}"

if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

PROJECT_PATH="$1"

# Validar caminho
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Erro: Diretório não encontrado: $PROJECT_PATH" >&2
    exit 1
fi

# Função para outputting
output() {
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo -e "$1" >> "$OUTPUT_FILE"
    else
        echo -e "$1"
    fi
}

# Iniciar output
output "=== CONTEXTO DO PROJETO ==="
output ""
output "**Caminho:** $PROJECT_PATH"
output "**Data:** $(date +%Y-%m-%d_%H:%M:%S)"
output ""

# 1. Árvore de ficheiros
output "---"
output "## 📁 Árvore de Ficheiros"
output ""
if command -v tree &>/dev/null; then
    output "~~~$"
    output "tree -L 2 -a \"$PROJECT_PATH\""
    output "~~~"
    output ""
    output "~~~"
    tree -L 2 -a "$PROJECT_PATH" 2>/dev/null || ls -la "$PROJECT_PATH"
    output "~~~"
else
    output "tree não disponível, usando ls:"
    output "~~~"
    ls -la "$PROJECT_PATH"
    output "~~~"
fi
output ""

# 2. Versões instaladas
output "---"
output "## 🛠️ Versões Instaladas"
output ""

for cmd in python3 node npm git jq; do
    if command -v "$cmd" &>/dev/null; then
        version=$("$cmd" --version 2>&1 | head -1 || echo "unknown")
        output "- **$cmd**: $version"
    else
        output "- **$cmd**: NOT FOUND"
    fi
done
output ""

# 3. Estado do git
output "---"
output "## 🔀 Estado do Git"
output ""

if [[ -d "$PROJECT_PATH/.git" ]]; then
    output "~~~"
    output "cd \"$PROJECT_PATH\" && git status"
    output "~~~"
    output "~~~"
    (cd "$PROJECT_PATH" && git status 2>/dev/null || echo "git status falhou")
    output "~~~"
    output ""
    
    output "**Último commit:**"
    output "~~~"
    (cd "$PROJECT_PATH" && git log -1 --oneline 2>/dev/null || echo "sem commits")
    output "~~~"
    output ""
    
    output "**Branch:**"
    output "~~~"
    (cd "$PROJECT_PATH" && git branch --show-current 2>/dev/null || echo "unknown")
    output "~~~"
else
    output "*Diretório não é repositório git*"
fi
output ""

# 4. README.md
output "---"
output "## 📖 README.md"
output ""

readme=$(find "$PROJECT_PATH" -maxdepth 2 -iname "readme*" -type f 2>/dev/null | head -1)
if [[ -n "$readme" ]]; then
    output "**Ficheiro:** $readme"
    output ""
    output "~~~"
    head -50 "$readme"
    output "~~~"
else
    output "*README.md não encontrado*"
fi
output ""

# 5. Último log de erro (se Makan72)
output "---"
output "## 📜 Último Log de Erro"
output ""

if [[ "$PROJECT_PATH" == *"Makan72"* ]] && [[ -d "$PROJECT_PATH/08-logs/logs" ]]; then
    error_log=$(find "$PROJECT_PATH/08-logs/logs" -name "*.log" -type f 2>/dev/null | head -1)
    if [[ -n "$error_log" ]]; then
        output "**Ficheiro:** $error_log"
        output ""
        output "~~~"
        tail -30 "$error_log"
        output "~~~"
    else
        output "*Sem logs de erro*"
    fi
else
    output "*Não aplicável (não é projeto Makan72)*"
fi

output ""
output "---"
output "*Gerado por context-builder.sh — Makan72*"

# Se output file, mostrar caminho
if [[ -n "$OUTPUT_FILE" ]]; then
    echo ""
    echo "✅ Contexto guardado em: $OUTPUT_FILE"
fi