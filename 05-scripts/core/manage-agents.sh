#!/usr/bin/env bash
# =============================================================================
# manage-agents.sh — Gerir Agentes (add/remove/pause/activate/list/stop/sessions/attach/cleanup)
# Versão: 2.1 (+ sub-comandos sessão)
# =============================================================================
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"
TEMPLATES_DIR="$MAKAN72_HOME/01-config/templates"
CVS_DIR="$MAKAN72_HOME/00-global/cvs"
PROMPTS_DIR="$MAKAN72_HOME/01-config/prompts"
INBOX_DIR="$MAKAN72_HOME/03-inbox"
ARCHIVE_DIR="$MAKAN72_HOME/07-archive"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Função de erro
error() {
    echo -e "${RED}❌ $1${NC}" >&2
    exit 1
}

# Função de integridade
update_integrity() {
    local integrity_file="$MAKAN72_HOME/01-config/integrity.json"
    if command -v python3 &>/dev/null; then
        python3 -c "
import json, os, hashlib
from datetime import datetime
agents_file = '$AGENTS_FILE'
try:
    with open(agents_file) as f:
        data = json.load(f)
    h = hashlib.md5(json.dumps(data, sort_keys=True).encode()).hexdigest()
    integrity = {
        'last_update': datetime.now().isoformat(),
        'agents_count': len(data.get('agents', [])),
        'agents_hash': h
    }
    with open('$integrity_file', 'w') as f:
        json.dump(integrity, f, indent=2)
except Exception as e:
    pass
" 2>/dev/null || true
    fi
}

# =============================================================================
# PROMPT DO REGISTRADOR
# =============================================================================
REGISTRADOR_PROMPT='Responde APENAS com um JSON (sem texto antes ou depois) com estes campos exactos:
{
  "nome": "TEU_NOME_EM_MAIUSCULAS",
  "modelo": "nome completo do modelo",
  "empresa": "empresa que te criou",
  "contexto_tokens": numero_inteiro,
  "editor_nativo": true_ou_false,
  "multimodal": true_ou_false,
  "linguagens": ["Python", "Bash", ...],
  "forcas": ["ponto forte 1", "ponto forte 2"],
  "fraquezas": ["ponto fraco 1", "ponto fraco 2"],
  "ferramentas_nativas": ["read", "write", "bash", ...]
}
Responde APENAS o JSON, sem texto antes ou depois.'

# =============================================================================
# FUNÇÕES DO REGISTRADOR
# =============================================================================

# Detectar prompt_flag — testar -p (universal para claude/qwen/gemini)
detect_prompt_flag() {
    local cli="$1"

    # Verificar se o CLI suporta -p consultando --help (instantaneo, nao consome tokens)
    if "$cli" --help 2>&1 | grep -q '\-p'; then
        echo "-p"
        return 0
    fi

    echo ""
    return 1
}

# Enviar prompt do Registrador ao agente
send_registrador_prompt() {
    local cli="$1"
    local prompt_flag="$2"

    if [[ -z "$prompt_flag" ]]; then
        prompt_flag=$(detect_prompt_flag "$cli" || true)
    fi

    if [[ -n "$prompt_flag" ]]; then
        timeout 30 "$cli" $prompt_flag "$REGISTRADOR_PROMPT" 2>/dev/null || echo "FALHOU"
    else
        echo "FALHOU"
    fi
}

# Parsear resposta JSON do Registrador
parse_registrador_response() {
    local response="$1"

    # Limpar backticks markdown (```json ... ```)
    response=$(echo "$response" | sed '/^```/d')

    # Remover texto antes do primeiro { e depois do ultimo }
    local json
    json=$(echo "$response" | sed -n '/^{/,/^}/p')

    # Se nao encontrou com sed, tentar extrair com perl (texto misto)
    if [[ -z "$json" ]]; then
        json=$(echo "$response" | tr '\n' ' ' | sed 's/.*\({.*}\).*/\1/')
    fi

    if [[ -z "$json" ]]; then
        return 1
    fi

    # Validar e formatar com jq (jq lida com arrays, nested objects, tudo)
    local formatted
    formatted=$(echo "$json" | jq . 2>/dev/null)
    if [[ $? -ne 0 || -z "$formatted" ]]; then
        return 1
    fi

    echo "$formatted"
    return 0
}

