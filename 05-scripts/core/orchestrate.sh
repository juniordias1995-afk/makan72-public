#!/usr/bin/env bash
# orchestrate.sh — Motor de fila de execução (Bastão com Contrato)
# Autor: QWEN (MC)
# Data: 2026-04-04
# Versão: 1.0.0

set -uo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
PLANO_FILE="$MAKAN72_HOME/04-bus/plano.yaml"
BASTAO_FILE="$MAKAN72_HOME/04-bus/bastao.json"
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"
HANDOFF_DIR="$MAKAN72_HOME/04-bus/handoff"
ACKS_DIR="$HANDOFF_DIR/acks"

# ============================================================================
# HELPERS PYTHON PARA YAML
# ============================================================================

python_yaml_load() {
    local file="$1"
    python3 -c "
import yaml, json, sys
with open('$file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data, indent=2))
" 2>/dev/null
}

python_yaml_update_task() {
    local file="$1"
    local task_id="$2"
    local field="$3"
    local value="$4"
    python3 -c "
import yaml
with open('$file') as f:
    data = yaml.safe_load(f)
for t in data.get('tarefas', []):
    if t.get('id') == '$task_id':
        t['$field'] = '$value'
        break
with open('$file', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null
}

python_yaml_update_plano_status() {
    local file="$1"
    local status="$2"
    python3 -c "
import yaml
with open('$file') as f:
    data = yaml.safe_load(f)
data['plano']['status'] = '$status'
with open('$file', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null
}

python_yaml_get_task() {
    local file="$1"
    local task_id="$2"
    python3 -c "
import yaml, json
with open('$file') as f:
    data = yaml.safe_load(f)
for t in data.get('tarefas', []):
    if t.get('id') == '$task_id':
        print(json.dumps(t))
        break
" 2>/dev/null
}

python_yaml_get_plano_info() {
    local file="$1"
    python3 -c "
import yaml, json
with open('$file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data.get('plano', {})))
" 2>/dev/null
}

python_yaml_get_all_tasks() {
    local file="$1"
    python3 -c "
import yaml, json
with open('$file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data.get('tarefas', [])))
" 2>/dev/null
}

python_yaml_update_bastao() {
    local file="$1"
    local tarefa="$2"
    local agente="$3"
    python3 -c "
import yaml
with open('$file') as f:
    data = yaml.safe_load(f)
data['bastao']['tarefa_actual'] = '$tarefa'
data['bastao']['agente_actual'] = '$agente'
with open('$file', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null
}

python_yaml_detect_cycle() {
    local file="$1"
    python3 -c "
import yaml, sys

with open('$file') as f:
    data = yaml.safe_load(f)

tarefas = {t['id']: t.get('depende_de', []) for t in data.get('tarefas', [])}

def has_cycle(task_id, visited, rec_stack):
    visited.add(task_id)
    rec_stack.add(task_id)
    for dep in tarefas.get(task_id, []):
        if dep not in visited:
            if has_cycle(dep, visited, rec_stack):
                return True
        elif dep in rec_stack:
            return True
    rec_stack.remove(task_id)
    return False

visited = set()
rec_stack = set()
for task_id in tarefas:
    if task_id not in visited:
        if has_cycle(task_id, visited, rec_stack):
            print('CYCLE_DETECTED')
            sys.exit(1)
print('NO_CYCLE')
" 2>/dev/null
}

python_yaml_add_task_result() {
    local file="$1"
    local task_id="$2"
    local status="$3"
    local resultado="$4"
    local tentativas="$5"
    python3 -c "
import yaml
with open('$file') as f:
    data = yaml.safe_load(f)
for t in data.get('tarefas', []):
    if t.get('id') == '$task_id':
        t['status'] = '$status'
        t['resultado'] = '''$resultado'''
        t['tentativas'] = $tentativas
        break
with open('$file', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null
}

# ============================================================================
# HELPERS BASH
# ============================================================================

show_help() {
    cat << 'EOF'
orchestrate.sh — Motor de fila de execução (Bastão com Contrato)

Uso: orchestrate.sh <comando> [opções]

COMANDOS:
  plan <ficheiro.yaml>    Carregar/validar plano
  start                   Iniciar execução
  status                  Ver estado actual
  ack <tarefa> <DECISAO> "<resultado>"  Registar ACK (DONE|FAILED|BLOCKED|REJECTED)
  next                    Avançar bastão manualmente
  skip <tarefa>           Saltar tarefa
  pause                   Pausar fila
  resume                  Retomar fila
  cancel                  Cancelar plano
  history                 Listar planos arquivados

EXEMPLOS:
  orchestrate.sh plan plano.yaml
  orchestrate.sh start
  orchestrate.sh ack T1 DONE "tarefa concluída"
  orchestrate.sh status
EOF
}

log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ ERRO: $1" >&2
}

log_warn() {
    echo "⚠️  $1"
}

# Verificar se agente existe em agents.json
agent_exists() {
    local agent_code="$1"
    local status
    status=$(jq -r --arg code "$agent_code" '.agents[] | select(.code==$code) | .status' "$AGENTS_FILE" 2>/dev/null)
    [[ "$status" == "active" ]] || [[ "$status" == "paused" ]]
}

# Obter timestamp ISO
get_timestamp() {
    date +%Y-%m-%dT%H:%M:%S%z
}

# Gerar ID de plano
generate_plano_id() {
    echo "PLANO-$(date +%Y%m%d_%H%M%S)"
}

# ============================================================================
# SUBCOMANDO: plan
# ============================================================================

cmd_plan() {
    local yaml_file="$1"
    
    if [[ -z "$yaml_file" ]]; then
        log_error "Uso: orchestrate.sh plan <ficheiro.yaml>"
        exit 1
    fi
    
    if [[ ! -f "$yaml_file" ]]; then
        log_error "Ficheiro não encontrado: $yaml_file"
        exit 1
    fi
    
    log_info "Validando plano: $yaml_file"
    
    # 1. Validar estrutura YAML básica
    local plano_data
    plano_data=$(python_yaml_load "$yaml_file")
    if [[ -z "$plano_data" ]]; then
        log_error "YAML inválido"
        exit 1
    fi
    
    # 2. Validar agentes
    local tarefas_json
    tarefas_json=$(python_yaml_get_all_tasks "$yaml_file")
    
    local agents_list
    agents_list=$(echo "$tarefas_json" | jq -r '.[].agente' 2>/dev/null)
    
    for agent in $agents_list; do
        if ! agent_exists "$agent"; then
            log_error "Agente '$agent' não encontrado em agents.json"
            exit 1
        fi
    done
    log_success "Todos os agentes válidos"
    
    # 3. Validar dependências circulares
    local cycle_check
    cycle_check=$(python_yaml_detect_cycle "$yaml_file")
    if [[ "$cycle_check" == "CYCLE_DETECTED" ]]; then
        log_error "Dependência circular detectada"
        exit 1
    fi
    log_success "Sem dependências circulares"
    
    # 4. Verificar se já existe plano em_curso
    if [[ -f "$PLANO_FILE" ]]; then
        local current_status
        current_status=$(python_yaml_get_plano_info "$PLANO_FILE" | jq -r '.status' 2>/dev/null)
        if [[ "$current_status" == "em_curso" ]]; then
            log_error "Já existe um plano em execução. Cancela ou conclui o actual primeiro."
            exit 1
        fi
    fi
    
    # 5. Copiar para 04-bus/plano.yaml
    cp "$yaml_file" "$PLANO_FILE"
    log_success "Plano copiado para $PLANO_FILE"
    
    # 6. Criar bastao.json
    local plano_id
    plano_id=$(python_yaml_get_plano_info "$PLANO_FILE" | jq -r '.id' 2>/dev/null)
    
    cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "",
  "agente_actual": "",
  "inicio": "",
  "tentativa": 0,
  "status": "livre"
}
EOF
    log_success "Bastão inicializado"
    
    # 7. Output resumo
    local titulo
    titulo=$(python_yaml_get_plano_info "$PLANO_FILE" | jq -r '.titulo' 2>/dev/null)
    local num_tarefas
    num_tarefas=$(echo "$tarefas_json" | jq 'length' 2>/dev/null)
    local agentes_unicos
    agentes_unicos=$(echo "$tarefas_json" | jq -r '.[].agente' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    log_success "Plano carregado: $titulo ($num_tarefas tarefas, agentes: $agentes_unicos)"
}

# ============================================================================
# SUBCOMANDO: start
# ============================================================================

find_next_task() {
    # Retorna ID da próxima tarefa elegível
    python3 -c "
import yaml, json

with open('$PLANO_FILE') as f:
    data = yaml.safe_load(f)

tarefas = data.get('tarefas', [])
bastao = data.get('bastao', {})
tarefa_actual = bastao.get('tarefa_actual', '')

# Construir mapa de tarefas concluídas
concluidas = set()
for t in tarefas:
    if t.get('status') == 'concluida':
        concluidas.add(t['id'])

# Encontrar tarefas elegíveis
elegiveis = []
for t in tarefas:
    if t.get('status') != 'pendente':
        continue
    # Verificar dependências
    deps = t.get('depende_de', [])
    if all(d in concluidas for d in deps):
        elegiveis.append((t.get('prioridade', 999), t['id'], t))

if not elegiveis:
    print('')
else:
    elegiveis.sort()
    print(elegiveis[0][1])  # Retorna ID da tarefa com menor prioridade
" 2>/dev/null
}

dispatch_task() {
    local tarefa_id="$1"
    
    # Obter info da tarefa
    local task_json
    task_json=$(python_yaml_get_task "$PLANO_FILE" "$tarefa_id")
    
    local agente prompt prioridade max_retries
    agente=$(echo "$task_json" | jq -r '.agente' 2>/dev/null)
    prompt=$(echo "$task_json" | jq -r '.prompt' 2>/dev/null)
    prioridade=$(echo "$task_json" | jq -r '.prioridade' 2>/dev/null)
    max_retries=$(echo "$task_json" | jq -r '.max_retries' 2>/dev/null)
    
    # Obter info do plano
    local plano_info
    plano_info=$(python_yaml_get_plano_info "$PLANO_FILE")
    local plano_id titulo
    plano_id=$(echo "$plano_info" | jq -r '.id' 2>/dev/null)
    titulo=$(echo "$plano_info" | jq -r '.titulo' 2>/dev/null)
    
    # Obter tarefa anterior (se existir)
    local task_anterior_json=""
    local agente_anterior="" resultado_anterior=""
    
    # Simplificação: procurar tarefa com ID anterior (T1 antes de T2)
    local anterior_id=""
    local num_id=$(echo "$tarefa_id" | sed 's/T//')
    if [[ $num_id -gt 1 ]]; then
        anterior_id="T$((num_id - 1))"
        task_anterior_json=$(python_yaml_get_task "$PLANO_FILE" "$anterior_id" 2>/dev/null)
        if [[ -n "$task_anterior_json" ]]; then
            agente_anterior=$(echo "$task_anterior_json" | jq -r '.agente' 2>/dev/null)
            resultado_anterior=$(echo "$task_anterior_json" | jq -r '.resultado' 2>/dev/null)
        fi
    fi
    
    # Criar envelope TASK-*.json
    local task_id_full="${plano_id}_${tarefa_id}"
    local envelope_file="$HANDOFF_DIR/TASK-${task_id_full}.json"
    
    local contexto_anterior="null"
    if [[ -n "$task_anterior_json" && "$resultado_anterior" != "null" && -n "$resultado_anterior" ]]; then
        contexto_anterior=$(cat << EOF
{
  "tarefa": "$anterior_id",
  "agente": "$agente_anterior",
  "resultado": "$resultado_anterior"
}
EOF
)
    fi
    
    local timestamp
    timestamp=$(get_timestamp)
    
    cat > "$envelope_file" << EOF
{
  "task_id": "$task_id_full",
  "plano_id": "$plano_id",
  "tarefa_id": "$tarefa_id",
  "agente": "$agente",
  "prompt": "$prompt",
  "contexto_anterior": $contexto_anterior,
  "max_retries": $max_retries,
  "tentativa": 1,
  "timestamp": "$timestamp"
}
EOF
    
    # Criar contrato no inbox do agente
    local inbox_dir="$MAKAN72_HOME/03-inbox/$agente/pending"
    mkdir -p "$inbox_dir"
    local contrato_file="$inbox_dir/TASK_${tarefa_id}.md"
    
    local contexto_texto
    if [[ "$contexto_anterior" == "null" ]]; then
        contexto_texto="Esta é a primeira tarefa do plano. Sem contexto anterior."
    else
        contexto_texto="**Agente anterior:** $agente_anterior
**Resultado:** $resultado_anterior"
    fi
    
    cat > "$contrato_file" << EOF
# TAREFA — $titulo

**Plano:** $plano_id
**Tarefa:** $tarefa_id (prioridade $prioridade)
**Para:** $agente
**Retries:** max $max_retries

---

## MISSÃO

$prompt

---

## CONTEXTO DA TAREFA ANTERIOR

$contexto_texto

---

## QUANDO TERMINARES

Confirma conclusão:
  orchestrate.sh ack $tarefa_id DONE "descricao do resultado"

Se falhaste:
  orchestrate.sh ack $tarefa_id FAILED "descricao do erro"

Se estás bloqueado (precisas de input):
  orchestrate.sh ack $tarefa_id BLOCKED "o que precisas"
EOF
    
    # Actualizar bastao.json
    cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "$tarefa_id",
  "agente_actual": "$agente",
  "inicio": "$timestamp",
  "tentativa": 1,
  "status": "dispatched"
}
EOF
    
    # Actualizar plano.yaml
    python_yaml_update_task "$PLANO_FILE" "$tarefa_id" "status" "em_curso"
    python_yaml_update_bastao "$PLANO_FILE" "$tarefa_id" "$agente"
    python_yaml_update_plano_status "$PLANO_FILE" "em_curso"
    
    # Notificar via dispatch.sh (se disponível)
    if [[ -f "$MAKAN72_HOME/02-bots/lib/dispatch.sh" ]]; then
        (
            source "$MAKAN72_HOME/02-bots/lib/dispatch.sh" 2>/dev/null
            dispatch_notify "$agente" "TASK_${tarefa_id}.md" "orchestrate" 2>/dev/null || true
        )
    fi
    
    log_success "Bastão entregue a $agente: tarefa $tarefa_id — ${prompt:0:50}..."
}

cmd_start() {
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado. Usa 'orchestrate.sh plan <ficheiro.yaml>'"
        exit 1
    fi
    
    local plano_status
    plano_status=$(python_yaml_get_plano_info "$PLANO_FILE" | jq -r '.status' 2>/dev/null)
    
    if [[ "$plano_status" != "pendente" && "$plano_status" != "pausado" ]]; then
        log_error "Plano não está pendente ou pausado (status: $plano_status)"
        exit 1
    fi
    
    # Actualizar status para em_curso
    python_yaml_update_plano_status "$PLANO_FILE" "em_curso"
    log_info "Plano iniciado"
    
    # Encontrar primeira tarefa elegível
    local next_task
    next_task=$(find_next_task)
    
    if [[ -z "$next_task" ]]; then
        log_warn "Nenhuma tarefa elegível (dependências não satisfeitas)"
        exit 1
    fi
    
    dispatch_task "$next_task"
}

# ============================================================================
# SUBCOMANDO: status
# ============================================================================

cmd_status() {
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado"
        exit 1
    fi
    
    local plano_info tarefas_json bastao_info
    plano_info=$(python_yaml_get_plano_info "$PLANO_FILE")
    tarefas_json=$(python_yaml_get_all_tasks "$PLANO_FILE")
    
    if [[ -f "$BASTAO_FILE" ]]; then
        bastao_info=$(cat "$BASTAO_FILE" | jq -c '.' 2>/dev/null)
    else
        bastao_info='{"tarefa_actual":"","agente_actual":"","status":"livre"}'
    fi
    
    local plano_id titulo status criado_por
    plano_id=$(echo "$plano_info" | jq -r '.id' 2>/dev/null)
    titulo=$(echo "$plano_info" | jq -r '.titulo' 2>/dev/null)
    status=$(echo "$plano_info" | jq -r '.status' 2>/dev/null)
    criado_por=$(echo "$plano_info" | jq -r '.criado_por' 2>/dev/null)
    
    echo ""
    echo "=== PLANO: $titulo ($plano_id) ==="
    echo "Status: $status | Criado por: $criado_por"
    echo ""
    echo "TAREFAS:"
    
    local tarefa_actual bastao_agente
    tarefa_actual=$(echo "$bastao_info" | jq -r '.tarefa_actual' 2>/dev/null)
    bastao_agente=$(echo "$bastao_info" | jq -r '.agente_actual' 2>/dev/null)
    
    echo "$tarefas_json" | jq -r '.[] | "  \(.id) [\(.agente)]   \(.status)   — \"\(.prompt)\""' 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q "\[$tarefa_actual\]"; then
            echo -e "$line ← BASTÃO"
        else
            echo "$line"
        fi
    done
    
    echo ""
    if [[ -n "$tarefa_actual" && "$tarefa_actual" != "" && "$tarefa_actual" != "null" ]]; then
        local bastao_status
        bastao_status=$(echo "$bastao_info" | jq -r '.status' 2>/dev/null)
        echo "BASTÃO: $bastao_agente ($tarefa_actual) — $bastao_status"
    else
        echo "BASTÃO: livre"
    fi
    echo ""
}

# ============================================================================
# SUBCOMANDO: ack
# ============================================================================

cmd_ack() {
    local tarefa_id="$1"
    local decision="$2"
    local resultado="${3:-}"
    
    if [[ -z "$tarefa_id" || -z "$decision" ]]; then
        log_error "Uso: orchestrate.sh ack <tarefa_id> <DONE|FAILED|BLOCKED|REJECTED> \"<resultado>\""
        exit 1
    fi
    
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado"
        exit 1
    fi
    
    # Validar decision
    case "$decision" in
        DONE|FAILED|BLOCKED|REJECTED) ;;
        *)
            log_error "Decision inválida: $decision (usa DONE, FAILED, BLOCKED, ou REJECTED)"
            exit 1
            ;;
    esac
    
    # Obter info do plano e bastão
    local plano_info bastao_info
    plano_info=$(python_yaml_get_plano_info "$PLANO_FILE")
    local plano_id
    plano_id=$(echo "$plano_info" | jq -r '.id' 2>/dev/null)
    
    if [[ -f "$BASTAO_FILE" ]]; then
        bastao_info=$(cat "$BASTAO_FILE")
    else
        log_error "Bastão não encontrado"
        exit 1
    fi
    
    local tarefa_actual bastao_agente
    tarefa_actual=$(echo "$bastao_info" | jq -r '.tarefa_actual' 2>/dev/null)
    bastao_agente=$(echo "$bastao_info" | jq -r '.agente_actual' 2>/dev/null)
    
    # Criar ficheiro ACK
    local task_id_full="${plano_id}_${tarefa_id}"
    local ack_file="$ACKS_DIR/ack_TASK-${task_id_full}.json"
    local timestamp
    timestamp=$(get_timestamp)
    
    cat > "$ack_file" << EOF
{
  "task_id": "$task_id_full",
  "agente": "$bastao_agente",
  "decision": "$decision",
  "resultado": "$resultado",
  "timestamp": "$timestamp"
}
EOF
    
    log_success "ACK registado: $tarefa_id → $decision"
    
    # Processar por decision
    case "$decision" in
        DONE)
            # Obter max_retries da tarefa
            local task_json tentativas max_retries agente
            task_json=$(python_yaml_get_task "$PLANO_FILE" "$tarefa_id")
            tentativas=$(echo "$task_json" | jq -r '.tentativas' 2>/dev/null)
            max_retries=$(echo "$task_json" | jq -r '.max_retries' 2>/dev/null)
            agente=$(echo "$task_json" | jq -r '.agente' 2>/dev/null)
            
            # Actualizar tarefa como concluída
            python_yaml_add_task_result "$PLANO_FILE" "$tarefa_id" "concluida" "$resultado" "$tentativas"
            
            # Encontrar próxima tarefa
            local next_task
            next_task=$(find_next_task)
            
            if [[ -n "$next_task" ]]; then
                dispatch_task "$next_task"
            else
                # Verificar se todas estão concluídas
                local restantes
                restantes=$(python3 -c "
import yaml
with open('$PLANO_FILE') as f:
    data = yaml.safe_load(f)
for t in data.get('tarefas', []):
    if t.get('status') not in ['concluida', 'ignorada']:
        print('PENDENTES')
        break
else:
    print('NONE')
" 2>/dev/null)
                
                if [[ "$restantes" == "NONE" ]]; then
                    python_yaml_update_plano_status "$PLANO_FILE" "concluido"
                    cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "",
  "agente_actual": "",
  "inicio": "",
  "tentativa": 0,
  "status": "livre"
}
EOF
                    log_success "Plano concluído! Bastão livre."
                else
                    log_warn "Não há próxima tarefa elegível (dependências não satisfeitas)"
                    cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "",
  "agente_actual": "",
  "inicio": "",
  "tentativa": 0,
  "status": "livre"
}
EOF
                fi
            fi
            ;;
            
        FAILED)
            # Obter info da tarefa
            local task_json tentativas max_retries agente
            task_json=$(python_yaml_get_task "$PLANO_FILE" "$tarefa_id")
            tentativas=$(echo "$task_json" | jq -r '.tentativas // 0' 2>/dev/null)
            max_retries=$(echo "$task_json" | jq -r '.max_retries' 2>/dev/null)
            agente=$(echo "$task_json" | jq -r '.agente' 2>/dev/null)
            
            tentativas=$((tentativas + 1))
            
            if [[ $tentativas -lt $max_retries ]]; then
                # Retry
                log_warn "Tarefa falhou. Retry $tentativas/$max_retries"
                
                # Usar retry.sh se existir
                if [[ -x "$MAKAN72_HOME/05-scripts/utils/retry.sh" ]]; then
                    bash "$MAKAN72_HOME/05-scripts/utils/retry.sh" "$agente" echo "Retry da tarefa $tarefa_id: $resultado" &
                fi
                
                # Actualizar tentativas
                python_yaml_add_task_result "$PLANO_FILE" "$tarefa_id" "em_curso" "$resultado" "$tentativas"
                
                # Actualizar bastão
                cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "$tarefa_id",
  "agente_actual": "$agente",
  "inicio": "$timestamp",
  "tentativa": $tentativas,
  "status": "retry"
}
EOF
            else
                # Max retries atingido
                log_error "Max retries atingido para $tarefa_id"
                
                python_yaml_add_task_result "$PLANO_FILE" "$tarefa_id" "falhada" "$resultado" "$tentativas"
                python_yaml_update_plano_status "$PLANO_FILE" "falhado"
                
                # Alerta CEO
                local alerta_file="$MAKAN72_HOME/03-inbox/CEO/pending/ALERTA_PLANO_${plano_id}_${tarefa_id}.md"
                mkdir -p "$(dirname "$alerta_file")"
                cat > "$alerta_file" << EOF
