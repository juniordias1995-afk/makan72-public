#!/usr/bin/env bash
# =============================================================================
# team-bot.sh — Bot principal do Makan72
# Orquestrador de módulos — NÃO faz trabalho, apenas carrega e encaminha
# =============================================================================
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
BOT_DIR="$MAKAN72_HOME/02-bots"
LIB_DIR="$BOT_DIR/lib"
CONFIG="$BOT_DIR/config/BOT_RULES.yaml"
LOG_FILE="$MAKAN72_HOME/08-logs/bot-main.log"
# Carregar funções partilhadas (com protecção — não crashar se falhar)
FUNCTIONS_FILE="$MAKAN72_HOME/05-scripts/core/makan72-functions.sh"
[[ -f "$FUNCTIONS_FILE" ]] && source "$FUNCTIONS_FILE" 2>/dev/null || true

# Cores ANSI
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log() {
    echo "[$(portable_date_iso)] $*" >> "$LOG_FILE"
}

# Verificar BOT_RULES.yaml existe
if [[ ! -f "$CONFIG" ]]; then
    echo -e "${RED}❌ Erro: BOT_RULES.yaml não encontrado em $CONFIG${NC}"
    exit 1
fi

# Ler agents.json para saber agentes activos
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"
if [[ -f "$AGENTS_FILE" ]]; then
    # Usar jq sem -e para não crashar com set -e
    AGENTS_LIST=$(jq -r ".agents[] | select(.status==\"active\") | .code" "$AGENTS_FILE" 2>/dev/null || echo "")
    AGENT_COUNT=$(echo "$AGENTS_LIST" | grep -c . 2>/dev/null || echo "0")
    log "Agentes activos carregados: $AGENT_COUNT"
else
    log "AVISO: agents.json nao encontrado"
    AGENTS_LIST=""
fi

# Carregar todos os módulos disponíveis
declare -a LOADED_MODULES=()
for module in "$LIB_DIR"/*.sh; do
    if [[ -f "$module" ]]; then
        # Extrair nome do módulo
        module_name=$(basename "$module" .sh)
        
        # Verificar se módulo está habilitado
        if source "$module" 2>/dev/null; then
            LOADED_MODULES+=("$module_name")
            log "Módulo carregado: $module_name"
        else
            log "AVISO: Módulo falhou ao carregar: $module_name"
        fi
    fi
done


# Gerar documentacao automatica
cmd_docs() {
    local output="$MAKAN72_HOME/06-reports/DOCS_auto.md"
    
    echo "# Documentação Automática do Makan72" > "$output"
    echo "" >> "$output"
    echo "**Gerado em:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$output"
    echo "" >> "$output"
    
    # Scripts
    echo "## Scripts (05-scripts)" >> "$output"
    echo "" >> "$output"
    for script in "$MAKAN72_HOME/05-scripts"/*/*.sh; do
        if [[ -f "$script" ]]; then
            local name=$(basename "$script")
            local desc=$(head -5 "$script" | grep "^#" | head -1 | sed 's/^# //')
            echo "- **$name**: $desc" >> "$output"
        fi
    done
    echo "" >> "$output"
    
    # Agentes
    echo "## Agentes" >> "$output"
    echo "" >> "$output"
    echo "### Activos" >> "$output"
    jq -r '.agents[] | select(.status=="active") | "- **\(.code)**: \(.name) (\(.cli))"' "$MAKAN72_HOME/01-config/agents.json" >> "$output" 2>/dev/null || echo "(nenhum)" >> "$output"
    echo "" >> "$output"
    echo "### Pausados" >> "$output"
    jq -r '.agents[] | select(.status=="paused") | "- **\(.code)**: \(.name) (\(.cli))"' "$MAKAN72_HOME/01-config/agents.json" >> "$output" 2>/dev/null || echo "(nenhum)" >> "$output"
    echo "" >> "$output"
    
    # Projectos
    echo "## Projectos" >> "$output"
    echo "" >> "$output"
    jq -r '.projects[] | "- **\(.name)**: \(.path)"' "$MAKAN72_HOME/01-config/projects.json" >> "$output" 2>/dev/null || echo "(nenhum)" >> "$output"
    
    echo ""
    echo "✅ Documentação gerada: $output"
}