# Gerar CV a partir de dados do Registrador
generate_cv_from_registrador() {
    local code="$1"
    local json="$2"
    local cv_file="$3"

    local nome modelo empresa contexto_tokens editor_nativo multimodal
    local linguagens forcas fraquezas ferramentas_nativas
    local data_criacao

    nome=$(echo "$json" | jq -r '.nome // "DESCONHECIDO"')
    modelo=$(echo "$json" | jq -r '.modelo // "Desconhecido"')
    empresa=$(echo "$json" | jq -r '.empresa // "Desconhecida"')
    contexto_tokens=$(echo "$json" | jq -r '.contexto_tokens // 0')
    editor_nativo=$(echo "$json" | jq -r '.editor_nativo // false')
    multimodal=$(echo "$json" | jq -r '.multimodal // false')

    linguagens=$(echo "$json" | jq -r '.linguagens // [] | join(", ")')
    forcas=$(echo "$json" | jq -r '.forcas // [] | join("\n- ")')
    fraquezas=$(echo "$json" | jq -r '.fraquezas // [] | join("\n- ")')
    ferramentas_nativas=$(echo "$json" | jq -r '.ferramentas_nativas // [] | join(", ")')

    data_criacao=$(date +%Y-%m-%d)

    cat > "$cv_file" << CVMD
# CV de $nome

**Modelo:** $modelo
**CLI:** $code
**Data de criacao:** $data_criacao
**Registado por:** Registrador Makan72 (automatico)

---

## Configuração (sistema le)

| Campo | Valor |
|-------|-------|
| Nome | $nome |
| Modelo | $modelo |
| Empresa | $empresa |
| CLI | $code |
| Contexto (tokens) | $contexto_tokens |
| Editor nativo | $editor_nativo |
| Multimodal | $multimodal |

## Capacidades

**Forcas:**
- ${forcas:-Nenhuma especificada}

**Fraquezas:**
- ${fraquezas:-Nenhuma especificada}

**Linguagens:** ${linguagens:-Nenhuma}

**Ferramentas nativas:** ${ferramentas_nativas:-Nenhuma}

---

## Papel no Makan72

**Funcao:** Agente de IA via CLI
**Responsabilidades:**
1. Executar tarefas atribuidas via inbox
2. Reportar progresso com SITREPs
3. Seguir regras do VERDADE.md e VACINAS.md
4. Verificar fisicamente antes de declarar completo

---

## Notas Operacionais

**Inbox:** 03-inbox/${code}/pending/
**Contexto:** 09-workspace/context/${code}_context.md
CVMD
}

# Gerar agents.json entry a partir de dados do Registrador
generate_agent_entry() {
    local code="$1"
    local json="$2"
    local cli="$3"
    local prompt_flag="$4"

    local nome modelo empresa contexto_tokens editor_nativo multimodal
    local data_criacao

    nome=$(echo "$json" | jq -r '.nome // "DESCONHECIDO"')
    modelo=$(echo "$json" | jq -r '.modelo // "Desconhecido"')
    empresa=$(echo "$json" | jq -r '.empresa // "Desconhecida"')
    contexto_tokens=$(echo "$json" | jq -r '.contexto_tokens // 0')
    editor_nativo=$(echo "$json" | jq -r '.editor_nativo // false')
    multimodal=$(echo "$json" | jq -r '.multimodal // false')

    data_criacao=$(date +%Y-%m-%d)

    # Determinar memory_file baseado no code
    local memory_file="${code}.md"

    # Determinar cli_flags e context_flag baseado no cli
    local cli_flags=""
    local context_flag="--prompt-interactive"
    case "$cli" in
        claude)
            cli_flags="--permission-mode acceptEdits"
            context_flag="--append-system-prompt"
            ;;
        qwen)
            cli_flags="--approval-mode auto-edit"
            context_flag="--prompt-interactive"
            ;;
        gemini)
            cli_flags="--approval-mode auto_edit --sandbox"
            context_flag="--prompt-interactive"
            ;;
        *)
            cli_flags=""
            context_flag="--prompt-interactive"
            ;;
    esac

    cat << ENTRY
{
    "code": "$code",
    "name": "$nome",
    "model": "$modelo",
    "empresa": "$empresa",
    "cli": "$cli",
    "memory_file": "$memory_file",
    "cli_flags": "$cli_flags",
    "context_flag": "$context_flag",
    "prompt_flag": "$prompt_flag",
    "contexto_tokens": $contexto_tokens,
    "editor_nativo": $editor_nativo,
    "multimodal": $multimodal,
    "tab": 0,
    "status": "active",
    "added_date": "$data_criacao",
    "registered_by": "registrador",
    "modos_possiveis": []
}
ENTRY
}

# =============================================================================
# COMPLETE INTROSPECT (V2 Híbrido — completar registo de agente pendente)
# =============================================================================
complete_introspect() {
    local code="${1:-}"
    if [[ -z "$code" ]]; then
        echo -e "${RED}❌ Uso: complete-introspect <CODE>${NC}"
        echo -e "${YELLOW}Ex: complete-introspect CLAUDE${NC}"
        exit 1
    fi
    code=$(echo "$code" | tr '[:lower:]' '[:upper:]')

    # Verificar se agente existe e tem pending_introspect
    local is_pending
    is_pending=$(jq -r ".agents[] | select(.code==\"$code\") | .pending_introspect // false" "$AGENTS_FILE" 2>/dev/null || echo "false")

    if [[ "$is_pending" != "true" ]]; then
        echo -e "${YELLOW}⚠ Agente $code não tem introspecção pendente${NC}"
        return 0
    fi

    local cli
    cli=$(jq -r ".agents[] | select(.code==\"$code\") | .cli" "$AGENTS_FILE")

    local prompt_flag
    prompt_flag=$(jq -r ".agents[] | select(.code==\"$code\") | .prompt_flag // \"-p\"" "$AGENTS_FILE")

    echo -e "${BLUE}📡 A completar introspecção de $code...${NC}"
    echo -e "${BLUE}⏳ A contactar $cli (timeout 30s)...${NC}"

    local response
    response=$(send_registrador_prompt "$cli" "$prompt_flag" || true)

    if [[ "$response" == "FALHOU" || -z "$response" ]]; then
        echo -e "${RED}❌ Introspecção falhou novamente.${NC}"
        echo -e "${YELLOW}Alternativa: regista manualmente com:${NC}"
        echo -e "  ${CYAN}manage-agents.sh add CODE \"Nome\" cli${NC}"
        return 1
    fi

    local json
    json=$(parse_registrador_response "$response" || true)
    if [[ -z "$json" ]]; then
        echo -e "${RED}❌ JSON inválido na resposta.${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Resposta JSON válida!${NC}"

    # Gerar nova entry completa
    local entry
    entry=$(generate_agent_entry "$code" "$json" "$cli" "$prompt_flag" || true)

    # Remover agente antigo e adicionar o novo completo
    local tmp_file
    tmp_file=$(mktemp)

    jq "del(.agents[] | select(.code==\"$code\"))" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

    tmp_file=$(mktemp)
    jq ".agents += [$entry]" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

    # Regenerar CV completo
    generate_cv_from_registrador "$code" "$json" "$CVS_DIR/CV_${code}.md"

    echo -e "${GREEN}✅ Introspecção de $code completa!${NC}"
    echo -e "  CV actualizado: $CVS_DIR/CV_${code}.md"
    echo -e "  agents.json actualizado"

    update_integrity
}

