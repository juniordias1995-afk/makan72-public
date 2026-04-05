#!/usr/bin/env bash
# =============================================================================
# Makan72 — Setup Script
# Instalação inicial do sistema
# =============================================================================
set -euo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
cd "$MAKAN72_HOME"

# Cores ANSI
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# Detectar OS
detect_os() {
    if [[ "${OSTYPE:-}" == "darwin"* ]]; then
        echo "macos"
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}
OS_TYPE=$(detect_os)


echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Makan72 — Setup Script v1.0.0                       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Passo 1: Verificar requisitos
echo -e "${YELLOW}[1/8] Verificando requisitos...${NC}"

# Bash 4+
if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
    echo -e "${RED}❌ Erro: Bash 4+ necessário. Actual: ${BASH_VERSION}${NC}"
    exit 1
fi
echo "  ✅ Bash ${BASH_VERSION}"

# Aviso Bash no macOS
if [[ "$OS_TYPE" == "macos" && ${BASH_VERSION%%.*} -lt 4 ]]; then
    echo -e "${YELLOW}  ⚠️  macOS: Instalar Bash 4+ via Homebrew: brew install bash${NC}"
fi

# Python 3.10+
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "  ✅ Python ${PYTHON_VERSION}"
else
    echo -e "${YELLOW}  ⚠️  Python 3 não encontrado (opcional para bots)${NC}"
fi

# jq
if command -v jq &>/dev/null; then
    echo "  ✅ jq instalado"
else
    echo -e "${YELLOW}  ⚠️  jq não encontrado (necessário para manage-agents.sh)${NC}"
    case "$OS_TYPE" in
        macos)   echo -e "${YELLOW}     Instalar: brew install jq${NC}" ;;
        fedora)  echo -e "${YELLOW}     Instalar: sudo dnf install jq${NC}" ;;
        arch)    echo -e "${YELLOW}     Instalar: sudo pacman -S jq${NC}" ;;
        debian)  echo -e "${YELLOW}     Instalar: sudo apt install jq${NC}" ;;
        *)       echo -e "${YELLOW}     Instalar jq manualmente${NC}" ;;
    esac
fi

# zellij (opcional)
if command -v zellij &>/dev/null; then
    echo "  ✅ zellij instalado"
else
    echo -e "${YELLOW}  ⚠️  zellij nao encontrado (opcional — para layout multi-tab)${NC}"
fi

# Passo 2: Criar pastas e sub-pastas
echo -e "${YELLOW}[2/8] Criando estrutura de pastas...${NC}"

mkdir -p 00-global/{cvs,onboarding}
mkdir -p 01-config/{prompts,templates,docker}
mkdir -p 02-bots/{config,lib,orchestrator,tests/fixtures}
mkdir -p 03-inbox/{ceo/{pending,read,alerts},archive}
mkdir -p 04-bus/{heartbeat,status,handoff,alerts}
mkdir -p 05-scripts/{core,utils,migration}
mkdir -p 06-reports
mkdir -p 07-archive/{agents,backups}
mkdir -p 08-logs/{logs,cache/{locks,pids,temp}}
mkdir -p 09-workspace/{tarefas,lab}

# Criar .gitkeep em pastas vazias
find . -type d -empty -exec touch {}/.gitkeep \; 2>/dev/null || true
echo "  ✅ Pastas criadas"

# Passo 3: Copiar templates para 00-global/ (se não existirem)
echo -e "${YELLOW}[3/8] Copiando templates...${NC}"

for template in VERDADE.md VACINAS.md SESSAO_HOJE.yaml; do
    src="01-config/templates/${template%.*}_TEMPLATE.md"
    [ "$template" == "SESSAO_HOJE.yaml" ] && src="01-config/templates/SESSAO_TEMPLATE.yaml"
    dst="00-global/$template"
    
    if [ -f "$dst" ]; then
        echo "  ⚠️  $dst já existe (não sobrescrito)"
    elif [ -f "$src" ]; then
        cp "$src" "$dst"
        echo "  ✅ $dst criado"
    fi
done

# Passo 4: Inicializar agents.json (se não existir)
echo -e "${YELLOW}[4/8] Inicializando agents.json...${NC}"

if [ -f "01-config/agents.json" ]; then
    echo "  ⚠️  agents.json já existe"
else
    cat > 01-config/agents.json << 'EOF'
{
  "version": "1.0",
  "agents": [],
  "tools": []
}
EOF
    echo "  ✅ agents.json criado"
fi

# Passo 4b: Inicializar projects.json (se não existir)
if [ -f "01-config/projects.json" ]; then
    echo "  ⚠️  projects.json já existe"