# Gerar relatorio de estado
cmd_report() {
    local timestamp=$(date '+%Y%m%d_%H%M')
    local output="$MAKAN72_HOME/06-reports/REPORT_${timestamp}.md"
    
    echo "# Relatório de Estado do Makan72" > "$output"
    echo "" >> "$output"
    echo "**Gerado em:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$output"
    echo "" >> "$output"
    
    # Versao
    echo "## Versão" >> "$output"
    echo "" >> "$output"
    if [[ -f "$MAKAN72_HOME/VERSION" ]]; then
        echo "- **Versão:** $(cat "$MAKAN72_HOME/VERSION")" >> "$output"
    fi
    echo "" >> "$output"
    
    # Agentes
    echo "## Agentes" >> "$output"
    echo "" >> "$output"
    local active_count=$(jq '[.agents[] | select(.status=="active")] | length' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null || echo "0")
    local paused_count=$(jq '[.agents[] | select(.status=="paused")] | length' "$MAKAN72_HOME/01-config/agents.json" 2>/dev/null || echo "0")
    echo "- **Activos:** $active_count" >> "$output"
    echo "- **Pausados:** $paused_count" >> "$output"
    echo "" >> "$output"
    
    # Projecto activo
    echo "## Projecto Activo" >> "$output"
    echo "" >> "$output"
    local active_project=$(jq -r '.projects[] | select(.active==true) | .name' "$MAKAN72_HOME/01-config/projects.json" 2>/dev/null || echo "Nenhum")
    local active_path=$(jq -r '.projects[] | select(.active==true) | .path' "$MAKAN72_HOME/01-config/projects.json" 2>/dev/null || echo "Nenhum")
    echo "- **Nome:** $active_project" >> "$output"
    echo "- **Path:** $active_path" >> "$output"
    echo "" >> "$output"
    
    # Health check quick
    echo "## Health Check (Quick)" >> "$output"
    echo "" >> "$output"
    local health_result=$(bash "$MAKAN72_HOME/05-scripts/utils/health-check.sh" quick 2>&1 | tail -3)
    echo '```' >> "$output"
    echo "$health_result" >> "$output"
    echo '```' >> "$output"
    echo "" >> "$output"
    
    # Ultimos ficheiros modificados
    echo "## Últimos Ficheiros Modificados" >> "$output"
    echo "" >> "$output"
    echo '```' >> "$output"
    find "$MAKAN72_HOME" -type f -mmin -60 -not -path "*/.git/*" -not -path "*/08-logs/*" 2>/dev/null | head -10 >> "$output"
    echo '```' >> "$output"
    
    echo ""
    echo "✅ Relatório gerado: $output"
}

# Mostrar ajuda
show_help() {
    cat << 'HELP'
╔══════════════════════════════════════════════════════════╗
║     team-bot.sh — Bot Principal do Makan72              ║
╠══════════════════════════════════════════════════════════╣
║  OPERAÇÕES CORE:                                         ║
║    process-inbox         Processar tarefas pendentes    ║
║    check-heartbeats      Verificar agentes vivos         ║
║    process-handoffs      Processar entregas entre agentes║
║    check-guardrails      Verificar limites de acção      ║
║                                                            ║
║  MANUTENÇÃO:                                              ║
║    cleanup               Limpar ficheiros expirados       ║
║    sleep                 Consolidação de memória          ║
║    notify                Enviar notificações              ║
║                                                            ║
║  VALIDAÇÃO:                                               ║
║    validate              Validação completa do sistema    ║
║                                                            ║
║  INFO:                                                    ║
║    status                Estado do bot e módulos          ║
║    modules               Listar módulos carregados        ║
║    help                  Mostrar esta ajuda               ║
║                                                            ║
║  DAEMON (opcional):                                       ║
║    daemon                Modo automático (30s ciclo)      ║
║    daemon-stop           Parar daemon                     ║
║                                                            ║
║  ALL:                                                     ║
║    all                   Executar tudo (validate→cleanup→ ║
║                          sleep→notify)                    ║
╚══════════════════════════════════════════════════════════╝
HELP
}