# ALERTA — Plano Falhado

**Plano:** $plano_id
**Tarefa:** $tarefa_id
**Agente:** $agente
**Tentativas:** $tentativas/$max_retries

---

## Erro

$resultado

---

**Acção necessária:** Verificar tarefa e decidir se continua ou cancela.
EOF
                cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "",
  "agente_actual": "",
  "inicio": "",
  "tentativa": 0,
  "status": "livre"
}
EOF
            fi
            ;;
            
        BLOCKED|REJECTED)
            log_warn "Tarefa $tarefa_id: $decision"

            # Actualizar status da tarefa
            local task_json_br tentativas_br
            task_json_br=$(python_yaml_get_task "$PLANO_FILE" "$tarefa_id")
            tentativas_br=$(echo "$task_json_br" | jq -r '.tentativas' 2>/dev/null)
            local status_tarefa="bloqueada"
            [[ "$decision" == "REJECTED" ]] && status_tarefa="rejeitada"
            python_yaml_add_task_result "$PLANO_FILE" "$tarefa_id" "$status_tarefa" "$resultado" "${tentativas_br:-0}"

            python_yaml_update_plano_status "$PLANO_FILE" "pausado"
            
            # Alerta CEO
            local alerta_file="$MAKAN72_HOME/03-inbox/CEO/pending/ALERTA_PLANO_${plano_id}_${tarefa_id}.md"
            mkdir -p "$(dirname "$alerta_file")"
            cat > "$alerta_file" << EOF