# =============================================================================
# ADD FROM REGISTRY — Consultar 01-config/registry/ antes do Registrador
# =============================================================================
add_from_registry() {
    local cli_name="$1"
    local registry_dir="$MAKAN72_HOME/01-config/registry"
    local index_file="$registry_dir/_REGISTRY_INDEX.json"

    # 1. Verificar se existe index
    if [[ ! -f "$index_file" ]]; then
        return 1
    fi

    # 2. Procurar CLI no index
    local registry_file
    registry_file=$(jq -r ".lookup_by_cli[\"$cli_name\"] // empty" "$index_file" 2>/dev/null)
    if [[ -z "$registry_file" ]]; then
        return 1
    fi

    local registry_path="$registry_dir/$registry_file"
    if [[ ! -f "$registry_path" ]]; then
        return 1
    fi

    # 3. Extrair dados do registry JSON
    echo -e "${GREEN}✓ Registry encontrado: $registry_file${NC}"

    local nome empresa modelo cli_cmd contexto
    local editor_nativo multimodal

    # Identidade — campos variam entre registries (cli vs cli_command, empresa vs criador)
    nome=$(jq -r '.identidade.nome // "DESCONHECIDO"' "$registry_path")
    empresa=$(jq -r '.identidade.empresa // .identidade.criador // "Desconhecida"' "$registry_path")
    cli_cmd=$(jq -r '.identidade.cli_command // .identidade.cli // "'"$cli_name"'"' "$registry_path")
    modelo=$(jq -r '.identidade.modelo_default // .identidade.versao // "unknown"' "$registry_path")

    # Se modelo é descrição e não nome real, marcar como configurável
    if echo "$modelo" | grep -qi "configurável\|configurable\|sem modelo"; then
        modelo="configurable"
    fi

    contexto=$(jq -r '.identidade.contexto_maximo // 0' "$registry_path")
    if ! [[ "$contexto" =~ ^[0-9]+$ ]]; then
        contexto=0
    fi

    # Capacidades — campos variam (edicao_ficheiros vs edita_ficheiros, leitura_imagens vs multimodal_imagens)
    editor_nativo=$(jq -r '.capacidades.edicao_ficheiros // .capacidades.edita_ficheiros // false' "$registry_path")
    multimodal=$(jq -r '.capacidades.leitura_imagens // .capacidades.multimodal_imagens // false' "$registry_path")

    # CODE = CLI em maiúsculas (opencode→OPENCODE, goose→GOOSE)
    local code
    code=$(echo "$cli_name" | tr '[:lower:]' '[:upper:]')

    # 4. Verificar duplicado
    if jq -e ".agents[] | select(.code==\"$code\")" "$AGENTS_FILE" &>/dev/null; then
        echo -e "${RED}❌ Agente $code já existe em agents.json${NC}"
        exit 1
    fi

    # 5. Determinar context_flag por CLI
    local context_flag=""
    local prompt_flag="-p"
    case "$cli_cmd" in
        claude)   context_flag="--append-system-prompt" ;;
        qwen)     context_flag="--prompt-interactive" ;;
        gemini)   context_flag="" ;;
        opencode) context_flag="--prompt" ;;
        goose)    context_flag="--system" ;;
        *)
            # Tentar inferir do registry
            local sys_flag
            sys_flag=$(jq -r '.flags_sistema.system_prompt_flag // empty' "$registry_path" 2>/dev/null)
            if [[ -n "$sys_flag" ]]; then
                context_flag=$(echo "$sys_flag" | awk '{print $1}')
            else
                context_flag="--prompt-interactive"
            fi
            ;;
    esac

    # 6. Mostrar dados ao CEO
    echo -e "${BLUE}📋 Dados do Registry:${NC}"
    echo -e "  Código:   ${GREEN}$code${NC}"
    echo -e "  Nome:     ${GREEN}$nome${NC}"
    echo -e "  Empresa:  ${GREEN}$empresa${NC}"
    echo -e "  CLI:      ${GREEN}$cli_cmd${NC}"
    echo -e "  Modelo:   ${GREEN}$modelo${NC}"
    echo ""

    # 7. Adicionar ao agents.json
    local today
    today=$(date +%Y-%m-%d)
    local tmp_file
    tmp_file=$(mktemp)

    jq ".agents += [{
        \"code\": \"$code\",
        \"name\": \"$nome\",
        \"model\": \"$modelo\",
        \"empresa\": \"$empresa\",
        \"cli\": \"$cli_cmd\",
        \"memory_file\": \"${code}.md\",
        \"cli_flags\": \"\",
        \"context_flag\": \"$context_flag\",
        \"prompt_flag\": \"$prompt_flag\",
        \"contexto_tokens\": $contexto,
        \"editor_nativo\": $editor_nativo,
        \"multimodal\": $multimodal,
        \"tab\": 0,
        \"status\": \"active\",
        \"added_date\": \"$today\",
        \"registered_by\": \"registry\",
        \"registry_file\": \"$registry_file\",
        \"modos_possiveis\": []
    }]" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

    # 8. Gerar CV do registry
    generate_cv_from_registry "$code" "$registry_path" "$CVS_DIR/CV_${code}.md"

    # 9. Criar inbox e prompt
    mkdir -p "$INBOX_DIR/$code/pending"
    mkdir -p "$INBOX_DIR/$code/in_progress"
    mkdir -p "$INBOX_DIR/$code/done"

    if [[ -f "$TEMPLATES_DIR/PROMPT_TEMPLATE.md" ]]; then
        cp "$TEMPLATES_DIR/PROMPT_TEMPLATE.md" "$PROMPTS_DIR/${code}.md"
    fi

    update_integrity

    echo -e "${GREEN}✅ Agente $code adicionado a partir do Registry!${NC}"
    echo ""
    echo -e "  CV:    $CVS_DIR/CV_${code}.md"
    echo -e "  Inbox: $INBOX_DIR/$code/"
    echo -e "  Fonte: $registry_file"
    echo ""
    echo -e "${CYAN}Pronto a usar: makan72 agent start $code${NC}"

    return 0
}