# Listar módulos carregados
list_modules() {
    echo -e "${GREEN}Módulos carregados (${#LOADED_MODULES[@]}):${NC}"
    for module in "${LOADED_MODULES[@]}"; do
        echo "  ✅ $module"
    done
}

# Mostrar status
show_status() {
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     team-bot.sh — Status                                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "MAKAN72_HOME: $MAKAN72_HOME"
    echo "Módulos carregados: ${#LOADED_MODULES[@]}"
    echo "Config: $CONFIG"
    echo "Log: $LOG_FILE"
    echo ""
    
    # Chamar status de cada módulo
    for module in "${LOADED_MODULES[@]}"; do
        if type -t "${module}_status" &>/dev/null; then
            "${module}_status"
        fi
    done
}

# Executar tudo (sequencial)
run_all() {
    log "Executando pipeline completo..."
    local errors=0

    echo -e "${YELLOW}[1/7] Validando...${NC}"
    if ! validate_all 2>/dev/null; then
        echo -e "${RED}   ❌ Validação falhou${NC}"
        errors=$((errors + 1))
    fi

    echo -e "${YELLOW}[2/7] Limpando...${NC}"
    if ! cleanup_run 2>/dev/null; then
        echo -e "${RED}   ❌ Cleanup falhou${NC}"
        errors=$((errors + 1))
    fi

    echo -e "${YELLOW}[3/7] Consolidando memória...${NC}"
    if ! sleep_consolidate 2>/dev/null; then
        echo -e "${RED}   ❌ Consolidação falhou${NC}"
        errors=$((errors + 1))
    fi

    echo -e "${YELLOW}[4/7] Notificações...${NC}"
    if ! notify_status 2>/dev/null; then
        echo -e "${RED}   ❌ Notificações falharam${NC}"
        errors=$((errors + 1))
    fi

    echo -e "${YELLOW}[5/7] Peer reviews...${NC}"
    if type -t critique_run &>/dev/null; then
        critique_run 2>/dev/null || true
    else
        echo "   ⏭️ Módulo critique não carregado"
    fi

    echo -e "${YELLOW}[6/7] Guardrails...${NC}"
    if type -t guardrails_run &>/dev/null; then
        guardrails_run 2>/dev/null || true
    else
        echo "   ⏭️ Módulo guardrails não carregado"
    fi

    echo -e "${YELLOW}[7/7] Limpeza de sessões...${NC}"
    if type -t m72_clean_orphan_slots &>/dev/null; then
        m72_clean_orphan_slots 2>/dev/null || true
    fi
    if type -t m72_clean_old_heartbeats &>/dev/null; then
        m72_clean_old_heartbeats 2>/dev/null || true
    fi
    echo "   ✓ Sessões verificadas"

    log "Pipeline completo (erros: $errors)"

    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}⚠️  Pipeline completou com $errors erro(s)${NC}"
    else
        echo -e "${GREEN}✅ Pipeline completo sem erros${NC}"
    fi
}

