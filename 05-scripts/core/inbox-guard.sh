#!/usr/bin/env bash
# inbox-guard.sh — Guarda de Segurança do Inbox
# Autor: CLAUDE (ML)
# Data: 2026-04-05
# Versão: 1.0
#
# PROPÓSITO:
#   Scannear TODOS os ficheiros colocados em 03-inbox/*/pending/
#   antes de qualquer agente os ler ou executar.
#   Ficheiros suspeitos são QUARENTENADOS — nunca chegam ao agente.
#
# PROTEGE CONTRA:
#   - Prompt injection (comandos shell embutidos em markdown)
#   - Code injection (vírus/malware em contratos)
#   - Agentes não autorizados a colocar tarefas
#   - Sistemas externos a invadir o inbox
#   - Exfiltração de dados (curl, wget, nc para exterior)

set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
GUARD_LOG="$MAKAN72_HOME/08-logs/inbox-guard.log"
QUARANTINE_DIR="$MAKAN72_HOME/07-archive/quarantine"
AGENTS_JSON="$MAKAN72_HOME/01-config/agents.json"
INBOX_KEY_FILE="$MAKAN72_HOME/.inbox_token"
AUTH_HEADER_PREFIX="<!-- MAKAN72-INBOX-AUTH:"

# Cores
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# === AGENTES AUTORIZADOS ===
# Quem pode colocar ficheiros no inbox. CEO é sempre autorizado.
AUTHORIZED_SENDERS=("CEO" "CLAUDE" "QWEN" "GEMINI" "OPENCODE" "GOOSE" "SISTEMA" "orchestrate" "team-bot")

# === PADRÕES PERIGOSOS ===
# Cada padrão tem: REGEX|DESCRIÇÃO|SEVERIDADE (CRITICAL/HIGH/MEDIUM)