# Gerar CV a partir do ficheiro do Registry
generate_cv_from_registry() {
    local code="$1"
    local registry_path="$2"
    local cv_file="$3"

    local nome empresa modelo cli_cmd
    local editor_nativo multimodal

    nome=$(jq -r '.identidade.nome // "DESCONHECIDO"' "$registry_path")
    empresa=$(jq -r '.identidade.empresa // .identidade.criador // "Desconhecida"' "$registry_path")
    cli_cmd=$(jq -r '.identidade.cli_command // .identidade.cli // "unknown"' "$registry_path")
    modelo=$(jq -r '.identidade.modelo_default // .identidade.versao // "unknown"' "$registry_path")
    editor_nativo=$(jq -r '.capacidades.edicao_ficheiros // .capacidades.edita_ficheiros // false' "$registry_path")
    multimodal=$(jq -r '.capacidades.leitura_imagens // .capacidades.multimodal_imagens // false' "$registry_path")

    # Extrair tools builtin (campo pode não existir)
    local tools
    tools=$(jq -r '(.tools_builtin.tools // []) | if length > 0 then join(", ") else "N/A" end' "$registry_path" 2>/dev/null || echo "N/A")

    local data_criacao
    data_criacao=$(date +%Y-%m-%d)

    cat > "$cv_file" << CVMD
# CV de $nome

**Modelo:** $modelo
**Empresa:** $empresa
**CLI:** $cli_cmd
**Data de criacao:** $data_criacao
**Registado por:** Registry Makan72 (01-config/registry/)

---

## Configuração (sistema le)

| Campo | Valor |
|-------|-------|
| Nome | $nome |
| Modelo | $modelo |
| Empresa | $empresa |
| CLI | $cli_cmd |
| Editor nativo | $editor_nativo |
| Multimodal | $multimodal |

## Ferramentas Nativas

$tools

---

## Papel no Makan72

**Funcao:** Agente de IA via CLI
**Responsabilidades:**
1. Executar tarefas atribuidas via inbox
2. Reportar progresso com SITREPs
3. Seguir regras do VERDADE.md e VACINAS.md
4. Verificar fisicamente antes de declarar completo

---

## Notas Operacionais

**Inbox:** 03-inbox/${code}/pending/
**Contexto:** 09-workspace/context/${code}_context.md
**Registry:** 01-config/registry/ (ficha técnica detalhada)
CVMD
}


