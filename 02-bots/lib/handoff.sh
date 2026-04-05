#!/usr/bin/env bash
# handoff.sh — Processar handoffs entre agentes
# Módulo do team-bot.sh
# Autor: QWEN/GEMINI (MC)
# Data: 2026-03-03

# === DEPENDÊNCIAS ===
# Requer: jq
# Requer módulos: nenhum

# === CONFIGURAÇÃO ===
HANDOFF_ENABLED="${HANDOFF_ENABLED:-true}"

# === FUNÇÕES PÚBLICAS ===
handoff_run() {
    [[ "$HANDOFF_ENABLED" != "true" ]] && return 0
    
    echo "=== HANDOFF PROCESSING ==="
    
    local handoff_dir="$MAKAN72_HOME/04-bus/handoff"
    if [[ ! -d "$handoff_dir" ]]; then
        echo "WARNING: Pasta handoff não existe"
        return 0
    fi
    
    local processed=0
    
    # Listar handoffs não lidos
    for handoff_file in "$handoff_dir"/*.json; do
        [[ -f "$handoff_file" ]] || continue
        
        # Ignorar já lidos
        [[ "$handoff_file" == *.read ]] && continue
        
        local id from to type
        id=$(jq -r '.id // "unknown"' "$handoff_file" 2>/dev/null)
        from=$(jq -r '.from // "unknown"' "$handoff_file" 2>/dev/null)
        to=$(jq -r '.to // "unknown"' "$handoff_file" 2>/dev/null)
        type=$(jq -r '.type // "unknown"' "$handoff_file" 2>/dev/null)
        
        echo "  📬 Handoff: $id ($from → $to)"
        echo "     Tipo: $type"
        
        # Notificar destinatário
        local notify_file="$MAKAN72_HOME/03-inbox/$to/pending/handoff_${id}.md"
        if [[ -d "$(dirname "$notify_file")" ]]; then
            cat > "$notify_file" << EOF
# Handoff Recebido

**ID:** $id
**De:** $from
**Para:** $to
**Tipo:** $type
**Data:** $(portable_date_iso)

---

## Contexto

$(jq -r '.context.summary // "Sem resumo"' "$handoff_file" 2>/dev/null)

## Próximos Passos

$(jq -r '.context.next_steps[] // "- Verificar handoff"' "$handoff_file" 2>/dev/null)

---

## RESPOSTA OBRIGATÓRIA (ACK Protocol)

Deves confirmar recepção desta tarefa. Usa os comandos:

\`\`\`bash
# Para ACEITAR:
handoff_ack "$id" "$to" "ACCEPTED" "Tarefa aceite para revisão"

# Para REJEITAR:
handoff_ack "$id" "$to" "REJECTED" "Motivo da rejeição"
\`\`\`

**Nota:** Se não responderes, o remetente não saberá se aceitaste a tarefa.
EOF
            echo "     ✅ Notificação enviada para $to"
        fi
        
        # Marcar como lido
        mv "$handoff_file" "${handoff_file}.read"
        processed=$((processed + 1))
    done
    
    if [[ $processed -eq 0 ]]; then
        echo "Nenhum handoff pendente"
    else
        echo "TOTAL: $processed handoff(s) processado(s)"
    fi
}

handoff_status() {
    local pending=0
    local handoff_dir="$MAKAN72_HOME/04-bus/handoff"
    
    if [[ -d "$handoff_dir" ]]; then
        pending=$(find "$handoff_dir" -maxdepth 1 -name "*.json" ! -name "*.read" 2>/dev/null | wc -l)
    fi
    
    echo "handoff: enabled=$HANDOFF_ENABLED, pending=$pending"
}


# === HANDOFF ACK — Agente confirma recepção de tarefa ===
# Uso: handoff_ack <handoff_id> <agent_code> <decision> [mensagem]
#   decision: ACCEPTED ou REJECTED
handoff_ack() {
    local handoff_id="${1:?Uso: handoff_ack <id> <agent> <ACCEPTED|REJECTED> [msg]}"
    local agent_code="${2:?Falta agent_code}"
    local decision="${3:?Falta decision (ACCEPTED|REJECTED)}"
    local message="${4:-}"

    # Validar decision
    if [[ "$decision" != "ACCEPTED" && "$decision" != "REJECTED" ]]; then
        echo "ERRO: decision deve ser ACCEPTED ou REJECTED (recebido: $decision)"
        return 1
    fi

    local ack_dir="$MAKAN72_HOME/04-bus/handoff/acks"
    mkdir -p "$ack_dir"

    local timestamp
    timestamp=$(portable_date_iso)

    local ack_file="$ack_dir/ack_${handoff_id}_${agent_code}.json"

    cat > "$ack_file" << ACKEOF
{
  "handoff_id": "$handoff_id",
  "agent": "$agent_code",
  "decision": "$decision",
  "message": "$message",
  "timestamp": "$timestamp"
}
ACKEOF

    echo "  ✅ ACK registado: $handoff_id → $decision ($agent_code)"

    # Se REJECTED, notificar o remetente original
    if [[ "$decision" == "REJECTED" ]]; then
        # Tentar encontrar o handoff original para saber quem enviou
        local original_from=""
        local original_file="$MAKAN72_HOME/04-bus/handoff/${handoff_id}*.json.read"
        for f in $original_file; do
            [[ -f "$f" ]] || continue
            original_from=$(jq -r '.from // ""' "$f" 2>/dev/null)
            break
        done

        if [[ -n "$original_from" && -d "$MAKAN72_HOME/03-inbox/$original_from/pending" ]]; then
            cat > "$MAKAN72_HOME/03-inbox/$original_from/pending/handoff_REJECTED_${handoff_id}.md" << REJEOF
# Handoff REJEITADO

**ID:** $handoff_id
**Rejeitado por:** $agent_code
**Motivo:** ${message:-Sem motivo especificado}
**Data:** $timestamp

Reenvia para outro agente ou ajusta a tarefa.
REJEOF
            echo "  📬 Notificação de rejeição enviada para $original_from"
        fi
    fi
}

# === HANDOFF ACK STATUS — Ver ACKs pendentes/registados ===
handoff_ack_status() {
    local ack_dir="$MAKAN72_HOME/04-bus/handoff/acks"

    if [[ ! -d "$ack_dir" ]]; then
        echo "handoff_ack: nenhum ACK registado (pasta não existe)"
        return 0
    fi

    local total accepted rejected
    total=$(find "$ack_dir" -name "ack_*.json" 2>/dev/null | wc -l)
    accepted=$(grep -l '"ACCEPTED"' "$ack_dir"/ack_*.json 2>/dev/null | wc -l)
    rejected=$(grep -l '"REJECTED"' "$ack_dir"/ack_*.json 2>/dev/null | wc -l)

    echo "handoff_ack: total=$total, accepted=$accepted, rejected=$rejected"
}