INJECTION_PATTERNS=(
    # === EXECUÇÃO REMOTA — Sempre perigoso ===
    # Pipe directo para shell (ataque clássico)
    'curl\s+.{0,100}\|\s*(bash|sh)\b|CRITICAL|curl|bash — execução remota de código'
    'wget\s+.{0,100}\|\s*(bash|sh)\b|CRITICAL|wget|bash — execução remota de código'
    'wget\s+-O\s*-\s*\|.{0,30}(bash|sh)\b|CRITICAL|wget -O- | shell — execução remota'
    '\|\s*bash\s*$|\|\s*sh\s*$|CRITICAL|Pipe terminal para bash/sh — suspeito'

    # eval com expansão (não simples strings estáticas)
    'eval\s*\$|CRITICAL|eval com expansão de variável — injecção'
    'eval\s*`|CRITICAL|eval com backtick — injecção de comando'
    '\beval\s+"[^"]*\$|CRITICAL|eval com string expandida — injecção'

    # === DESTRUIÇÃO DO SISTEMA ===
    'rm\s+-[rRf]{1,3}\s+/[^M]|CRITICAL|rm -rf /sistema — apagar sistema'
    'rm\s+-[rRf]{1,3}\s+~/[^\.M]|CRITICAL|rm -rf ~/dir — apagar home'
    'rm\s+-[rRf]{1,3}\s+\$MAKAN72_HOME|CRITICAL|rm -rf Makan72 — auto-destruição'
    'rm\s+-[rRf]{1,3}\s+\$HOME\b|CRITICAL|rm -rf $HOME — apagar home completo'
    'mkfs\.[a-z]|CRITICAL|mkfs — formatar partição de disco'
    'dd\s+if=/dev/zero\s+of=|CRITICAL|dd zero-out — destruição de dados'
    'dd\s+if=/dev/random\s+of=|CRITICAL|dd random — destruição de dados'
    ':\s*>\s*/etc/(passwd|shadow|hosts|crontab)|CRITICAL|Sobrescrever ficheiro crítico do sistema'

    # === BACKDOORS E EXFILTRAÇÃO ===
    'nc\s+(-[a-z]*)?-e\s|CRITICAL|netcat -e — backdoor shell reverso'
    'ncat\s+.*--exec|CRITICAL|ncat --exec — backdoor shell'
    'ssh\s+-R\s+[0-9]+:|HIGH|SSH reverse tunnel — possível exfiltração'
    'socat\s+.*EXEC:|HIGH|socat EXEC — execução remota'
    'python\d*\s+-c\s+["'"'"'].*(socket|connect|bind)|HIGH|Python socket inline — conexão suspeita'
    'bash\s+-i\s+>&\s*/dev/tcp/|CRITICAL|Bash reverse shell — backdoor clássico'

    # === ESCALAÇÃO DE PRIVILÉGIOS ===
    'sudo\s+(rm|wget|curl|chmod|chown|dd|mkfs|bash|sh|python|perl|ruby)\b|HIGH|sudo + comando perigoso'
    'chmod\s+(u\+s|g\+s|[0-7]*[4-7][0-7][0-7])\s+/|HIGH|chmod SUID ou world-write em path de sistema'
    'chown\s+root:root\s+/|HIGH|chown root em path de sistema'

    # === SOBRESCREVER FICHEIROS SAGRADOS ===
    '(^|[;&|])\s*>\s*[^>].*(VERDADE|VACINAS|agents\.json|GUARDRAILS)|CRITICAL|Redirecção para ficheiro sagrado'
    '\btee\s+.*(VERDADE|VACINAS|agents\.json)|CRITICAL|tee para ficheiro sagrado'

    # === VIOLAÇÃO DE ISOLAMENTO (aceder ao .team) ===
    '~/\.team/[^"'"'"'`\s]|HIGH|Path directo ao .team — violação de isolamento'
    '\$HOME/\.team/|HIGH|$HOME/.team — violação de isolamento'
    '"/home/[^/]+/\.team/|HIGH|Path absoluto ao .team — violação de isolamento'

    # === INJECÇÃO PYTHON AVANÇADA ===
    '__import__\s*\(\s*["'"'"']os["'"'"']\s*\)|HIGH|__import__("os") — import dinâmico suspeito'
    'os\.(system|popen)\s*\(\s*["'"'"'][^"'"'"']*[;&|`]|HIGH|os.system com encadeamento de comandos'
    'subprocess\.[a-z]+\s*\([^)]*shell\s*=\s*True[^)]*[;&|`]|HIGH|subprocess shell=True com injecção'
    'compile\s*\(.{0,50}\)\s*;\s*exec|HIGH|compile + exec — execução dinâmica'

    # === MANIPULAÇÃO DO PRÓPRIO GUARD ===
    '\binbox.guard\b.*(disable|bypass|skip|remov|delet|stop)|CRITICAL|Tentativa de desactivar o inbox-guard'
    'QUARANTINE_DIR\s*=|CRITICAL|Tentativa de redefinir diretório de quarentena'
)

# === FUNÇÕES ===

_guard_log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $*" >> "$GUARD_LOG"
}