# =============================================================================
# ADD AGENT (com Registrador V2 Híbrido)
# =============================================================================
add_agent() {
    local code="${1:-}"
    local name="${2:-}"
    local cli="${3:-}"
    local use_registrador=0
    local registrador_cli=""
    local registrador_json=""

    # Verificar flag --cli
    if [[ "$code" == "--cli" ]]; then
        use_registrador=1
        registrador_cli="$name"
        # LIMPAR variaveis — serao preenchidas pelo Registrador ou fallback
        code=""
        name=""
        cli=""
        if [[ -z "$registrador_cli" ]]; then
            echo -e "${RED}❌ Uso: add --cli <comando>${NC}"
            echo -e "${YELLOW}Ex: add --cli claude${NC}"
            exit 1
        fi
        # Verificar se CLI existe
        if ! command -v "$registrador_cli" &>/dev/null; then
            echo -e "${RED}❌ CLI '$registrador_cli' não encontrado. Instale primeiro.${NC}"
            exit 1
        fi
        echo -e "${BLUE}🔍 Registrador: CLI '$registrador_cli' detectado${NC}"
    fi

    # MODO INTERACTIVO: Se nao ha argumentos, perguntar
    if [[ -z "$code" && $use_registrador -eq 0 ]]; then
        echo ""
        echo -e "${BLUE}🤖 Adicionar novo agente${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        read -t 60 -p "Código (ex: DEEPSEEK): " code
        [[ -z "$code" ]] && error "Código não pode ser vazio"
        code=$(echo "$code" | tr '[:lower:]' '[:upper:]')

        read -t 60 -p "Nome completo (ex: DeepSeek R1): " name
        [[ -z "$name" ]] && error "Nome não pode ser vazio"

        read -t 60 -p "Comando CLI (ex: deepseek): " cli
        [[ -z "$cli" ]] && error "CLI não pode ser vazio"

        echo ""
        echo -e "Código: ${GREEN}$code${NC}"
        echo -e "Nome:   ${GREEN}$name${NC}"
        echo -e "CLI:    ${GREEN}$cli${NC}"
        echo ""
        read -t 30 -p "Confirmar? (s/N): " confirm
        [[ "$confirm" != "s" && "$confirm" != "S" ]] && { echo "Cancelado."; exit 0; }
        echo ""
    fi

    # MODO REGISTRADOR: Falar com o agente
    if [[ $use_registrador -eq 1 ]]; then
        # === Registry: verificar 01-config/registry/ primeiro ===
        if add_from_registry "$registrador_cli"; then
            return 0  # Sucesso via Registry — sair
        fi
        echo -e "${YELLOW}⚠ Registry nao encontrado para '$registrador_cli' — a usar Registrador...${NC}"
        # === Fim Registry ===

        echo -e "${BLUE}📡 A contactar agente via Registrador...${NC}"

        # Detectar prompt_flag
        local prompt_flag
        prompt_flag=$(detect_prompt_flag "$registrador_cli" || true)
        if [[ -n "$prompt_flag" ]]; then
            echo -e "${GREEN}✓ prompt_flag detectado: $prompt_flag${NC}"
        else
            echo -e "${YELLOW}⚠ prompt_flag não detectado, a tentar mesmo assim...${NC}"
            prompt_flag="-p"
        fi

        # Enviar prompt do Registrador
        local response
        echo -e "${BLUE}⏳ A aguardar resposta do agente (timeout 30s)...${NC}"
        response=$(send_registrador_prompt "$registrador_cli" "$prompt_flag" || true)

        if [[ "$response" == "FALHOU" || -z "$response" ]]; then
            # ============================================================
            # DEFERRED PATH (V2): Criar registo mínimo + pending_introspect
            # ============================================================
            echo -e "${YELLOW}⚠ Registrador timeout — a criar registo mínimo...${NC}"
            code=$(echo "$registrador_cli" | tr '[:lower:]' '[:upper:]')
            name="$registrador_cli"
            cli="$registrador_cli"

            # Verificar duplicado
            if jq -e ".agents[] | select(.code==\"$code\")" "$AGENTS_FILE" &>/dev/null; then
                echo -e "${RED}❌ Agente $code já existe${NC}"
                exit 1
            fi

            local today
            today=$(date +%Y-%m-%d)
            local tmp_file
            local _ctx_flag="--prompt-interactive"
            [[ "$cli" == "claude" ]] && _ctx_flag="--system-prompt"
            tmp_file=$(mktemp)

            jq ".agents += [{
                \"code\": \"$code\",
                \"name\": \"$name\",
                \"model\": \"unknown\",
                \"cli\": \"$cli\",
                \"memory_file\": \"${code}.md\",
                \"cli_flags\": \"\",
                \"prompt_flag\": \"$prompt_flag\",
                \"context_flag\": \"$_ctx_flag\",
                \"tab\": 0,
                \"status\": \"active\",
                \"added_date\": \"$today\",
                \"registered_by\": \"registrador-deferred\",
                \"pending_introspect\": true,
                \"modos_possiveis\": []
            }]" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

            # Criar CV mínimo
            cat > "$CVS_DIR/CV_${code}.md" << CVMIN
# CV de $code

**Modelo:** (pendente — introspecção no primeiro start)
**CLI:** $cli
**Data de criacao:** $today
**Registado por:** Registrador Makan72 (deferred)

---

## Estado: PENDENTE INTROSPECÇÃO