# ALERTA — Tarefa $decision

**Plano:** $plano_id
**Tarefa:** $tarefa_id
**Agente:** $bastao_agente
**Decision:** $decision

---

## Motivo

$resultado

---

**Acção necessária:** Resolver bloqueio ou rejeição.
EOF
            cat > "$BASTAO_FILE" << EOF
{
  "plano_id": "$plano_id",
  "tarefa_actual": "",
  "agente_actual": "",
  "inicio": "",
  "tentativa": 0,
  "status": "livre"
}
EOF
            ;;
    esac
}

# ============================================================================
# SUBCOMANDO: next
# ============================================================================

cmd_next() {
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado"
        exit 1
    fi
    
    # Marcar tarefa actual como concluída (sem resultado)
    local bastao_info
    bastao_info=$(cat "$BASTAO_FILE" 2>/dev/null)
    local tarefa_actual
    tarefa_actual=$(echo "$bastao_info" | jq -r '.tarefa_actual' 2>/dev/null)
    
    if [[ -n "$tarefa_actual" && "$tarefa_actual" != "" && "$tarefa_actual" != "null" ]]; then
        python_yaml_add_task_result "$PLANO_FILE" "$tarefa_actual" "concluida" "" "0"
        log_info "Tarefa $tarefa_actual marcada como concluída"
    fi
    
    # Encontrar próxima
    local next_task
    next_task=$(find_next_task)
    
    if [[ -n "$next_task" ]]; then
        dispatch_task "$next_task"
    else
        log_warn "Não há próxima tarefa elegível"
    fi
}

