#!/usr/bin/env bash
# notify.sh — Enviar notificações
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: nenhum
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
NOTIFY_ENABLED="${NOTIFY_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
notify_run() {
    [[ "$NOTIFY_ENABLED" != "true" ]] && return 0
    
    echo "=== NOTIFY ==="
    echo "Sistema de notificações pronto"
    echo "Uso: notify_send <destinatário> <mensagem>"
    echo "     notify_ceo <mensagem>"
    echo "     notify_agent <agente> <mensagem>"
}

notify_send() {
    local recipient="$1"
    local message="$2"
    local level="${3:-INFO}"
    
    [[ -z "$recipient" || -z "$message" ]] && return 1
    
    # Criar alerta em 04-bus/alerts/
    local alert_file="$MAKAN72_HOME/04-bus/alerts/notify_$(date +%Y%m%d_%H%M%S).json"
    cat > "$alert_file" << EOF
{
  "type": "notification",
  "recipient": "$recipient",
  "level": "$level",
  "message": "$message",
  "timestamp": "$(portable_date_iso)"
}
EOF
    
    # Se for CEO, criar notificação na inbox
    if [[ "$recipient" == "ceo" || "$recipient" == "CEO" ]]; then
        local inbox_file="$MAKAN72_HOME/03-inbox/ceo/alerts/notify_$(date +%Y%m%d_%H%M%S).md"
        cat > "$inbox_file" << EOF
# Notificação [$level]

**Data:** $(portable_date_iso)
**Para:** CEO

---

## Mensagem

$message
EOF
        echo "✅ Notificação enviada para CEO"
    else
        # Notificar agente específico
        local inbox_file="$MAKAN72_HOME/03-inbox/$recipient/pending/notify_$(date +%Y%m%d_%H%M%S).md"
        if [[ -d "$(dirname "$inbox_file")" ]]; then
            cat > "$inbox_file" << EOF
# Notificação [$level]

**Data:** $(portable_date_iso)
**Para:** $recipient

---

## Mensagem

$message
EOF
            echo "✅ Notificação enviada para $recipient"
        else
            echo "⚠️ Inbox de $recipient não existe"
        fi
    fi
    
    # Output no terminal
    echo "[$level] $message"
}

notify_ceo() {
    local message="$1"
    notify_send "ceo" "$message" "INFO"
}

notify_agent() {
    local agent="$1"
    local message="$2"
    notify_send "$agent" "$message" "INFO"
}

notify_status() {
    local alerts_count=0
    alerts_count=$(find "$MAKAN72_HOME/04-bus/alerts" -name "*.json" 2>/dev/null | wc -l)
    echo "notify: enabled=$NOTIFY_ENABLED, alerts=$alerts_count"
}