Este agente foi registado mas ainda não completou a introspecção.
Ao executar \`makan72 agent start $code\`, o sistema pedirá ao agente
para se identificar automaticamente.

Depois: \`makan72 agent complete-introspect $code\`
CVMIN

            # Criar inbox
            mkdir -p "$INBOX_DIR/$code/pending"
            mkdir -p "$INBOX_DIR/$code/in_progress"
            mkdir -p "$INBOX_DIR/$code/done"

            # Criar prompt a partir de template
            if [[ -f "$TEMPLATES_DIR/PROMPT_TEMPLATE.md" ]]; then
                cp "$TEMPLATES_DIR/PROMPT_TEMPLATE.md" "$PROMPTS_DIR/${code}.md"
            fi

            update_integrity

            echo -e "${GREEN}✅ Agente $code adicionado (registo mínimo)${NC}"
            echo ""
            echo -e "${YELLOW}⚠ Introspecção pendente!${NC}"
            echo -e "  Quando iniciar: ${CYAN}makan72 agent start $code${NC}"
            echo -e "  O agente vai identificar-se automaticamente no primeiro chat."
            echo -e "  Depois: ${CYAN}makan72 agent complete-introspect $code${NC}"
            return 0
        else
            # FAST PATH: Resposta recebida — parsear JSON
            local json
            json=$(parse_registrador_response "$response" || true)
            if [[ -z "$json" ]]; then
                echo -e "${RED}❌ Resposta JSON inválida. A mudar para modo interactivo...${NC}"
                echo -e "${YELLOW}Resposta recebida: $response${NC}"
                use_registrador=0
            else
                # Sucesso! Extrair dados
                echo -e "${GREEN}✓ Resposta JSON válida recebida${NC}"
                registrador_json="$json"
                local nome modelo empresa
                nome=$(echo "$json" | jq -r '.nome')
                modelo=$(echo "$json" | jq -r '.modelo')
                empresa=$(echo "$json" | jq -r '.empresa')

                code="$nome"
                name="$modelo"
                cli="$registrador_cli"

                echo -e "${GREEN}✓ Agente identificado: $nome ($modelo) da $empresa${NC}"
            fi
        fi
    fi

    # Se saiu do modo Registrador, cair no modo interactivo
    if [[ $use_registrador -eq 0 && -z "$code" ]]; then
        echo ""
        echo -e "${YELLOW}Modo interactivo (fallback):${NC}"
        read -t 60 -p "Código (ex: DEEPSEEK): " code
        [[ -z "$code" ]] && error "Código não pode ser vazio"
        code=$(echo "$code" | tr '[:lower:]' '[:upper:]')

        read -t 60 -p "Nome completo (ex: DeepSeek R1): " name
        [[ -z "$name" ]] && error "Nome não pode ser vazio"

        read -t 60 -p "Comando CLI (ex: deepseek): " cli
        [[ -z "$cli" ]] && error "CLI não pode ser vazio"
    fi

    # Validar código (apenas A-Z, 0-9, _)
    if [[ -n "$code" && ! "$code" =~ ^[A-Z0-9_]+$ ]]; then
        echo -e "${RED}❌ Código inválido: use apenas A-Z, 0-9, _${NC}"
        exit 1
    fi

    # Verificar duplicado
    if [[ -n "$code" ]] && jq -e ".agents[] | select(.code==\"$code\")" "$AGENTS_FILE" &>/dev/null; then
        echo -e "${RED}❌ Agente $code já existe${NC}"
        exit 1
    fi

    # Se ainda nao temos dados suficientes, fallback interactivo
    if [[ -z "$name" || -z "$cli" ]]; then
        echo -e "${YELLOW}⚠ Dados insuficientes. Modo interactivo...${NC}"
        [[ -z "$code" ]] && {
            read -t 60 -p "Código (ex: DEEPSEEK): " code
            code=$(echo "$code" | tr '[:lower:]' '[:upper:]')
        }
        [[ -z "$name" ]] && {
            read -t 60 -p "Nome completo (ex: DeepSeek R1): " name
        }
        [[ -z "$cli" ]] && {
            read -t 60 -p "Comando CLI (ex: deepseek): " cli
        }
    fi

    local today
    today=$(date +%Y-%m-%d)
    local tmp_file
    tmp_file=$(mktemp)

    # Se veio do Registrador, gerar entry completa
    if [[ $use_registrador -eq 1 && -n "$registrador_json" ]]; then
        local entry
        entry=$(generate_agent_entry "$code" "$registrador_json" "$cli" "$prompt_flag" || true)

        # Adicionar a agents.json
        jq ".agents += [$entry]" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

        # Gerar CV
        generate_cv_from_registrador "$code" "$registrador_json" "$CVS_DIR/CV_${code}.md"

        echo -e "${GREEN}✓ CV gerado automaticamente${NC}"
    else
        # Modo tradicional (interactivo)
        local _ctx_flag="--prompt-interactive"
        [[ "$cli" == "claude" ]] && _ctx_flag="--system-prompt"
        jq ".agents += [{
            \"code\": \"$code\",
            \"name\": \"$name\",
            \"model\": \"unknown\",
            \"cli\": \"$cli\",
            \"memory_file\": \"${code}.md\",
            \"cli_flags\": \"\",
            \"context_flag\": \"$_ctx_flag\",
            \"prompt_flag\": \"-p\",
            \"tab\": 0,
            \"status\": \"active\",
            \"added_date\": \"$today\",
            \"registered_by\": \"manual\",
            \"modos_possiveis\": []
        }]" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

        # Criar CV a partir de template
        if [[ -f "$TEMPLATES_DIR/CV_TEMPLATE.md" ]]; then
            cp "$TEMPLATES_DIR/CV_TEMPLATE.md" "$CVS_DIR/CV_${code}.md"
        fi
    fi

    # Criar prompt a partir de template
    if [[ -f "$TEMPLATES_DIR/PROMPT_TEMPLATE.md" ]]; then
        cp "$TEMPLATES_DIR/PROMPT_TEMPLATE.md" "$PROMPTS_DIR/${code}.md"
    fi

    # Criar inbox
    mkdir -p "$INBOX_DIR/$code/pending"
    mkdir -p "$INBOX_DIR/$code/in_progress"
    mkdir -p "$INBOX_DIR/$code/done"

    echo -e "${GREEN}✅ Agente $code adicionado!${NC}"
    echo ""
    echo -e "${BLUE}Resumo:${NC}"
    echo "  Código: $code"
    echo "  Nome: $name"
    echo "  CLI: $cli"
    echo "  CV: $CVS_DIR/CV_${code}.md"
    echo "  Inbox: $INBOX_DIR/$code/"
    echo ""
    echo -e "${CYAN}Pronto a usar: makan72 agent start $code${NC}"

    # Actualizar integridade
    update_integrity
}

# =============================================================================
# FUNÇÕES DE GESTÃO (remove, pause, activate, list, info)
# =============================================================================

# Remover agente
remove_agent() {
    local code="$1"

    # Verificar se existe
    if ! jq -e ".agents[] | select(.code==\"$code\")" "$AGENTS_FILE" &>/dev/null; then
        echo -e "${RED}❌ Agente $code não existe${NC}"
        exit 1
    fi

    # Mudar status para removed
    local tmp_file
    tmp_file=$(mktemp)
    jq "(.agents[] | select(.code==\"$code\") | .status) = \"removed\"" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

    # Mover inbox, CV e prompt para arquivo (limpa destino se já existir)
    mkdir -p "$ARCHIVE_DIR/agents/$code"

    if [[ -d "$INBOX_DIR/$code" ]]; then
        cp -r "$INBOX_DIR/$code/"* "$ARCHIVE_DIR/agents/$code/" 2>/dev/null || true
        rm -rf "$INBOX_DIR/$code"
    fi

    [[ -f "$CVS_DIR/CV_${code}.md" ]] && mv -f "$CVS_DIR/CV_${code}.md" "$ARCHIVE_DIR/agents/$code/"
    [[ -f "$PROMPTS_DIR/${code}.md" ]] && mv -f "$PROMPTS_DIR/${code}.md" "$ARCHIVE_DIR/agents/$code/"

    # Apagar heartbeat e status
    rm -f "$MAKAN72_HOME/04-bus/heartbeat/${code}_heartbeat.json"
    rm -f "$MAKAN72_HOME/04-bus/status/${code}_status.json"

    echo -e "${GREEN}✅ Agente $code removido e arquivado!${NC}"
}

# Pausar agente
pause_agent() {
    local code="$1"

    local tmp_file
    tmp_file=$(mktemp)
    jq "(.agents[] | select(.code==\"$code\") | .status) = \"paused\"" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

    echo -e "${YELLOW}⏸️  Agente $code pausado${NC}"
}

# Activar agente
activate_agent() {
    local code="$1"

    local tmp_file
    tmp_file=$(mktemp)
    jq "(.agents[] | select(.code==\"$code\") | .status) = \"active\"" "$AGENTS_FILE" > "$tmp_file" && mv "$tmp_file" "$AGENTS_FILE"

    echo -e "${GREEN}▶️  Agente $code activado${NC}"
}

# Listar agentes
list_agents() {
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     AGENTES MAKAN72                                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Activos
    echo -e "${GREEN}AGENTES ACTIVOS:${NC}"
    jq -r '.agents[] | select(.status=="active") | "  \(.code) | \(.name) | \(.cli) | Tab \(.tab)"' "$AGENTS_FILE" 2>/dev/null || echo "  (nenhum)"
    echo ""

    # Pendentes de introspecção
    local pending_count
    pending_count=$(jq '[.agents[] | select(.pending_introspect==true)] | length' "$AGENTS_FILE" 2>/dev/null || echo "0")
    if [[ "$pending_count" -gt 0 ]]; then
        echo -e "${YELLOW}INTROSPECÇÃO PENDENTE:${NC}"
        jq -r '.agents[] | select(.pending_introspect==true) | "  ⚠ \(.code) | \(.cli) | makan72 agent complete-introspect \(.code)"' "$AGENTS_FILE" 2>/dev/null
        echo ""
    fi

    # Pausados
    echo -e "${YELLOW}AGENTES PAUSADOS:${NC}"
    jq -r '.agents[] | select(.status=="paused") | "  \(.code) | \(.name) | \(.cli)"' "$AGENTS_FILE" 2>/dev/null || echo "  (nenhum)"
    echo ""

    # Removidos
    echo -e "${RED}AGENTES REMOVIDOS:${NC}"
    jq -r '.agents[] | select(.status=="removed") | "  \(.code) | \(.name)"' "$AGENTS_FILE" 2>/dev/null || echo "  (nenhum)"
}

# Info de agente
info_agent() {
    local code="$1"

    echo "Informações do agente $code:"
    jq ".agents[] | select(.code==\"$code\")" "$AGENTS_FILE" 2>/dev/null || echo "Agente não encontrado"
}

# =============================================================================
# HELP E MAIN
# =============================================================================

show_help() {
    cat << 'HELP'
manage-agents.sh — Gerir Agentes (v2.0 — Registrador Híbrido)

USO:
  manage-agents.sh <comando> [opções]

COMANDOS:
  add CODE "Nome" cli        Adicionar agente (manual)
  add --cli <comando>        Adicionar via Registrador automático
  remove CODE                Remover agente
  pause CODE                 Pausar agente
  activate CODE              Activar agente
  list                       Listar agentes
  info CODE                  Info de um agente
  complete-introspect CODE   Completar registo pendente
  help                       Mostrar ajuda

EXEMPLOS:
  manage-agents.sh add --cli qwen          # Auto-registo via Registrador
  manage-agents.sh add --cli claude        # Se timeout → registo mínimo
  manage-agents.sh complete-introspect CLAUDE  # Completar registo pendente
  manage-agents.sh add CLAUDE "Claude Opus 4.6" claude  # Manual
  manage-agents.sh list
  manage-agents.sh remove INSPETOR
HELP
}

# =============================================================================
# SUB-COMANDOS DE SESSÃO (stop/sessions/attach/cleanup)
# Reutilizam funções de makan72-functions.sh
# =============================================================================

# Source funções base (para m72_kill_agent, m72_list_sessions, etc.)
source "$MAKAN72_HOME/05-scripts/core/makan72-functions.sh" 2>/dev/null || true

# --- sessions: Listar sessões activas ---
cmd_sessions() {
    local SLOTS_FILE="$MAKAN72_HOME/04-bus/active_slots.json"
    if [[ ! -f "$SLOTS_FILE" ]]; then
        echo "Nenhuma sessão activa."
        return 0
    fi

    local COUNT=$(jq '.slots | length' "$SLOTS_FILE" 2>/dev/null || echo "0")
    if [[ "$COUNT" -eq 0 ]]; then
        echo "Nenhuma sessão activa."
        return 0
    fi

    echo ""
    echo "═══ Sessões Activas ($COUNT) ═══"
    echo ""
    printf "%-6s %-10s %-10s %-30s %s\n" "SLOT" "AGENTE" "CLI" "PROJECTO" "INICIO"
    printf "%-6s %-10s %-10s %-30s %s\n" "----" "------" "---" "--------" "------"

    jq -r '.slots[] | "\(.slot)|\(.name)|\(.cli)|\(.project)|\(.started)"' "$SLOTS_FILE" 2>/dev/null | while IFS='|' read -r slot name cli project started; do
        # Verificar se PID ainda está vivo
        local pid=$(jq -r --argjson s "$slot" '.slots[] | select(.slot==$s) | .pid' "$SLOTS_FILE" 2>/dev/null)
        local status="🟢"
        if [[ -n "$pid" && "$pid" != "null" ]] && ! kill -0 "$pid" 2>/dev/null; then
            status="💀"
        fi
        printf "%-6s %-10s %-10s %-30s %s %s\n" "$slot" "$name" "$cli" "$project" "$started" "$status"
    done
    echo ""
}

# --- stop: Parar agente ---
cmd_stop() {
    local CODE="${1:-}"
    if [[ -z "$CODE" ]]; then
        echo -e "${RED}❌ Uso: manage-agents.sh stop <CODE>${NC}"
        exit 1
    fi
    CODE="${CODE^^}"

    # Obter CLI do agente
    local CLI=$(jq -r --arg code "$CODE" '.agents[] | select(.code==$code) | .cli // empty' "$AGENTS_FILE" 2>/dev/null)
    if [[ -z "$CLI" ]]; then
        echo -e "${RED}❌ Agente '$CODE' não encontrado em agents.json${NC}"
        exit 1
    fi

    if type -t m72_kill_agent &>/dev/null; then
        m72_kill_agent "$CLI"
    else
        echo -e "${RED}❌ Função m72_kill_agent não disponível${NC}"
        exit 1
    fi
}

# --- attach: Anexar a sessão existente ---
cmd_attach() {
    local CODE="${1:-}"
    if [[ -z "$CODE" ]]; then
        echo -e "${RED}❌ Uso: manage-agents.sh attach <CODE>${NC}"
        exit 1
    fi
    CODE="${CODE^^}"

    if type -t m72_attach_agent &>/dev/null; then
        m72_attach_agent "$CODE"
    else
        echo -e "${RED}❌ Função m72_attach_agent não disponível${NC}"
        exit 1
    fi
}

# --- cleanup: Limpar sessões órfãs ---
cmd_cleanup() {
    echo "🧹 A limpar sessões órfãs..."
    if type -t m72_clean_orphan_slots &>/dev/null; then
        m72_clean_orphan_slots
    else
        echo -e "${RED}❌ Função m72_clean_orphan_slots não disponível${NC}"
        exit 1
    fi
    echo "✓ Cleanup completo."
}

# Main
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        add)
            add_agent "$@"
            ;;
        remove)
            [[ $# -lt 1 ]] && { echo -e "${RED}❌ Uso: remove CODE${NC}"; exit 1; }
            remove_agent "$1"
            ;;
        pause)
            [[ $# -lt 1 ]] && { echo -e "${RED}❌ Uso: pause CODE${NC}"; exit 1; }
            pause_agent "$1"
            ;;
        activate)
            [[ $# -lt 1 ]] && { echo -e "${RED}❌ Uso: activate CODE${NC}"; exit 1; }
            activate_agent "$1"
            ;;
        list)
            list_agents
            ;;
        info)
            [[ $# -lt 1 ]] && { echo -e "${RED}❌ Uso: info CODE${NC}"; exit 1; }
            info_agent "$1"
            ;;
        complete-introspect)
            [[ $# -lt 1 ]] && { echo -e "${RED}❌ Uso: complete-introspect CODE${NC}"; exit 1; }
            complete_introspect "$1"
            ;;
        sessions)
            cmd_sessions
            ;;
        stop)
            cmd_stop "$@"
            ;;
        attach)
            cmd_attach "$@"
            ;;
        cleanup)
            cmd_cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconhecido: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