# Rotação de log do daemon (chamada periodicamente dentro do loop)
_rotate_daemon_log() {
    local log_file="$MAKAN72_HOME/08-logs/team-bot-daemon.log"
    [[ -f "$log_file" ]] || return 0

    local line_count
    line_count=$(wc -l < "$log_file" 2>/dev/null || echo 0)
    [[ "$line_count" -lt 5000 ]] && return 0

    # 1. Dedup linhas consecutivas iguais (ruído do daemon)
    local dedup_tmp="${log_file}.dedup.$$"
    awk 'NR==1 || $0!=p {print} {p=$0}' "$log_file" > "$dedup_tmp" \
        && mv "$dedup_tmp" "$log_file" \
        || rm -f "$dedup_tmp"

    # 2. Re-verificar após dedup
    line_count=$(wc -l < "$log_file" 2>/dev/null || echo 0)
    [[ "$line_count" -lt 5000 ]] && return 0

    # 3. Arquivar tudo excepto as últimas 2000 linhas (NUNCA gzip o ficheiro activo)
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local archive="$MAKAN72_HOME/08-logs/team-bot-daemon.${timestamp}.log.gz"
    local keep_tmp="${log_file}.keep.$$"

    # Arquivar as linhas antigas
    head -n $((line_count - 2000)) "$log_file" | gzip > "$archive" 2>/dev/null || true

    # Manter apenas as últimas 2000 linhas no log activo (atomic move)
    tail -n 2000 "$log_file" > "$keep_tmp" && mv "$keep_tmp" "$log_file" \
        || rm -f "$keep_tmp"

    # 4. Limpar arquivos com mais de 7 dias
    find "$MAKAN72_HOME/08-logs" -name "team-bot-daemon.*.log.gz" -mtime +7 -delete 2>/dev/null

    log "Log rotation: arquivadas $((line_count - 2000)) linhas → $(basename "$archive")"
}

# Daemon mode
run_daemon() {
    local PID_FILE="$MAKAN72_HOME/08-logs/cache/team-bot-daemon.pid"
    local _log_last_rotate=0
    
    # Verificar se já está a correr
    if [[ -f "$PID_FILE" ]]; then
        local existing_pid=$(cat "$PID_FILE")
        if kill -0 "$existing_pid" 2>/dev/null; then
            echo -e "${YELLOW}Daemon já está a correr (PID $existing_pid)${NC}"
            echo "Parar com: bash 02-bots/team-bot.sh daemon-stop"
            return 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    # Guardar PID
    echo $$ > "$PID_FILE"
    
    log "Daemon iniciado (ciclo 30s, PID $$)"
    echo -e "${GREEN}Daemon iniciado (PID $$). Pressione Ctrl+C para parar.${NC}"
    
    # Trap para limpar PID file ao sair
    trap 'rm -f "$PID_FILE"; echo -e "${YELLOW}Daemon parado${NC}"' EXIT INT TERM
    
    while true; do
        # Verificar heartbeats
        if type -t heartbeat_run &>/dev/null; then
            heartbeat_run || true
        fi
        
        # Processar inbox
        if type -t inbox_run &>/dev/null; then
            inbox_run || true
        fi

        # Guardar tab actual para dispatch poder voltar
        if type -t _dispatch_save_current_tab &>/dev/null; then
            _dispatch_save_current_tab "Monitor" 2>/dev/null || true
        fi

        # Detectar ficheiros novos na inbox
        if type -t inbox_watch &>/dev/null; then
            inbox_watch || true
        fi
        
        # Processar handoffs
        if type -t handoff_run &>/dev/null; then
            handoff_run || true
        fi

        # Verificar rotação de log a cada 5 minutos
        local _log_now
        _log_now=$(date +%s)
        if (( _log_now - _log_last_rotate >= 300 )); then
            _rotate_daemon_log
            _log_last_rotate=$_log_now
        fi

        sleep 30
    done
}

# Parar daemon
stop_daemon() {
    PID_FILE="$MAKAN72_HOME/08-logs/cache/team-bot-daemon.pid"
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
        echo -e "${GREEN}Daemon parado${NC}"
    else
        echo -e "${YELLOW}Daemon não está a correr${NC}"
    fi
}

