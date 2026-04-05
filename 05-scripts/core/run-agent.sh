#!/usr/bin/env bash
# run-agent.sh — Gerar contexto de memória para agente
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
source "$MAKAN72_HOME/05-scripts/utils/portable.sh"
AGENT_CODE="${1:-}"

if [[ -z "$AGENT_CODE" ]]; then
    echo "Uso: run-agent.sh <AGENT_CODE>"
    echo "Gera ficheiro de contexto com memória do sistema para o agente."
    exit 1
fi

echo "Preparando contexto para $AGENT_CODE..."

# Validar agente existe e status
AGENTS_FILE="$MAKAN72_HOME/01-config/agents.json"
AGENT_STATUS=$(jq -r --arg code "$AGENT_CODE" '.agents[] | select(.code==$code) | .status' "$AGENTS_FILE" 2>/dev/null || echo "")
if [[ -z "$AGENT_STATUS" ]]; then
    echo "Agente $AGENT_CODE nao encontrado em agents.json"
    exit 1
fi
if [[ "$AGENT_STATUS" == "removed" ]]; then
    echo "Agente $AGENT_CODE foi removido (status=removed)"
    exit 1
fi

# Ler verbosidade da sessao
VERBOSITY="COMPACTO"
if [[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]]; then
    VERBOSITY=$(grep "verbosidade:" "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" 2>/dev/null | awk '{print $2}' || echo "COMPACTO")
fi

# Preparar directorio de contexto
CONTEXT_DIR="$MAKAN72_HOME/09-workspace/context"
mkdir -p "$CONTEXT_DIR"
CONTEXT_FILE="$CONTEXT_DIR/${AGENT_CODE}_context.md"

# Limpar contexto anterior
> "$CONTEXT_FILE"

echo "  Verbosidade: $VERBOSITY"
echo "  Gerando contexto..."

# === CAMADA 1: SESSAO (sempre) ===
{
    echo "# CONTEXTO GERADO PARA $AGENT_CODE"
    echo "# Data: $(portable_date_iso)"
    echo "# Verbosidade: $VERBOSITY"
    echo ""
} >> "$CONTEXT_FILE"

if [[ -f "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" ]]; then
    echo "## SESSAO ACTUAL" >> "$CONTEXT_FILE"
    cat "$MAKAN72_HOME/00-global/SESSAO_HOJE.yaml" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
fi

# === CAMADA 0: ÚLTIMA SESSÃO DO PROJETO ===
PROJECTS_FILE="$MAKAN72_HOME/01-config/projects.json"
ACTIVE_PROJECT=""
if [[ -f "$PROJECTS_FILE" ]]; then
    ACTIVE_PROJECT=$(jq -r '.active_project // empty' "$PROJECTS_FILE" 2>/dev/null)
fi

