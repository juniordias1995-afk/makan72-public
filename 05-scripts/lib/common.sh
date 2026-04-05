#!/usr/bin/env bash
# =============================================================================
# common.sh — Biblioteca Partilhada de Helpers Makan72
# =============================================================================
# Uso: source "$MAKAN72_HOME/05-scripts/lib/common.sh"
# =============================================================================

# Evitar re-source
if [[ -n "${MAKAN72_COMMON_LOADED:-}" ]]; then
    return 0
fi
MAKAN72_COMMON_LOADED=1

# =============================================================================
# CORES ANSI
# =============================================================================
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;97m'
export BOLD='\033[1m'
export NC='\033[0m'

# =============================================================================
# HELPERS DE OUTPUT
# =============================================================================
error() {
    local msg="${1:-Erro desconhecido}"
    local exit_code="${2:-1}"
    echo -e "${RED}❌ ERRO: ${msg}${NC}" >&2
    exit "$exit_code"
}

warn() {
    local msg="${1:-Aviso}"
    echo -e "${YELLOW}⚠️  AVISO: ${msg}${NC}" >&2
}

info() {
    local msg="${1:-Info}"
    echo -e "${BLUE}ℹ️  ${msg}${NC}"
}

success() {
    local msg="${1:-Sucesso}"
    echo -e "${GREEN}✅ ${msg}${NC}"
}

# =============================================================================
# HELPERS DE VALIDAÇÃO
# =============================================================================
require_cmd() {
    local cmd="$1"
    local package="${2:-$cmd}"
    if ! command -v "$cmd" &>/dev/null; then
        error "Comando '$cmd' não encontrado. Instale: $package"
    fi
}

require_jq() { require_cmd "jq" "jq"; }
require_python() { require_cmd "python3" "python3"; }

require_file() {
    local file="$1"
    local desc="${2:-ficheiro}"
    [[ ! -f "$file" ]] && error "$desc não encontrado: $file"
}

require_dir() {
    local dir="$1"
    local desc="${2:-pasta}"
    [[ ! -d "$dir" ]] && error "$desc não encontrada: $dir"
}

# =============================================================================
# FICHEIROS TEMPORÁRIOS
# =============================================================================
safe_tmp() {
    local prefix="${1:-makan72}"
    TMP_DIR="${TMP_DIR:-/tmp/${prefix}_$$}"
    mkdir -p "$TMP_DIR"
    mktemp "${TMP_DIR}/tmp_XXXXXX"
}

cleanup_tmp() {
    [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"
}

setup_tmp_cleanup() {
    trap cleanup_tmp EXIT
    trap cleanup_tmp INT
    trap cleanup_tmp TERM
}

# =============================================================================
# CONFIRMAÇÃO
# =============================================================================
confirm() {
    local msg="${1:-Confirmar?}"
    local default="${2:-N}"
    local prompt=$([[ "$default" == "Y" ]] && echo "[Y/n]" || echo "[y/N]")
    
    echo -n -e "${YELLOW}❓ ${msg} ${prompt}: ${NC}"
    read -r response
    [[ -z "$response" ]] && response="$default"
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

confirm_dangerous() {
    local action="$1"
    local target="$2"
    
    echo ""
    echo -e "${RED}⚠️  ATENÇÃO: Esta acção é DESTRUTIVA${NC}"
    echo ""
    echo "  Acção:  ${action}"
    echo "  Alvo:   ${target}"
    echo ""
    echo "Esta acção é IRREVERSÍVEL."
    echo ""
    
    local confirm_text
    read -p "Escreva '$(basename "$target")' para confirmar: " confirm_text
    
    [[ "$confirm_text" == "$(basename "$target")" ]] && return 0 || { echo "Cancelado."; return 1; }
}

# =============================================================================
# LISTAS NUMERADAS
# =============================================================================
numbered_list_select() {
    local title="$1"
    local prompt="${2:-Escolher}"
    local max="$3"
    
    echo ""
    echo -e "${BLUE}${title}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    read -p "${prompt} (1-${max}): " choice
    
    [[ -z "$choice" ]] && error "Escolha não pode ser vazia"
    [[ ! "$choice" =~ ^[0-9]+$ ]] && error "Escolha deve ser número"
    [[ "$choice" -lt 1 || "$choice" -gt "$max" ]] && error "Escolha inválida (1-${max})"
    
    echo "$choice"
}

# =============================================================================
# JQ SEGURO (não crasha com set -e)
# =============================================================================
json_get() {
    local file="$1"
    local query="$2"
    local default="${3:-}"
    
    local result
    result=$(jq -r "$query" "$file" 2>/dev/null) || result="$default"
    [[ -z "$result" || "$result" == "null" ]] && echo "$default" || echo "$result"
}

# =============================================================================
# TIMEOUT EM READS
# =============================================================================
read_with_timeout() {
    local timeout="$1"
    local prompt="$2"
    local varname="$3"
    
    echo -n "$prompt"
    if read -t "$timeout" -r "$varname"; then
        return 0
    else
        echo ""
        return 1
    fi
}

# =============================================================================
# LOGGING
# =============================================================================
log_operation() {
    local action="$1"
    local agent="${2:-system}"
    local result="${3:-OK}"
    local details="${4:-}"

    local log_file="${MAKAN72_HOME:-$HOME/.Makan72}/08-logs/audit/audit.jsonl"
    mkdir -p "$(dirname "$log_file")"

    local ts
    ts=$(portable_date_iso 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)

    echo "{\"ts\":\"$ts\",\"agent\":\"$agent\",\"action\":\"$action\",\"result\":\"$result\",\"details\":\"$details\"}" >> "$log_file"
}

# =============================================================================
# ROTAÇÃO DE LOGS
# =============================================================================
# Parâmetros: <ficheiro_log> <max_size_kb> <max_backups>
# Rotação: file.log → file.log.1 → file.log.2 → apaga .3+
rotate_log() {
    local log_file="$1"
    local max_size_kb="${2:-1024}"  # 1MB default
    local max_backups="${3:-3}"
    
    # Se ficheiro não existe, ignorar
    [[ ! -f "$log_file" ]] && return 0
    
    local size_kb
    size_kb=$(stat -c%s "$log_file" 2>/dev/null | awk '{print int($1/1024)}')
    
    # Se ficheiro menor que max_size, ignorar
    [[ $size_kb -lt $max_size_kb ]] && return 0
    
    echo "📜 Rotacionando $log_file (${size_kb}KB > ${max_size_kb}KB)..."
    
    # Remover backup mais antigo
    local oldest="$log_file.$max_backups"
    [[ -f "$oldest" ]] && rm -f "$oldest"
    
    # Deslocar backups (3→2, 2→1, 1→original)
    for i in $(seq $max_backups -1 1); do
        local old="$log_file.$i"
        local new="$log_file.$((i + 1))"
        [[ -f "$old" ]] && mv "$old" "$new"
    done
    
    # Mover log actual para .1
    mv "$log_file" "$log_file.1"
    
    # Criar novo ficheiro vazio
    touch "$log_file"
    
    echo "✅ Rotação completa"
}

# Setup cleanup automático
setup_tmp_cleanup