# === VERIFICAÇÃO DE TOKEN DE AUTENTICAÇÃO ===
# Todo o ficheiro de inbox DEVE começar com:
#   <!-- MAKAN72-INBOX-AUTH: <token> -->
# Ficheiros sem token válido são de origem externa — quarentena imediata.
_guard_verify_token() {
    local file="$1"

    # Se a chave não existe no sistema, avisar mas não bloquear
    # (sistema ainda não configurado — modo de compatibilidade)
    if [[ ! -f "$INBOX_KEY_FILE" ]]; then
        _guard_log "WARN" "Chave de inbox não configurada ($INBOX_KEY_FILE) — verificação desactivada"
        return 0
    fi

    local stored_key
    stored_key=$(cat "$INBOX_KEY_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ ${#stored_key} -lt 64 ]]; then
        _guard_log "WARN" "Chave de inbox inválida/corrompida — verificação desactivada"
        return 0
    fi

    # Ler linha 1 do ficheiro
    local first_line
    first_line=$(head -n 1 "$file" 2>/dev/null)

    # Verificar se começa com o prefixo correcto
    if [[ "$first_line" != "$AUTH_HEADER_PREFIX"* ]]; then
        # Ficheiro sem cabeçalho de autenticação — origem externa/não autorizada
        echo "SEM_TOKEN"
        return 1
    fi

    # Extrair chave do cabeçalho: <!-- MAKAN72-INBOX-AUTH: CHAVE -->
    local file_key
    file_key=$(echo "$first_line" | sed "s|$AUTH_HEADER_PREFIX ||; s| -->||" | tr -d '[:space:]')

    if [[ "$file_key" != "$stored_key" ]]; then
        # Token presente mas errado — possível tentativa de spoofing
        echo "TOKEN_INVALIDO"
        return 1
    fi

    return 0
}

_guard_alert_ceo() {
    local filename="$1"
    local reason="$2"
    local severity="$3"
    local alert_file="$MAKAN72_HOME/03-inbox/CEO/pending/ALERT_GUARD_$(date +%Y%m%d_%H%M%S).md"

    mkdir -p "$(dirname "$alert_file")"

    # IMPORTANTE: NÃO incluir conteúdo malicioso no alerta (evita auto-quarentena do alerta)
    # O motivo é sanitizado — padrões perigosos são substituídos por descrições seguras
    local safe_reason
    safe_reason=$(echo "$reason" | sed 's/curl.*bash/[REDACTED: execucao remota]/g; s/rm -rf/[REDACTED: destructive-cmd]/g; s/eval/[REDACTED: eval]/g')

    cat > "$alert_file" << ALERT_EOF
# ALERTA DE SEGURANCA -- Inbox Guard

**Data:** $(date '+%Y-%m-%d %H:%M:%S')
**Severidade:** $severity
**Ficheiro bloqueado:** $(basename "$filename")
**Destino original:** $filename
**Motivo (sanitizado):** $safe_reason

---

## Accao Tomada

O ficheiro foi movido para quarentena automaticamente.
Localização: $QUARANTINE_DIR/

O agente NAO recebeu este ficheiro.

---

## Proximo Passo

1. Verificar o ficheiro em quarentena (NAO executar o conteudo)
2. Se for legitimo: mover de volta para pending/ manualmente
3. Se for malicioso: investigar a origem e apagar

ATENCAO: Pode ser uma tentativa de ataque ao sistema Makan72.
ALERT_EOF

    _guard_log "ALERT" "CEO notificado: $alert_file"
    echo -e "${RED}${BOLD}ALERTA CEO criado: $alert_file${RESET}"
}

_guard_quarantine() {
    local file="$1"
    local reason="$2"
    local severity="${3:-HIGH}"

    mkdir -p "$QUARANTINE_DIR"
    local dest="$QUARANTINE_DIR/$(date +%Y%m%d_%H%M%S)_$(basename "$file")"
    mv "$file" "$dest"

    _guard_log "QUARANTINE" "[$severity] $file → $dest | $reason"
    echo -e "${RED}🔒 QUARENTENA: $(basename "$file") — $reason${RESET}"
    _guard_alert_ceo "$file" "$reason" "$severity"
}

# Verificar se o nome do ficheiro vem de remetente autorizado
_guard_check_sender() {
    local filename="$1"
    local basename
    basename=$(basename "$filename")

    # CEO pode sempre escrever qualquer coisa
    for sender in "${AUTHORIZED_SENDERS[@]}"; do
        if [[ "$basename" == *"$sender"* ]] || [[ "$basename" =~ ^(CONTRATO|SITREP|NOTIFY|MEMO|DOUBT|ALERTA|ALERT|HANDOFF|REPLY|PERGUNTA|TAREFA|TASK|notify|handoff)_ ]]; then
            return 0
        fi
    done

    # Padrões de nomes permitidos
    if [[ "$basename" =~ ^[A-Z_0-9-]+\.md$ ]] || [[ "$basename" =~ ^[a-z_0-9-]+\.md$ ]]; then
        return 0  # Nome estruturado sem padrões suspeitos — OK
    fi

    return 1
}

# Verificar conteúdo do ficheiro contra padrões de injecção
_guard_scan_content() {
    local file="$1"
    local issues=()
    local max_severity="NONE"

    # Ler conteúdo sem executar
    local content
    content=$(cat "$file" 2>/dev/null) || return 0

    for pattern_entry in "${INJECTION_PATTERNS[@]}"; do
        local pattern="${pattern_entry%%|*}"
        local rest="${pattern_entry#*|}"
        local description="${rest%%|*}"
        local severity="${rest##*|}"

        if echo "$content" | grep -qPi "$pattern" 2>/dev/null; then
            issues+=("[$severity] $description")
            # Elevar severidade máxima
            if [[ "$severity" == "CRITICAL" ]]; then
                max_severity="CRITICAL"
            elif [[ "$severity" == "HIGH" && "$max_severity" != "CRITICAL" ]]; then
                max_severity="HIGH"
            elif [[ "$severity" == "MEDIUM" && "$max_severity" == "NONE" ]]; then
                max_severity="MEDIUM"
            fi
        fi
    done

    if [[ ${#issues[@]} -gt 0 ]]; then
        local report
        report=$(printf '%s\n' "${issues[@]}")
        echo "$max_severity|$report"
        return 1
    fi

    return 0
}

# === COMANDO: scan — Escanear ficheiro específico ===
guard_scan_file() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    echo -e "${CYAN}🔍 Scanning: $basename${RESET}"
    _guard_log "SCAN" "Início: $file"

    # Verificação 1: Ficheiro existe?
    if [[ ! -f "$file" ]]; then
        echo -e "${YELLOW}⚠️  Ficheiro não existe: $file${RESET}"
        return 0
    fi

    # Verificação 1b: Token de autenticação (PRIMEIRA LINHA — mais importante)
    local token_check
    if ! token_check=$(_guard_verify_token "$file"); then
        if [[ "$token_check" == "TOKEN_INVALIDO" ]]; then
            _guard_quarantine "$file" "Token de autenticação INVÁLIDO — possível spoofing ou ficheiro adulterado" "CRITICAL"
        else
            _guard_quarantine "$file" "Ficheiro sem token Makan72 — origem externa não autorizada (use inbox-write.sh)" "CRITICAL"
        fi
        return 1
    fi

    # Verificação 2: Extensão permitida
    if [[ "$file" != *.md && "$file" != *.txt && "$file" != *.yaml && "$file" != *.json ]]; then
        _guard_quarantine "$file" "Extensão não permitida no inbox: ${file##*.}" "HIGH"
        return 1
    fi

    # Verificação 3: Tamanho suspeito (> 1MB = suspeito)
    local size_kb
    size_kb=$(du -k "$file" 2>/dev/null | cut -f1)
    if [[ "$size_kb" -gt 1024 ]]; then
        _guard_quarantine "$file" "Ficheiro suspeito: ${size_kb}KB (máximo 1MB no inbox)" "MEDIUM"
        return 1
    fi

    # Verificação 4: Conteúdo malicioso
    local scan_result
    if ! scan_result=$(_guard_scan_content "$file"); then
        local severity="${scan_result%%|*}"
        local issues="${scan_result#*|}"
        _guard_quarantine "$file" "Conteúdo malicioso detectado: $issues" "$severity"
        return 1
    fi

    echo -e "${GREEN}✅ LIMPO: $basename${RESET}"
    _guard_log "OK" "$file — limpo"
    return 0
}

# === COMANDO: scan-inbox — Escanear inbox de um agente ===
guard_scan_inbox() {
    local agent="${1:-ALL}"
    local scanned=0
    local blocked=0
    local ok=0

    echo -e "${BOLD}${CYAN}=== INBOX GUARD — Scan Iniciado ===${RESET}"
    echo -e "Agente: ${agent}"
    echo ""

    local inboxes=()
    if [[ "$agent" == "ALL" ]]; then
        # Encontrar todos os pending/
        while IFS= read -r dir; do
            inboxes+=("$dir")
        done < <(find "$MAKAN72_HOME/03-inbox" -type d -name "pending" 2>/dev/null)
    else
        inboxes=("$MAKAN72_HOME/03-inbox/$agent/pending")
    fi

    for inbox_dir in "${inboxes[@]}"; do
        [[ -d "$inbox_dir" ]] || continue
        local agent_name
        agent_name=$(echo "$inbox_dir" | awk -F'/' '{print $(NF-1)}')

        # CEO é o dono do sistema — inbox do CEO não é scaneado
        # (CEO escreve alertas e instruções aqui — nunca deve ser bloqueado)
        if [[ "$agent_name" == "CEO" ]]; then
            _guard_log "SKIP" "Inbox CEO ignorado (dono do sistema)"
            continue
        fi

        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            [[ "$(basename "$file")" == ".gitkeep" ]] && continue
            scanned=$((scanned + 1))

            if ! guard_scan_file "$file"; then
                blocked=$((blocked + 1))
            else
                ok=$((ok + 1))
            fi
        done < <(find "$inbox_dir" -maxdepth 1 -type f 2>/dev/null)
    done

    echo ""
    echo -e "${BOLD}=== RESULTADO ===${RESET}"
    echo -e "  Ficheiros scaneados: $scanned"
    echo -e "  ${GREEN}Limpos: $ok${RESET}"
    echo -e "  ${RED}Bloqueados/Quarentena: $blocked${RESET}"
    echo ""

    if [[ $blocked -gt 0 ]]; then
        echo -e "${RED}${BOLD}⚠️  $blocked ficheiro(s) quarentenado(s). CEO foi alertado.${RESET}"
        _guard_log "SUMMARY" "scan=$scanned ok=$ok blocked=$blocked"
        return 1
    else
        echo -e "${GREEN}✅ Inbox limpo.${RESET}"
        _guard_log "SUMMARY" "scan=$scanned ok=$ok blocked=0"
        return 0
    fi
}

# === COMANDO: watch — Monitorizar inbox em tempo real ===
guard_watch() {
    local agent="${1:-ALL}"
    echo -e "${BOLD}${CYAN}👁️  INBOX GUARD — Modo Watch (Ctrl+C para parar)${RESET}"
    echo -e "A monitorizar: $MAKAN72_HOME/03-inbox/"
    echo ""

    # Scan inicial
    guard_scan_inbox "$agent"

    # Monitorizar com inotifywait se disponível
    if command -v inotifywait &>/dev/null; then
        echo -e "${CYAN}inotifywait detectado — monitorização em tempo real${RESET}"
        inotifywait -m -r -e create,moved_to "$MAKAN72_HOME/03-inbox" \
            --format '%w%f' 2>/dev/null | while read -r new_file; do
            if [[ "$new_file" == */pending/* && -f "$new_file" ]]; then
                sleep 0.2  # Aguardar escrita completa
                guard_scan_file "$new_file"
            fi
        done
    else
        # Fallback: polling a cada 5 segundos
        echo -e "${YELLOW}inotifywait não instalado — polling a cada 5s${RESET}"
        local last_count=0
        while true; do
            local current_count
            current_count=$(find "$MAKAN72_HOME/03-inbox" -path "*/pending/*" -type f ! -name ".gitkeep" 2>/dev/null | wc -l)
            if [[ "$current_count" -gt "$last_count" ]]; then
                guard_scan_inbox "$agent"
                last_count=$current_count
            fi
            sleep 5
        done
    fi
}

# === COMANDO: status ===
guard_status() {
    local quarantine_count=0
    quarantine_count=$(find "$QUARANTINE_DIR" -type f 2>/dev/null | wc -l) || quarantine_count=0
    local pending_count=0
    pending_count=$(find "$MAKAN72_HOME/03-inbox" -path "*/pending/*" -type f ! -name ".gitkeep" 2>/dev/null | wc -l) || pending_count=0
    local log_lines=0
    [[ -f "$GUARD_LOG" ]] && log_lines=$(wc -l < "$GUARD_LOG" 2>/dev/null) || log_lines=0

    echo "=== INBOX GUARD STATUS ==="
    echo "  Ficheiros em quarentena : $quarantine_count"
    echo "  Ficheiros pending (total): $pending_count"
    echo "  Entradas no log         : $log_lines"
    echo "  Log                     : $GUARD_LOG"
    echo "  Quarentena              : $QUARANTINE_DIR"
}

# === COMANDO: quarantine-list ===
guard_quarantine_list() {
    echo "=== FICHEIROS EM QUARENTENA ==="
    if [[ ! -d "$QUARANTINE_DIR" ]] || [[ -z "$(ls -A "$QUARANTINE_DIR" 2>/dev/null)" ]]; then
        echo "  (vazio — nenhum ficheiro quarentenado)"
        return 0
    fi
    ls -lh "$QUARANTINE_DIR"
}

# === COMANDO: install-hook — Integrar no run-agent.sh ===
guard_install_hook() {
    echo "Para integrar o inbox-guard no run-agent.sh, adiciona antes do agente arrancar:"
    echo ""
    echo '  # Scan de segurança antes de ler inbox'
    echo '  bash "$MAKAN72_HOME/05-scripts/core/inbox-guard.sh" scan-inbox "$AGENT_CODE" || {'
    echo '      echo "⚠️  Inbox Guard bloqueou ficheiros suspeitos. Verifica 03-inbox/CEO/pending/"'
    echo '  }'
}

# === HELP ===
guard_help() {
    cat << 'EOF'
inbox-guard.sh — Guarda de Segurança do Inbox Makan72

COMANDOS:
  scan-inbox [AGENTE]    Escanear inbox de um agente (ALL para todos)
  scan FILE              Escanear ficheiro específico
  watch [AGENTE]         Monitorizar inbox em tempo real
  status                 Estado do guard (quarentena, logs)
  quarantine-list        Listar ficheiros em quarentena
  install-hook           Mostrar como integrar no run-agent.sh
  help                   Esta ajuda

EXEMPLOS:
  bash inbox-guard.sh scan-inbox ALL
  bash inbox-guard.sh scan-inbox QWEN
  bash inbox-guard.sh scan ~/.Makan72/03-inbox/CLAUDE/pending/CONTRATO.md
  bash inbox-guard.sh watch ALL
  bash inbox-guard.sh status

PROTEGE CONTRA:
  - Shell injection ($(), backticks, eval, exec)
  - Pipe para bash/sh (curl|bash, wget|sh)
  - Comandos destrutivos (rm -rf /, dd, mkfs)
  - Exfiltração (curl URLs externas, nc, ssh -R)
  - Acesso a sistemas externos (.team/)
  - Escalação de privilégios (sudo, chmod 777)
  - Manipulação de ficheiros sagrados
  - Ficheiros com extensões não permitidas
  - Ficheiros > 1MB no inbox
EOF
}

# === ENTRY POINT ===
CMD="${1:-help}"
shift || true

case "$CMD" in
    scan-inbox)    guard_scan_inbox "${1:-ALL}" ;;
    scan)          guard_scan_file "${1:?Uso: inbox-guard.sh scan <ficheiro>}" ;;
    watch)         guard_watch "${1:-ALL}" ;;
    status)        guard_status ;;
    quarantine-list) guard_quarantine_list ;;
    install-hook)  guard_install_hook ;;
    help|--help|-h) guard_help ;;
    *)
        echo "Comando desconhecido: $CMD"
        guard_help
        exit 1
        ;;
esac