elif [ -f "01-config/projects.json.example" ]; then
    cp "01-config/projects.json.example" "01-config/projects.json"
    echo "  ✅ projects.json criado (vazio — adiciona projectos com: makan72 project add)"
else
    echo '{"version":"1.0","active_project":null,"projects":[]}' > 01-config/projects.json
    echo "  ✅ projects.json criado (vazio)"
fi

# Passo 4c: Inicializar active_slots.json (se não existir)
if [ ! -f "04-bus/active_slots.json" ]; then
    echo '{"slots":[]}' > 04-bus/active_slots.json
    echo "  ✅ active_slots.json inicializado"
fi

# Passo 4d: Gerar token de inbox (se não existir)
if [ -f ".inbox_token" ]; then
    echo "  ⚠️  .inbox_token já existe"
elif command -v openssl &>/dev/null; then
    openssl rand -hex 64 > .inbox_token && chmod 400 .inbox_token
    echo "  ✅ .inbox_token gerado (256 bits, chmod 400)"
else
    echo -e "${YELLOW}  ⚠️  openssl não encontrado — inbox_token não gerado (funcionalidade de segurança reduzida)${NC}"
fi

# Passo 5: Criar team.yaml base (se não existir)
echo -e "${YELLOW}[5/8] Verificando team.yaml...${NC}"

if [ -f "01-config/team.yaml" ]; then
    echo "  ⚠️  team.yaml já existe"
else
    cat > 01-config/team.yaml << 'EOF'
system:
  name: "Makan72"
  version: "1.0.0"
  owner: "CEO"

rules:
  max_active_agents: 10
  report_retention_days: 30
  archive_after_days: 30

git:
  auto_push: false
  branch: "main"

paths:
  home: "~/.Makan72"
EOF
    echo "  ✅ team.yaml criado"
fi

# Passo 6: Verificar VERSION
echo -e "${YELLOW}[6/8] Verificando VERSION...${NC}"

if [ -f "VERSION" ]; then
    echo "  ⚠️  VERSION já existe"
else
    echo "1.0.0" > VERSION
    echo "  ✅ VERSION criado"
fi

# Passo 7: Criar .env.template (se não existir)
echo -e "${YELLOW}[7/8] Criando .env.template...${NC}"

if [ -f "01-config/.env.template" ]; then
    echo "  ⚠️  .env.template já existe"
else
    cat > 01-config/.env.template << 'ENVTEMPLATE'
# Makan72 — Environment Variables
# Copiar para .env e preencher com as tuas credenciais

# API Keys (descomentar e preencher)
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# GOOGLE_API_KEY=...
# GROQ_API_KEY=...

# Configuracoes opcionais
# MAKAN72_HOME=$HOME/.Makan72
# MAKAN72_LOG_LEVEL=INFO
ENVTEMPLATE
    echo "  ✅ .env.template criado"
fi

# Passo 8: Configurar .gitignore (se não existir)
echo -e "${YELLOW}[8/8] Verificando .gitignore...${NC}"

if [ -f ".gitignore" ]; then
    echo "  ⚠️  .gitignore já existe"
else
    cat > .gitignore << 'EOF'
# Cache e temporários
08-logs/cache/
08-logs/logs/*.log

# Sinais em tempo real
04-bus/heartbeat/
04-bus/status/
04-bus/alerts/

# Segredos
01-config/.env
01-config/secrets.*
*.env

# Sistema
__pycache__/
*.pyc
.DS_Store
EOF
    echo "  ✅ .gitignore criado"
fi

# Passo 8b: Configurar bash completion
echo -e "${YELLOW}[8b/9] Configurando bash completion...${NC}"

COMPLETION_LINE="source $MAKAN72_HOME/05-scripts/utils/makan72-completion.sh"
if grep -q "makan72-completion.sh" ~/.bashrc 2>/dev/null; then
    echo "  ✓ Bash completion já configurado no ~/.bashrc"
else
    echo "$COMPLETION_LINE" >> ~/.bashrc
    echo "  ✅ Bash completion adicionado ao ~/.bashrc"
fi

# Passo 9: Mensagem de sucesso
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Makan72 instalado com sucesso!                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Próximos passos:"
echo "  1. Adicionar agentes: ./05-scripts/core/manage-agents.sh add CLAUDE \"Claude Opus 4.6\" claude"
echo "  2. Configurar .env: cp 01-config/.env.template .env"
echo "  3. Criar sessão: editar 00-global/SESSAO_HOJE.yaml"
echo "  4. Iniciar: ./05-scripts/tools/start-session.sh"
echo ""
