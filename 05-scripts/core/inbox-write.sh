#!/usr/bin/env bash
# inbox-write.sh — Único ponto de entrada oficial para escrever no inbox Makan72
# Autor: CLAUDE (ML/MR)
# Data: 2026-04-05
# Versão: 1.0
#
# PROPÓSITO:
#   Qualquer ficheiro colocado em 03-inbox/*/pending/ DEVE passar por este script.
#   Assina automaticamente com o token Makan72 no cabeçalho.
#   Sem assinatura válida → inbox-guard rejeita imediatamente.
#
# SEGURANÇA:
#   - O token está em ~/.Makan72/.inbox_token (chmod 400, gitignored)
#   - Agentes externos (.team, etc.) não conhecem este token
#   - Ficheiros escritos directamente (sem token) são quarentenados
#
# USO:
#   inbox-write.sh <AGENTE_DESTINO> <NOME_FICHEIRO> <FICHEIRO_FONTE>
#   inbox-write.sh CLAUDE CONTRATO_TAREFA.md /tmp/contrato.md
#   inbox-write.sh --from QWEN CLAUDE SITREP.md /tmp/sitrep.md

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
INBOX_KEY_FILE="$MAKAN72_HOME/.inbox_token"
INBOX_BASE="$MAKAN72_HOME/03-inbox"
AGENTS_JSON="$MAKAN72_HOME/01-config/agents.json"

# Header de autenticação (linha 1 de todos os ficheiros de inbox válidos)
AUTH_HEADER_PREFIX="<!-- MAKAN72-INBOX-AUTH:"

# === FUNÇÕES ===

_iw_log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] INBOX-WRITE: $*" >> "$MAKAN72_HOME/08-logs/inbox-write.log" 2>/dev/null || true
}

_iw_error() {
    echo "❌ ERRO: $*" >&2
    _iw_log "ERRO: $*"
    exit 1
}

_iw_usage() {
    cat << 'EOF'
USO:
  inbox-write.sh [--from REMETENTE] <DESTINO> <NOME> <FICHEIRO>

ARGUMENTOS:
  --from REMETENTE   Quem envia (default: SISTEMA)
  DESTINO            Agente destino (CLAUDE, QWEN, GEMINI, CEO, ...)
  NOME               Nome do ficheiro no inbox (ex: CONTRATO_TAREFA.md)
  FICHEIRO           Ficheiro local com o conteúdo a entregar

EXEMPLOS:
  inbox-write.sh CLAUDE CONTRATO_TAREFA.md /tmp/tarefa.md
  inbox-write.sh --from QWEN CLAUDE SITREP_DONE.md /tmp/sitrep.md
  inbox-write.sh CEO ALERTA_CRITICO.md /tmp/alerta.md
EOF
    exit 1
}

# Verificar que a chave de inbox existe e é legível
_iw_load_key() {
    if [[ ! -f "$INBOX_KEY_FILE" ]]; then
        _iw_error "Chave de inbox não encontrada: $INBOX_KEY_FILE
Execute: openssl rand -hex 64 > $INBOX_KEY_FILE && chmod 400 $INBOX_KEY_FILE"
    fi
    if [[ ! -r "$INBOX_KEY_FILE" ]]; then
        _iw_error "Chave de inbox não legível: $INBOX_KEY_FILE (chmod 400 — apenas owner pode ler)"
    fi
    local inbox_key
    inbox_key=$(cat "$INBOX_KEY_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ ${#inbox_key} -lt 64 ]]; then
        _iw_error "Chave de inbox inválida (muito curta: ${#inbox_key} chars). Regenerar com: openssl rand -hex 64 > $INBOX_KEY_FILE"
    fi
    echo "$inbox_key"
}

# Verificar que o agente destino existe no sistema
_iw_validate_agent() {
    local agent="$1"
    # CEO é sempre válido (humano)
    [[ "$agent" == "CEO" ]] && return 0

    if [[ -f "$AGENTS_JSON" ]] && command -v jq &>/dev/null; then
        if jq -e --arg code "$agent" '.agents[] | select(.code == $code)' "$AGENTS_JSON" &>/dev/null; then
            return 0
        fi
        # Aceitar agentes pausados também (podem receber mensagens)
        _iw_log "AVISO: $agent não encontrado em agents.json — a entregar mesmo assim"
    fi
    # Se agents.json não existe, aceitar qualquer nome que pareça válido
    if [[ "$agent" =~ ^[A-Z][A-Z0-9_-]+$ ]]; then
        return 0
    fi
    _iw_error "Agente destino inválido: '$agent' (deve ser maiúsculas, ex: CLAUDE)"
}

# Assinar e entregar ficheiro no inbox
_iw_deliver() {
    local sender="$1"
    local dest="$2"
    local name="$3"
    local source="$4"

    # Verificações básicas
    [[ -f "$source" ]] || _iw_error "Ficheiro fonte não existe: $source"
    [[ -s "$source" ]] || _iw_error "Ficheiro fonte está vazio: $source"

    # Validar extensão
    if [[ "$name" != *.md && "$name" != *.txt && "$name" != *.yaml && "$name" != *.json ]]; then
        _iw_error "Extensão não permitida: ${name##*.} (permitidas: .md .txt .yaml .json)"
    fi

    # Validar tamanho (max 1MB)
    local size_kb
    size_kb=$(du -k "$source" 2>/dev/null | cut -f1)
    if [[ "$size_kb" -gt 1024 ]]; then
        _iw_error "Ficheiro demasiado grande: ${size_kb}KB (máximo 1MB)"
    fi

    # Carregar chave de autenticação
    local inbox_key
    inbox_key=$(_iw_load_key)

    # Criar pasta de destino se não existir
    local dest_dir="$INBOX_BASE/$dest/pending"
    mkdir -p "$dest_dir"

    local dest_file="$dest_dir/$name"

    # Construir ficheiro assinado:
    # Linha 1: cabeçalho de autenticação com chave
    # Linha 2: metadados
    # Restante: conteúdo original
    {
        echo "$AUTH_HEADER_PREFIX $inbox_key -->"
        echo "<!-- MAKAN72-INBOX-META: from=$sender to=$dest ts=$(date +%Y%m%dT%H%M%S) -->"
        echo ""
        cat "$source"
    } > "$dest_file"

    chmod 640 "$dest_file"

    _iw_log "OK: $sender -> $dest/$name (${size_kb}KB)"
    echo "✅ Entregue: $dest/pending/$name (de: $sender)"
    return 0
}

# === MAIN ===

# Verificar dependências
command -v openssl &>/dev/null || _iw_error "openssl não encontrado (necessário para verificação de token)"

# Parsear argumentos
SENDER="SISTEMA"
if [[ "${1:-}" == "--from" ]]; then
    SENDER="${2:?--from requer nome do remetente}"
    shift 2
fi

DEST="${1:-}"
NAME="${2:-}"
SOURCE="${3:-}"

[[ -z "$DEST" || -z "$NAME" || -z "$SOURCE" ]] && _iw_usage

# Validar agente destino
_iw_validate_agent "$DEST"

# Entregar
_iw_deliver "$SENDER" "$DEST" "$NAME" "$SOURCE"