# ============================================================================
# SUBCOMANDO: skip
# ============================================================================

cmd_skip() {
    local tarefa_id="$1"
    
    if [[ -z "$tarefa_id" ]]; then
        log_error "Uso: orchestrate.sh skip <tarefa_id>"
        exit 1
    fi
    
    python_yaml_update_task "$PLANO_FILE" "$tarefa_id" "status" "ignorada"
    log_success "Tarefa $tarefa_id ignorada"
    
    # Se era a actual, avançar
    local bastao_info
    bastao_info=$(cat "$BASTAO_FILE" 2>/dev/null)
    local tarefa_actual
    tarefa_actual=$(echo "$bastao_info" | jq -r '.tarefa_actual' 2>/dev/null)
    
    if [[ "$tarefa_actual" == "$tarefa_id" ]]; then
        cmd_next
    fi
}

# ============================================================================
# SUBCOMANDO: pause
# ============================================================================

cmd_pause() {
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado"
        exit 1
    fi
    
    python_yaml_update_plano_status "$PLANO_FILE" "pausado"
    log_success "Plano pausado. Usar 'orchestrate.sh resume' para retomar."
}

# ============================================================================
# SUBCOMANDO: resume
# ============================================================================

cmd_resume() {
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado"
        exit 1
    fi
    
    local plano_status
    plano_status=$(python_yaml_get_plano_info "$PLANO_FILE" | jq -r '.status' 2>/dev/null)
    
    if [[ "$plano_status" == "pausado" ]]; then
        python_yaml_update_plano_status "$PLANO_FILE" "em_curso"
        log_info "Plano retomado"
    fi
    
    # Verificar bastão
    local bastao_info
    bastao_info=$(cat "$BASTAO_FILE" 2>/dev/null)
    local bastao_status
    bastao_status=$(echo "$bastao_info" | jq -r '.status' 2>/dev/null)
    
    if [[ "$bastao_status" == "livre" ]]; then
        local next_task
        next_task=$(find_next_task)
        if [[ -n "$next_task" ]]; then
            dispatch_task "$next_task"
        else
            log_warn "Não há tarefa elegível"
        fi
    fi
}