if [[ -n "$ACTIVE_PROJECT" ]]; then
    PROJ_NAME=$(jq -r --arg id "$ACTIVE_PROJECT" '.projects[] | select(.id==$id) | .name // "N/A"' "$PROJECTS_FILE" 2>/dev/null)
    RELATORIOS_DIR="$MAKAN72_HOME/09-workspace/relatorios/$PROJ_NAME"
    ULTIMO_RELATORIO=""
    if [[ -d "$RELATORIOS_DIR" ]]; then
        ULTIMO_RELATORIO=$(ls -t "$RELATORIOS_DIR"/*.md 2>/dev/null | head -1)
    fi

    {
        echo "## ÚLTIMA SESSÃO DO PROJETO"
        echo "**Projeto:** $PROJ_NAME"
        if [[ -n "$ULTIMO_RELATORIO" && -f "$ULTIMO_RELATORIO" ]]; then
            echo "**Último relatório:** $(basename "$ULTIMO_RELATORIO")"
            echo ""
            head -50 "$ULTIMO_RELATORIO"
        else
            echo "**Status:** Primeira sessão neste projecto — sem histórico anterior"
        fi
        echo ""
    } >> "$CONTEXT_FILE"
fi

# === CAMADA 2: CV DO AGENTE (sempre) ===
if [[ -f "$MAKAN72_HOME/00-global/cvs/CV_${AGENT_CODE}.md" ]]; then
    echo "## CV DO AGENTE" >> "$CONTEXT_FILE"
    cat "$MAKAN72_HOME/00-global/cvs/CV_${AGENT_CODE}.md" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
else
    echo "## CV DO AGENTE" >> "$CONTEXT_FILE"
    echo "_(CV nao encontrado para $AGENT_CODE)_" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
fi

# === CAMADA 3: VERDADE + VACINAS (COMPACTO e COMPLETO) ===
if [[ "$VERBOSITY" != "MINIMO" ]]; then
    if [[ -f "$MAKAN72_HOME/00-global/VERDADE.md" ]]; then
        echo "## VERDADE (Resumo)" >> "$CONTEXT_FILE"
        if [[ "$VERBOSITY" == "COMPACTO" ]]; then
            # Secções 1-8 (core) + Secção 12 (Sistema de Correios — ferramentas)
            sed -n '1,200p' "$MAKAN72_HOME/00-global/VERDADE.md" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            # Injectar secção 12 (Sistema de Correios) — essencial para comunicação
            sed -n '/^## 12\. Sistema de Correios/,$ p' "$MAKAN72_HOME/00-global/VERDADE.md" >> "$CONTEXT_FILE"
        else
            cat "$MAKAN72_HOME/00-global/VERDADE.md" >> "$CONTEXT_FILE"
        fi
        echo "" >> "$CONTEXT_FILE"
    fi
    if [[ -f "$MAKAN72_HOME/00-global/VACINAS.md" ]]; then
        echo "## VACINAS (Erros a Evitar)" >> "$CONTEXT_FILE"
        if [[ "$VERBOSITY" == "COMPACTO" ]]; then
            tail -50 "$MAKAN72_HOME/00-global/VACINAS.md" >> "$CONTEXT_FILE"
        else
            cat "$MAKAN72_HOME/00-global/VACINAS.md" >> "$CONTEXT_FILE"
        fi
        echo "" >> "$CONTEXT_FILE"
    fi
fi

# === MCP CONFIG (se existir) ===
MCP_FILE="$MAKAN72_HOME/01-config/mcp/${AGENT_CODE}.md"
if [[ -f "$MCP_FILE" ]]; then
    echo "## MCP CONFIG" >> "$CONTEXT_FILE"
    cat "$MCP_FILE" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
fi

# === CAMADA 4: COMPLETO extras ===
if [[ "$VERBOSITY" == "COMPLETO" ]]; then
    # VISAO_MAKAN72.md (sempre)
    if [[ -f "$MAKAN72_HOME/00-global/VISAO_MAKAN72.md" ]]; then
        echo "## VISAO MAKAN72" >> "$CONTEXT_FILE"
        cat "$MAKAN72_HOME/00-global/VISAO_MAKAN72.md" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
    fi
    
    # Banks (se tiverem conteúdo)
    bancos_dir="$MAKAN72_HOME/00-global/bancos"
    if [[ -d "$bancos_dir" ]]; then
        for bank in "$bancos_dir"/*.md; do
            [[ -f "$bank" ]] || continue
            # Skip se ficheiro vazio ou < 50 bytes
            size=$(wc -c < "$bank")
            [[ "$size" -lt 50 ]] && continue
            
            name=$(basename "$bank" .md)
            echo "## $name" >> "$CONTEXT_FILE"
            cat "$bank" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
        done
    fi
fi

# === INBOX GUARD — Scan de segurança antes de ler tarefas ===
INBOX_GUARD="$MAKAN72_HOME/05-scripts/core/inbox-guard.sh"
if [[ -f "$INBOX_GUARD" ]]; then
    if ! bash "$INBOX_GUARD" scan-inbox "$AGENT_CODE" 2>/dev/null; then
        echo "⚠️  [INBOX GUARD] Ficheiros suspeitos bloqueados no inbox de $AGENT_CODE."
        echo "   O CEO foi alertado. Verifica 03-inbox/CEO/pending/ para detalhes."
    fi
fi

# === TAREFAS PENDENTES (com conteúdo) ===
PENDING_DIR="$MAKAN72_HOME/03-inbox/${AGENT_CODE}/pending"
if [[ -d "$PENDING_DIR" ]]; then
    PENDING_COUNT=$(find "$PENDING_DIR" -name "*.md" 2>/dev/null | wc -l)
    if [[ "$PENDING_COUNT" -gt 0 ]]; then
        echo "## TAREFAS PENDENTES ($PENDING_COUNT)" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        echo "**ATENÇÃO:** Tens $PENDING_COUNT tarefa(s) pendente(s). Lê e executa quando o CEO autorizar ou quando receberes alerta do dispatch." >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        task_num=0
        for f in "$PENDING_DIR"/*.md; do
            [[ -f "$f" ]] || continue
            task_num=$((task_num + 1))
            echo "### Tarefa $task_num: $(basename "$f")" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            # Incluir conteúdo (max 150 linhas por tarefa para não explodir contexto)
            head -150 "$f" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            echo "---" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
        done
    fi
fi

# === REGRAS DE OBEDIÊNCIA (injectadas em TODOS os agentes) ===
# Esta secção é o "contrato de obediência" do Makan72 como orquestrador.
# Aplica-se a TODOS os agentes, independentemente do CLI.

cat >> "$CONTEXT_FILE" << OBEDIENCIA_EOF

---

# ⚠️ REGRAS OBRIGATÓRIAS — LÊ TUDO ANTES DE AGIR

## A TUA IDENTIDADE

Tu és **${AGENT_CODE}**, agente de IA do sistema **Makan72**.
- Tu NÃO és um assistente genérico.
- Tu NÃO escolhes o teu nome — o teu nome é ${AGENT_CODE}.
- Quando perguntarem "quem és?", responde SEMPRE: "Sou ${AGENT_CODE}, agente do Makan72."
- O teu CV e capacidades estão descritos acima na secção "CV DO AGENTE".

## CADEIA DE COMANDO (INVIOLÁVEL)

\`\`\`
CEO (humano) → Líder da sessão → Tu (${AGENT_CODE})
\`\`\`

- O **CEO** tem autoridade máxima e final. NUNCA desobedecer ao CEO.
- O **Líder da sessão** coordena a missão (definido em SESSAO_HOJE).
- Tu **EXECUTAS** o que te pedem. Não decides sozinho.

## REGRAS OPERACIONAIS (TODAS OBRIGATÓRIAS)

**R1 — NUNCA improvisar fora do scope**
Se te pedem X, faz X. Não faças Y "porque achas melhor".
Se tiveres dúvidas → PÁRA → cria ficheiro DOUBT em 03-inbox/CEO/pending/ → aguarda.

**R2 — Verificação física obrigatória**
Antes de declarar que algo existe ou funciona: verifica com \`ls\`, \`cat\`, ou executa.
NUNCA dizer "feito" sem ter verificado que realmente está feito.

**R3 — Honestidade absoluta**
Se não sabes → diz "não sei".
Se não testaste → diz "não testei".
NUNCA inventar, alucinar, ou declarar "100% funcional" sem evidência.

**R4 — Perguntar antes de executar acções destrutivas**
Antes de apagar ficheiros, reescrever código, ou mudar arquitectura → confirma com o CEO.

**R5 — SITREP obrigatório**
Após CADA tarefa, reporta com formato:
\`\`\`
SITREP:
STATUS: VERDE/AMARELO/VERMELHO
MISSAO: [o que fizeste]
RESULTADO: [o que aconteceu]
FICHEIROS: [lista de ficheiros tocados]
PROBLEMAS: [se houver]
PROXIMO: [próximo passo sugerido]
\`\`\`

**R6 — Respeitar os outros agentes**
Outros agentes (CLAUDE, QWEN, GEMINI, GOOSE, OPENCODE) são teus colegas.
Não sobrescrever o trabalho deles sem autorização do CEO.

**R7 — Disclaimer obrigatório**
Se não tens certeza de algo, adiciona:
"EU POSSO NÃO ESTAR 100% CERTO. ANALISAR BEM E SE ENCONTRAR PROBLEMA, REPORTAR A MIM OU AO CEO."

## PRIMEIRA RESPOSTA OBRIGATÓRIA

Quando o CEO abrir esta sessão, a tua PRIMEIRA resposta deve ser:
**"PRONTO — regras lidas. Sou ${AGENT_CODE}. Aguardo ordens do CEO."**

NÃO começar a executar nada. NÃO fazer sugestões. NÃO listar capacidades.
Apenas confirmar que leste as regras e aguardar instrução.

---
OBEDIENCIA_EOF

# === FERRAMENTAS DISPONÍVEIS (injectadas em TODOS os agentes) ===
TOOLS_FILE="$MAKAN72_HOME/10-tools/tools.json"
if [[ -f "$TOOLS_FILE" ]]; then
    {
        echo ""
        echo "## FERRAMENTAS DISPONIVEIS"
        echo ""
        echo "O Makan72 tem ferramentas instaladas que podes usar via wrapper scripts."
        echo "Todas estao em \`~/.Makan72/10-tools/wrappers/\`."
        echo ""
        echo "| Ferramenta | Categoria | Wrapper | Comandos |"
        echo "|------------|-----------|---------|----------|"

        # Ler tools.json e gerar tabela
        jq -r '.tools[] | select(.installed == true) | "| \(.name) | \(.category) | \(.wrapper) | \(.commands | map(.name) | join(", ")) |"' "$TOOLS_FILE" 2>/dev/null

        echo ""
        echo "### Como usar"
        echo ""
        echo "Executa o wrapper script com o comando desejado:"
        echo '```bash'
        echo 'cd ~/.Makan72/10-tools'
        echo 'python3 wrappers/tool_video.py convert input.mp4 output.webm'
        echo 'python3 wrappers/tool_image.py resize photo.png thumb.png --width 200'
        echo 'python3 wrappers/tool_audio.py transcribe audio.mp3 --model medium'
        echo '```'
        echo ""
        echo "Para ver todos os comandos de um wrapper: \`python3 wrappers/tool_NOME.py --help\`"
        echo "Para ver ferramentas instaladas: \`bash ~/.Makan72/10-tools/install-tools.sh status\`"
        echo ""
    } >> "$CONTEXT_FILE"
fi

# === RESULTADO DO ENV-CHECK (para agente saber que ferramentas existem) ===
if [[ -f "$MAKAN72_HOME/05-scripts/utils/env-check.sh" ]]; then
    # Capturar summary; se env-check falha com output, usar esse output (não duplicar com fallback)
    ENV_STATUS=$(bash "$MAKAN72_HOME/05-scripts/utils/env-check.sh" --summary 2>/dev/null) || ENV_STATUS="env-check indisponível"
    {
        echo ""
        echo "## AMBIENTE"
        echo ""
        echo "$ENV_STATUS"
        echo ""
    } >> "$CONTEXT_FILE"
fi

# === CONTEXTO DO PROJECTO ACTIVO (via context-builder.sh) ===
PROJECT_PATH=$(jq -r '.projects[] | select(.active==true) | .path' "$MAKAN72_HOME/01-config/projects.json" 2>/dev/null || echo "")
if [[ -n "$PROJECT_PATH" && -d "$PROJECT_PATH" && -f "$MAKAN72_HOME/05-scripts/utils/context-builder.sh" ]]; then
    {
        echo ""
        echo "## CONTEXTO DO PROJECTO ACTIVO"
        echo ""
        # Capturar output do context-builder (máx 50 linhas para não poluir)
        # NOTA: || true evita SIGPIPE (exit 141) quando head fecha o pipe cedo sob pipefail
        bash "$MAKAN72_HOME/05-scripts/utils/context-builder.sh" "$PROJECT_PATH" 2>/dev/null | head -50 || true
        echo ""
    } >> "$CONTEXT_FILE"
fi

# === COMUNICAÇÃO INTER-AGENTES (injectada em TODOS) ===
{
cat << 'COMM_HEADER'

## COMUNICAÇÃO COM OUTROS AGENTES (BUS)

Tu podes comunicar com os outros agentes do Makan72 através do sistema de ficheiros.
O bus está em `~/.Makan72/04-bus/` e os inboxes em `~/.Makan72/03-inbox/`.

### Como PASSAR TAREFA a outro agente (Handoff)

Quando terminares uma tarefa e precisares que outro agente continue, cria um ficheiro JSON em `~/.Makan72/04-bus/handoff/` com este formato:

COMM_HEADER

cat << 'COMM_JSON'
```json
{
  "id": "HANDOFF-YYYYMMDD_HHMMSS",
  "from": "SEU_NOME_AQUI",
  "to": "NOME_DO_DESTINATARIO",
  "type": "review|implement|test|fix",
  "timestamp": "YYYY-MM-DDTHH:MM:SS+TZ",
  "status": "DONE",
  "context": {
    "summary": "Descrever o que fizeste e o que falta",
    "next_steps": ["Passo 1", "Passo 2"]
  },
  "artifacts": ["caminho/para/ficheiro.md"]
}
```
COMM_JSON

cat << 'COMM_BODY'

Nomeia o ficheiro como: `handoff_YYYYMMDD_HHMMSS.json`
O team-bot processa automaticamente e entrega ao destinatário via inbox.

### Como ENVIAR MENSAGEM a outro agente

Cria um ficheiro `.md` no inbox do agente destinatário:

- Para um agente: `~/.Makan72/03-inbox/NOME_AGENTE/pending/mensagem_descritiva.md`
- Para o CEO: `~/.Makan72/03-inbox/CEO/pending/mensagem_descritiva.md`

O ficheiro deve conter: título, data, remetente (tu: ${AGENT_CODE}), e a mensagem.

### Como REPORTAR que estás vivo (Heartbeat)

Se estiveres numa tarefa longa, cria/actualiza o ficheiro:
`~/.Makan72/04-bus/heartbeat/${AGENT_CODE}_heartbeat.json`

COMM_BODY

cat << 'COMM_JSON2'
```json
{
  "agent": "SEU_NOME_AQUI",
  "timestamp": "YYYY-MM-DDTHH:MM:SS+TZ",
  "status": "alive",
  "current_task": "Descrição da tarefa actual"
}
```
COMM_JSON2

cat << 'COMM_FOOTER'

### Como VER quem está online

- Slots activos: `cat ~/.Makan72/04-bus/active_slots.json`
- Heartbeats: `ls ~/.Makan72/04-bus/heartbeat/`

### Como VER tarefas no teu inbox

`ls ~/.Makan72/03-inbox/${AGENT_CODE}/pending/`

### REGRAS DE COMUNICAÇÃO
- NUNCA sobrescrever ficheiros de outros agentes sem autorização do CEO
- Usa handoff para passar trabalho — NÃO edites directamente o trabalho de outro agente
- Se receberes tarefa via inbox de outro agente, LÊ o ficheiro e EXECUTA conforme as instruções. Se tiveres dúvida sobre o scope, cria DOUBT em 03-inbox/CEO/pending/
- Preenche SEMPRE o campo "from" com o teu nome: ${AGENT_CODE}

COMM_FOOTER
} >> "$CONTEXT_FILE"

# === INBOX AUTOMÁTICO — INSTRUÇÃO CRÍTICA ===
cat >> "$CONTEXT_FILE" << 'AUTOREAD_EOF'

## INBOX AUTOMÁTICO — INSTRUÇÃO CRÍTICA

Quando receberes uma mensagem no terminal a dizer que tens tarefa(s) nova(s) no inbox:

1. **LÊ IMEDIATAMENTE** os ficheiros pendentes:
   ```bash
   ls ~/.Makan72/03-inbox/${AGENT_CODE}/pending/
   cat ~/.Makan72/03-inbox/${AGENT_CODE}/pending/*.md
   ```

2. **EXECUTA** a tarefa conforme descrita no ficheiro (contrato, pedido, etc.)

3. **MOVE** o ficheiro para `in_progress/` quando começares:
   ```bash
   mv ~/.Makan72/03-inbox/${AGENT_CODE}/pending/FICHEIRO.md ~/.Makan72/03-inbox/${AGENT_CODE}/in_progress/
   ```

4. **MOVE** para `done/` quando terminares:
   ```bash
   mv ~/.Makan72/03-inbox/${AGENT_CODE}/in_progress/FICHEIRO.md ~/.Makan72/03-inbox/${AGENT_CODE}/done/
   ```

5. **REPORTA** com SITREP ao CEO e/ou ao agente que enviou a tarefa

Se a tarefa estiver fora do teu scope ou tiveres dúvida → NÃO executes → cria ficheiro DOUBT em `03-inbox/CEO/pending/` e aguarda.

AUTOREAD_EOF

# Substituir placeholders pelo nome real do agente (heredocs quoted não expandem variáveis)
sed -i "s|SEU_NOME_AQUI|${AGENT_CODE}|g; s|\${AGENT_CODE}|${AGENT_CODE}|g" "$CONTEXT_FILE"

# === RESULTADO ===
LINES=$(wc -l < "$CONTEXT_FILE")
SIZE=$(du -h "$CONTEXT_FILE" | cut -f1)

echo ""
echo "Contexto gerado com sucesso!"
echo "   Ficheiro: $CONTEXT_FILE"
echo "   Linhas:   $LINES"
echo "   Tamanho:  $SIZE"
echo ""
echo "   Para usar: copiar conteudo para o prompt do agente $AGENT_CODE"

# Criar heartbeat inicial para o agente (indica que está a ser iniciado)
HB_DIR="$MAKAN72_HOME/04-bus/heartbeat"
mkdir -p "$HB_DIR"
cat > "$HB_DIR/${AGENT_CODE}_heartbeat.json" << HB_EOF
{
  "agent": "$AGENT_CODE",
  "timestamp": "$(date -Iseconds)",
  "status": "alive",
  "current_task": "Iniciando sessão"
}
HB_EOF
echo "   Heartbeat: $HB_DIR/${AGENT_CODE}_heartbeat.json"

# Registar operacao se log disponivel
if [[ -f "$MAKAN72_HOME/05-scripts/utils/log-operation.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/utils/log-operation.sh"
    if type log_operation &>/dev/null; then
        log_operation "run-agent" "$AGENT_CODE" "OK" "context=${LINES}L,${SIZE}"
    fi
fi