# Validação completa
validate_all() {
    local failed=0
    echo -e "${YELLOW}Executando validação completa...${NC}"
    # Chamar validação de cada módulo
    for module in "${LOADED_MODULES[@]}"; do
        local validate_fn="${module}_validate"
        if type -t "$validate_fn" &>/dev/null; then
            log "Validando módulo: $module"
            if ! "$validate_fn"; then
                log "ERRO: módulo $module falhou validação"
                failed=$((failed + 1))
            fi
        fi
    done
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}Validação completa${NC}"
        return 0
    else
        echo -e "${RED}Validação falhou: $failed módulo(s) com erros${NC}"
        return 1
    fi
}

# Main
main() {
    local command="${1:-help}"
    shift || true
    
    log "Comando recebido: $command"
    
    case "$command" in
        # Operações core
        process-inbox)
            if type -t inbox_run &>/dev/null; then
                inbox_run
            else
                echo -e "${RED}❌ Módulo inbox não disponível${NC}"
            fi
            ;;
        check-heartbeats)
            if type -t heartbeat_run &>/dev/null; then
                heartbeat_run
            else
                echo -e "${RED}❌ Módulo heartbeat não disponível${NC}"
            fi
            ;;
        process-handoffs)
            if type -t handoff_run &>/dev/null; then
                handoff_run
            else
                echo -e "${RED}❌ Módulo handoff não disponível${NC}"
            fi
            ;;
        check-guardrails)
            if type -t guardrails_check &>/dev/null; then
                guardrails_check "${1:-}"
            else
                echo -e "${RED}❌ Módulo guardrails não disponível${NC}"
            fi
            ;;
        
        # Manutenção
        cleanup)
            if type -t cleanup_run &>/dev/null; then
                cleanup_run
            else
                echo -e "${RED}❌ Módulo cleanup não disponível${NC}"
            fi
            ;;
        sleep)
            if type -t sleep_consolidate &>/dev/null; then
                sleep_consolidate
            else
                echo -e "${RED}❌ Módulo sleep não disponível${NC}"
            fi
            ;;
        notify)
            if type -t notify_send &>/dev/null; then
                notify_send "${1:-CEO}" "${2:-Sem mensagem}"
            else
                echo -e "${RED}❌ Módulo notify não disponível${NC}"
            fi
            ;;
        
        # Validação
        validate)
            validate_all
            ;;
        
        # Info
        status)
            show_status
            ;;
        modules)
            list_modules
            ;;
        # Documentacao
        docs)
            cmd_docs
            ;;
        
        # Relatorio
        report)
            cmd_report
            ;;

        help|--help|-h)
            show_help
            ;;
        
        # Daemon
        daemon)
            run_daemon
            ;;
        daemon-stop)
            stop_daemon
            ;;
        
        # All
        all)
            run_all
            ;;
        
        # Crítica (para módulos que precisam)
        # Inbox
        inbox)
            if type -t inbox_run &>/dev/null; then
                inbox_run
            else
                echo -e "${RED}❌ Módulo inbox não disponível${NC}"
            fi
            ;;

        critique)
            if type -t critique_check &>/dev/null; then
                critique_check "${1:-}"
            else
                echo -e "${YELLOW}⚠️  Módulo critique não disponível${NC}"
            fi
            ;;
        
        # Visualize
        visualize)
            if type -t visualizer_generate &>/dev/null; then
                visualizer_generate
            else
                echo -e "${YELLOW}⚠️  Módulo visualizer não disponível${NC}"
            fi
            ;;
        
        # Aliases intuitivos
        health)
            bash "$MAKAN72_HOME/05-scripts/utils/health-check.sh" "${1:-full}"
            ;;
        heartbeat|heartbeats)
            if type -t heartbeat_run &>/dev/null; then
                heartbeat_run
            else
                echo -e "${RED}❌ Módulo heartbeat não disponível${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Comando desconhecido: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Executar main
main "$@"