# ============================================================================
# SUBCOMANDO: cancel
# ============================================================================

cmd_cancel() {
    if [[ ! -f "$PLANO_FILE" ]]; then
        log_error "Nenhum plano carregado"
        exit 1
    fi
    
    local plano_info
    plano_info=$(python_yaml_get_plano_info "$PLANO_FILE")
    local plano_id
    plano_id=$(echo "$plano_info" | jq -r '.id' 2>/dev/null)
    
    python_yaml_update_plano_status "$PLANO_FILE" "cancelado"
    
    # Mover para archive
    local archive_file="$MAKAN72_HOME/07-archive/planos/plano_${plano_id}.yaml"
    mv "$PLANO_FILE" "$archive_file"
    rm -f "$BASTAO_FILE"
    
    log_success "Plano cancelado e arquivado: $archive_file"
}

# ============================================================================
# SUBCOMANDO: history
# ============================================================================

cmd_history() {
    local archive_dir="$MAKAN72_HOME/07-archive/planos"
    
    if [[ ! -d "$archive_dir" ]] || [[ -z "$(ls -A "$archive_dir" 2>/dev/null)" ]]; then
        log_info "Nenhum plano arquivado"
        exit 0
    fi
    
    echo ""
    echo "=== HISTÓRICO DE PLANOS ==="
    echo ""
    
    for file in "$archive_dir"/plano_*.yaml; do
        [[ -f "$file" ]] || continue
        
        local info status titulo data
        info=$(python_yaml_get_plano_info "$file" 2>/dev/null)
        status=$(echo "$info" | jq -r '.status' 2>/dev/null)
        titulo=$(echo "$info" | jq -r '.titulo' 2>/dev/null)
        data=$(echo "$info" | jq -r '.data' 2>/dev/null)
        
        echo "  $(basename "$file" .yaml) — $titulo ($status)"
    done
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

CMD="${1:-help}"
shift || true

case "$CMD" in
    plan)
        cmd_plan "$@"
        ;;
    start)
        cmd_start "$@"
        ;;
    status)
        cmd_status "$@"
        ;;
    ack)
        cmd_ack "$@"
        ;;
    next)
        cmd_next "$@"
        ;;
    skip)
        cmd_skip "$@"
        ;;
    pause)
        cmd_pause "$@"
        ;;
    resume)
        cmd_resume "$@"
        ;;
    cancel)
        cmd_cancel "$@"
        ;;
    history)
        cmd_history "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Comando desconhecido: $CMD"
        show_help
        exit 1
        ;;
esac
