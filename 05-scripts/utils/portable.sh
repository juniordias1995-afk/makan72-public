#!/usr/bin/env bash
# portable.sh — Funcoes portaveis para Linux e macOS
#
# Este ficheiro fornece funcoes wrapper para comandos que diferem
# entre GNU (Linux) e BSD (macOS).
#
# Uso: source "$MAKAN72_HOME/05-scripts/utils/portable.sh"

# Evitar re-source
if [[ -n "${PORTABLE_SH_LOADED:-}" ]]; then
    return 0
fi
PORTABLE_SH_LOADED=1

# Detectar se e macOS/BSD
is_bsd() {
    if [[ "${OSTYPE:-}" == "darwin"* ]]; then
        return 0
    elif command -v uname &>/dev/null && [[ "$(uname -s)" == "Darwin" ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# portable_date_iso
# =============================================================================
# Retorna data/hora em formato ISO 8601 com timezone.
#
# Exemplo output:
#   2026-03-08T12:30:45+00:00
#
# Uso:
#   timestamp=$(portable_date_iso)

portable_date_iso() {
    # Tentar GNU date primeiro (mais preciso)
    if date -Iseconds &>/dev/null; then
        date -Iseconds
    # Fallback para BSD/macOS date
    elif date -u +"%Y-%m-%dT%H:%M:%S%z" &>/dev/null; then
        # BSD date: formatar timezone correctamente
        local result
        result=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
        # Inserir ':' no timezone (ex: +0000 -> +00:00)
        echo "${result:0:22}:${result:22:2}"
    else
        # Fallback ultimo: UTC basico
        date -u +"%Y-%m-%dT%H:%M:%S+00:00"
    fi
}

# =============================================================================
# portable_date_parse
# =============================================================================
# Converte timestamp ISO 8601 para epoch seconds.
#
# Exemplo:
#   portable_date_parse "2026-03-08T12:30:45+00:00"  =>  1773057045
#
# Uso:
#   epoch=$(portable_date_parse "$timestamp")

portable_date_parse() {
    local ts="$1"
    
    [[ -z "$ts" ]] && echo "0" && return
    
    # Tentar GNU date primeiro
    if date -d "$ts" +%s &>/dev/null; then
        date -d "$ts" +%s
    # Tentar BSD date (macOS)
    elif date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%%[+-]*}" +%s &>/dev/null; then
        # BSD: extrair data sem timezone e converter
        date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%%[+-]*}" +%s
    # Fallback: python3
    elif command -v python3 &>/dev/null; then
        python3 -c "
from datetime import datetime
import sys
ts = sys.argv[1]
try:
    # Tentar parse com timezone
    dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print('0')
" "$ts"
    else
        # Sem fallback disponivel
        echo "0"
    fi
}

# =============================================================================
# portable_sed_i
# =============================================================================
# Executa sed -i (in-place) de forma portavel.
#
# Diferenca:
#   GNU:  sed -i 's/foo/bar/' file.txt
#   BSD:  sed -i '' 's/foo/bar/' file.txt  (exige argumento vazio para backup)
#
# Uso:
#   portable_sed_i "s/foo/bar/" file.txt
#   portable_sed_i -e "s/foo/bar/" file.txt

portable_sed_i() {
    local args=("$@")
    local num_args=${#args[@]}
    
    if [[ $num_args -lt 2 ]]; then
        echo "ERRO: portable_sed_i exige pelo menos 2 argumentos" >&2
        echo "Uso: portable_sed_i 's/old/new/' file.txt" >&2
        return 1
    fi
    
    # Obter ficheiro (ultimo argumento)
    local file="${args[$num_args-1]}"
    
    # Obter expressao/argumentos (todos excepto o ultimo)
    local sed_args=("${args[@]:0:$num_args-1}")
    
    if is_bsd; then
        # macOS/BSD: exige '' para nao criar backup
        sed -i '' "${sed_args[@]}" "$file"
    else
        # GNU/Linux: directo
        sed -i "${sed_args[@]}" "$file"
    fi
}

# =============================================================================
# portable_sed_inplace (alias mais descritivo)
# =============================================================================
# Alias para portable_sed_i com nome mais claro.

portable_sed_inplace() {
    portable_sed_i "$@"
}

# =============================================================================
# portable_readlink
# =============================================================================
# Resolve symlinks de forma portavel.
#
# Uso:
#   real_path=$(portable_readlink "$path")

portable_readlink() {
    local path="$1"
    
    if readlink -f "$path" &>/dev/null; then
        # GNU readlink
        readlink -f "$path"
    elif [[ -L "$path" ]]; then
        # BSD/macOS: usar stat ou fallback
        if stat -f "%Y" "$path" &>/dev/null 2>&1; then
            # macOS stat
            readlink "$path"
        else
            # Fallback simples
            readlink "$path"
        fi
    else
        # Nao e symlink, retornar path original
        echo "$path"
    fi
}

# =============================================================================
# portable_mktemp
# =============================================================================
# Cria ficheiro temporario de forma portavel.
#
# Uso:
#   tmpfile=$(portable_mktemp)

portable_mktemp() {
    if mktemp &>/dev/null; then
        mktemp
    else
        # Fallback basico
        echo "/tmp/makan72.$$.$RANDOM"
    fi
}

# =============================================================================
# portable_sleep
# =============================================================================
# Sleep portavel (aceita fraccional em segundos).
#
# Uso:
#   portable_sleep 0.5

portable_sleep() {
    local duration="$1"
    
    if sleep "$duration" &>/dev/null; then
        sleep "$duration"
    elif command -v python3 &>/dev/null; then
        python3 -c "import time; time.sleep($duration)"
    else
        # Fallback: sleep inteiro (BSD antigo)
        sleep "${duration%.*}"
    fi
}
