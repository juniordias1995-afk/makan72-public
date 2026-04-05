#!/usr/bin/env bash
set -euo pipefail

# manage-projects.sh — Gestao de Projectos Makan72

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

# Carregar biblioteca comum
if [[ -f "$MAKAN72_HOME/05-scripts/lib/common.sh" ]]; then
    source "$MAKAN72_HOME/05-scripts/lib/common.sh"
fi
# 7 comandos: create, register, list, switch, info, remove, active

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
PROJECTS_FILE="$MAKAN72_HOME/01-config/projects.json"
SESSAO_FILE="$MAKAN72_HOME/01-config/sessoes/SESSAO_HOJE.yaml"
TMP_DIR="/tmp/makan72_$$"  # PID unico por processo
mkdir -p "$TMP_DIR"
trap "rm -rf $TMP_DIR" EXIT

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


is_inside_makan72() {
    local path="$1"
    local real_makan72=$(realpath "$MAKAN72_HOME" 2>/dev/null || echo "$MAKAN72_HOME")
    local real_path=$(realpath "$path" 2>/dev/null || echo "$path")
    [[ "$real_path" == "$real_makan72"* ]]
}

generate_id() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -cd '[:alnum:]-_'
}

get_project() {
    local name_or_id="${1:-}"
    python3 -c "
import json
with open('$PROJECTS_FILE') as f:
    data = json.load(f)
for p in data['projects']:
    if p['id'] == '$name_or_id' or p['name'].lower() == '$name_or_id'.lower():
        print(json.dumps(p))
        exit(0)
exit(1)
" 2>/dev/null || return 1
}

set_active_project() {
    local project_id="$1"
    python3 -c "
import json
with open('$PROJECTS_FILE') as f:
    data = json.load(f)
data['active_project'] = '$project_id'
for p in data['projects']:
    p['active'] = (p['id'] == '$project_id')
with open('$PROJECTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
}

create_flow_template() {
    local project_name="$1"
    cat << 'FLOWEOF'
=========================================
  DIAGRAMA DE FLUXO — PROJECT_NAME
=========================================

  Edita este ficheiro para desenhar o
  fluxo da tua aplicacao. Usa ASCII art.

  Exemplo:

  ┌─────────┐    ┌──────────┐    ┌────┐
  │  Input  │───→│ Process  │───→│ DB │
  └─────────┘    └──────────┘    └────┘
       │              │
       ▼              ▼
  ┌─────────┐    ┌──────────┐
  │  Auth   │───→│ Output   │
  └─────────┘    └──────────┘

  Este diagrama aparece no tab MAP do
  terminal do agente (ex: Zellij, tmux, ou tab separado).

  Dica: Usa caracteres Unicode:
    ─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
    → ← ↑ ↓ ▶ ◀ ▲ ▼

=========================================
FLOWEOF
}

cmd_create() {
    local name=""
    local path=""
    local template=""
    
    # MODO INTERACTIVO: Se nao ha argumentos, perguntar
    if [[ $# -eq 0 ]]; then
        echo ""
        echo -e "${BLUE}📦 Criar novo projecto${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        read -t 60 -p "Nome do projecto: " name
        [[ -z "$name" ]] && error "Nome não pode ser vazio"
        
        local default_path="$HOME/Projects/$name"
        read -t 60 -p "Path (Enter = $default_path): " path
        [[ -z "$path" ]] && path="$default_path"
        
        echo ""
        echo "Templates disponíveis: web, api, mobile, desktop, cli-tool"
        read -t 60 -p "Template (Enter = nenhum): " template
        
        echo ""
        echo -e "Nome:     ${GREEN}$name${NC}"
        echo -e "Path:     ${GREEN}$path${NC}"
        echo -e "Template: ${GREEN}${template:-nenhum}${NC}"
        echo ""
        read -t 30 -p "Confirmar? (s/N): " confirm
        [[ "$confirm" != "s" && "$confirm" != "S" ]] && { echo "Cancelado."; exit 0; }
        
        echo ""
    fi
    
    # Parse argumentos com suporte a --template= e --path=
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --template=*)
                template="${1#--template=}"
                shift
                ;;
            --path=*)
                path="${1#--path=}"
                shift
                ;;
            --name=*)
                name="${1#--name=}"
                shift
                ;;
            *)
                if [[ -z "$name" ]]; then
                    name="$1"
                elif [[ -z "$path" ]]; then
                    path="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Path default
    if [[ -z "$path" ]]; then
        path="$HOME/Projects/$name"
    fi
    
    [[ -z "$name" ]] && error "Uso: manage-projects.sh create <nome> [--template=web|api|mobile|desktop|cli-tool] [--path=/caminho]"
    path="${path/#\~/$HOME}"
    
    if is_inside_makan72 "$path"; then
        error "Projectos NAO podem viver dentro do Makan72"
    fi
    
    if [[ -d "$path" ]]; then
        error "Pasta ja existe: $path"
    fi
    
    if get_project "$name" >/dev/null 2>&1; then
        error "Projecto '$name' ja registado"
    fi
    
    if [[ "$path" == "$HOME/Projects/"* ]]; then
        mkdir -p "$HOME/Projects"
    fi
    
    # Carregar template se especificado
    local template_dir="$MAKAN72_HOME/01-config/templates/projects"
    local use_template="false"
    
    if [[ -n "$template" && -d "$template_dir/$template" ]]; then
        use_template="true"
        info "  Template: $template"
    elif [[ -n "$template" ]]; then
        warn "Template '$template' nao encontrado. Usando estrutura padrao."
        template=""
    fi
    
    mkdir -p "$path" "$path/src" "$path/docs"
    touch "$path/src/.gitkeep" "$path/docs/.gitkeep"
    
    local date_today=$(date +%Y-%m-%d)
    
    # Criar README.md (com ou sem template)
    if [[ "$use_template" == "true" && -f "$template_dir/$template/structure.yaml" ]]; then
        # Ler template e substituir variaveis
        local readme_content
        readme_content=$(python3 << PYEOF
import yaml
import re

with open('$template_dir/_STANDARD/structure.yaml') as f:
    std = yaml.safe_load(f)

with open('$template_dir/$template/structure.yaml') as f:
    tpl = yaml.safe_load(f)

# Combinar ficheiros (template override standard)
files = {}
for f in std.get('files', []):
    files[f['name']] = f.get('content', '')
for f in tpl.get('files', []):
    files[f['name']] = f.get('content', '')

# Substituir variaveis
vars = {
    'PROJECT_NAME': '$name',
    'PROJECT_NAME_LOWER': '$name'.lower(),
    'TEMPLATE_NAME': '$template',
    'DESCRIPTION': 'Projecto criado com Makan72',
}

readme = files.get('README.md', '# {PROJECT_NAME}')
for k, v in vars.items():
    readme = readme.replace('{' + k + '}', v)

print(readme)
PYEOF
)
        echo "$readme_content" > "$path/README.md"
    else
        echo "# $name" > "$path/README.md"
        echo "" >> "$path/README.md"
        echo "Projecto criado em $date_today" >> "$path/README.md"
        echo "" >> "$path/README.md"
        echo "## Descricao" >> "$path/README.md"
        echo "" >> "$path/README.md"
        echo "(Descreve o teu projecto aqui)" >> "$path/README.md"
    fi
    
    # Criar .gitignore (com ou sem template)
    if [[ "$use_template" == "true" ]]; then
        local gitignore_content
        gitignore_content=$(python3 << PYEOF
import yaml

with open('$template_dir/_STANDARD/structure.yaml') as f:
    std = yaml.safe_load(f)

for f in std.get('files', []):
    if f['name'] == '.gitignore':
        print(f.get('content', ''))
        break
PYEOF
)
        echo "$gitignore_content" > "$path/.gitignore"
    else
        cat > "$path/.gitignore" << 'GITEOF'
# Python
__pycache__/
*.py[cod]
*.so
.Python
venv/
.env

# Node
node_modules/
npm-debug.log

# Geral
*.log
.DS_Store
*.swp
*.swo
*~
GITEOF
    fi
    
    # Criar FLOW.txt
    create_flow_template "$name" | sed "s/PROJECT_NAME/$name/" > "$path/docs/FLOW.txt"
    
    # Criar ficheiros adicionais do template
    if [[ "$use_template" == "true" ]]; then
        info "  A criar ficheiros do template..."
        
        python3 << PYEOF
import yaml
import os
import re

template_dir = '$template_dir'
template = '$template'
project_path = '$path'
project_name = '$name'
project_name_lower = '$name'.lower()

# Carregar standard + template
with open(f'{template_dir}/_STANDARD/structure.yaml') as f:
    std = yaml.safe_load(f)

with open(f'{template_dir}/{template}/structure.yaml') as f:
    tpl = yaml.safe_load(f)

# Combinar folders
folders = set(std.get('folders', []))
folders.update(tpl.get('folders', []))

# Criar folders
for folder in folders:
    full_path = os.path.join(project_path, folder)
    os.makedirs(full_path, exist_ok=True)
    # Criar .gitkeep em folders vazios
    gitkeep = os.path.join(full_path, '.gitkeep')
    if not os.path.exists(gitkeep):
        open(gitkeep, 'w').close()

# Combinar ficheiros (template override standard)
files = {}
for f in std.get('files', []):
    files[f['name']] = f.get('content', '')
for f in tpl.get('files', []):
    files[f['name']] = f.get('content', '')

# Substituir variaveis
vars = {
    'PROJECT_NAME': project_name,
    'PROJECT_NAME_LOWER': project_name_lower,
    'TEMPLATE_NAME': template,
    'DESCRIPTION': 'Projecto criado com Makan72',
}

# Criar ficheiros
for filename, content in files.items():
    # Ignorar ficheiros ja criados
    if filename in ['README.md', '.gitignore']:
        continue
    
    full_path = os.path.join(project_path, filename)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    
    # Substituir variaveis
    for k, v in vars.items():
        content = content.replace('{' + k + '}', v)
    
    with open(full_path, 'w') as f:
        f.write(content)
    
    print(f"    {filename}")
PYEOF
    fi
    
    (cd "$path" && git init -q && git add . && git commit -q -m "Initial commit")
    
    local project_id=$(generate_id "$name")
    
    python3 << PYEOF
import json
with open('$PROJECTS_FILE') as f:
    data = json.load(f)

new_project = {
    'id': '$project_id',
    'name': '$name',
    'path': '$path',
    'created': '$date_today',
    'active': True
}

for p in data['projects']:
    p['active'] = False

data['projects'].append(new_project)
data['active_project'] = '$project_id'

with open('$PROJECTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
    
    success "Projecto \"$name\" criado em $path"
    echo "  README.md criado"
    echo "  .gitignore criado"
    echo "  src/ criado"
    echo "  docs/ criado"
    echo "  docs/FLOW.txt criado (template de diagrama)"
    echo "  git init OK"
    info "  Registado em projects.json"
    info "  Definido como projecto activo"
}

cmd_register() {
    local path="$1"
    
    [[ -z "$path" ]] && error "Uso: manage-projects.sh register <path>"
    path="${path/#\~/$HOME}"
    
    if [[ ! -d "$path" ]]; then
        error "Pasta nao existe: $path"
    fi
    
    if is_inside_makan72 "$path"; then
        error "Projectos NAO podem viver dentro do Makan72"
    fi
    
    local name=$(basename "$path")
    local project_id=$(generate_id "$name")
    
    if get_project "$name" >/dev/null 2>&1; then
        error "Projecto '$name' ja registado"
    fi
    
    local date_today=$(date +%Y-%m-%d)
    
    python3 << PYEOF
import json
with open('$PROJECTS_FILE') as f:
    data = json.load(f)

new_project = {
    'id': '$project_id',
    'name': '$name',
    'path': '$path',
    'created': '$date_today',
    'active': True
}

for p in data['projects']:
    p['active'] = False

data['projects'].append(new_project)
data['active_project'] = '$project_id'

with open('$PROJECTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
    
    update_session "$name" "$path"
    
    success "Projecto \"$name\" registado ($path)"
    info "  Definido como projecto activo"
}

cmd_list() {
    python3 << 'PYEOF'
import json
import os

projects_file = os.environ.get('PROJECTS_FILE', f"{os.environ.get('MAKAN72_HOME', os.path.expanduser('~/.Makan72'))}/01-config/projects.json")
with open(projects_file) as f:
    data = json.load(f)

projects = data['projects']
active_id = data['active_project']

if not projects:
    print('Nenhum projecto registado. Use: manage-projects.sh create <nome>')
    exit(0)

print('PROJECTOS REGISTADOS:')
print('=' * 40)

for p in projects:
    marker = '*' if p['active'] else ' '
    active_str = 'activo' if p['active'] else ''
    print(f'  {marker} {p["name"]:<12} | {p["path"]:<30} | {active_str}')

print()
active_count = sum(1 for p in projects if p['active'])
print(f'Total: {len(projects)} projectos ({active_count} activo)')
PYEOF
}

cmd_switch() {
    local name_or_id="${1:-}"

    # MODO INTERACTIVO: Se não há argumentos, mostrar lista numerada
    if [[ -z "$name_or_id" ]]; then
        echo ""
        echo -e "${BLUE}🔄 Mudar projecto activo${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Listar projectos numerados
        python3 << 'LISTPY'
import json
import os

projects_file = os.environ.get('PROJECTS_FILE', f"{os.environ.get('MAKAN72_HOME', os.path.expanduser('~/.Makan72'))}/01-config/projects.json")
with open(projects_file) as f:
    data = json.load(f)

projects = data['projects']
active_id = data['active_project']

if not projects:
    print("Nenhum projecto registado. Use: manage-projects.sh create")
    exit(0)

print("Projectos disponíveis:")
for i, p in enumerate(projects, 1):
    active_marker = " ← ACTIVO" if p['active'] else ""
    print(f"  {i}. {p['name']} ({p['path']}){active_marker}")

print()
# Guardar mapping para o shell usar
with open('$TMP_DIR/switch_map.json', 'w') as f:
    json.dump({'projects': projects, 'active_id': active_id}, f)
LISTPY

        read -t 60 -p "Escolher (1-N): " choice

        # Validar escolha
        if [[ -z "$choice" ]]; then
            error "Escolha não pode ser vazia"
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            error "Escolha deve ser número"
        fi

        # Ler mapping e validar
        local num_projects=$(python3 -c "import json; print(len(json.load(open('$TMP_DIR/switch_map.json'))['projects']))")

        if [[ "$choice" -lt 1 || "$choice" -gt "$num_projects" ]]; then
            error "Escolha inválida (1-$num_projects)"
        fi

        # Obter projecto escolhido
        name_or_id=$(python3 << 'SELPY'
import json
import os

choice = int(os.environ.get('choice', '0'))
with open('$TMP_DIR/switch_map.json') as f:
    data = json.load(f)

projects = data['projects']
selected = projects[choice - 1]
print(selected['id'])
SELPY
)
        export choice
        name_or_id=$(python3 -c "import json; print(json.load(open('$TMP_DIR/switch_map.json'))['projects'][$choice - 1]['id'])")

        echo ""
    fi

    # ... resto da função original (continuar com o switch normal)
    local project
    project=$(get_project "$name_or_id") || error "Projecto '$name_or_id' nao encontrado"

    local path=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['path'])")
    local name=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
    local project_id=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

    if [[ ! -d "$path" ]]; then
        warn "Pasta nao existe — projecto pode ter sido movido"
    fi

    set_active_project "$project_id"
    update_session "$name" "$path"

    success "Projecto activo: $name ($path)"
    if [[ -f "$SESSAO_FILE" ]]; then
        info "  SESSAO_HOJE.yaml actualizado"
    fi
}

cmd_info() {
    local name_or_id="${1:-}"
    
    if [[ -z "$name_or_id" ]]; then
        name_or_id=$(python3 -c "import json; print(json.load(open('$PROJECTS_FILE'))['active_project'] or '')")
        [[ -z "$name_or_id" ]] && error "Nenhum projecto activo. Use: manage-projects.sh info <nome>"
    fi
    
    local project
    project=$(get_project "$name_or_id") || error "Projecto '$name_or_id' nao encontrado"
    
    local path=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['path'])")
    local name=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
    local created=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['created'])")
    local is_active=$(echo "$project" | python3 -c "import sys,json; print('SIM' if json.load(sys.stdin)['active'] else 'NAO')")
    
    local git_commits=0
    local git_branch="N/A"
    if [[ -d "$path/.git" ]]; then
        git_commits=$(git -C "$path" log --oneline 2>/dev/null | wc -l)
        git_branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "N/A")
    fi
    
    local file_count=$(find "$path" -type f 2>/dev/null | grep -v '.git/' | wc -l)
    local dir_count=$(find "$path" -type d 2>/dev/null | grep -v '.git/' | wc -l)
    local has_readme=$([ -f "$path/README.md" ] && echo "SIM" || echo "NAO")
    local has_flow=$([ -f "$path/docs/FLOW.txt" ] && echo "SIM" || echo "NAO")
    
    echo "PROJECTO: $name"
    echo "=========================================="
    echo "  Path:    $path"
    echo "  Criado:  $created"
    echo "  Activo:  $is_active"
    echo ""
    echo "  Deteccao automatica:"
    if [[ $git_commits -gt 0 ]]; then
        echo "    Git:       SIM (branch: $git_branch, $git_commits commits)"
    else
        echo "    Git:       NAO"
    fi
    echo "    Ficheiros: $file_count"
    echo "    Pastas:    $dir_count"
    echo "    README:    $has_readme"
    echo "    FLOW.txt:  $has_flow"
}

cmd_remove() {
    local name_or_id="${1:-}"
    
    [[ -z "$name_or_id" ]] && error "Uso: manage-projects.sh remove <nome_ou_id>"
    
    local project
    project=$(get_project "$name_or_id") || error "Projecto '$name_or_id' nao encontrado"
    
    local path=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['path'])")
    local name=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
    local project_id=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
    
    # Confirmação dupla para remoção
    echo ""
    echo -e "${RED}⚠️  ATENÇÃO: Vai remover o projecto "$name" do registo${NC}"
    echo "  Path: $path"
    echo ""
    read -p "Escreva '$name' para confirmar: " confirm_name
    if [[ "$confirm_name" != "$name" ]]; then
        echo "Cancelado."
        exit 0
    fi
    echo ""
    
    python3 << PYEOF
import json
with open('$PROJECTS_FILE') as f:
    data = json.load(f)

data['projects'] = [p for p in data['projects'] if p['id'] != '$project_id']
if data['active_project'] == '$project_id':
    data['active_project'] = None

with open('$PROJECTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
    
    success "Projecto \"$name\" removido do registo"
    info "  Ficheiros em $path NAO foram apagados"
}

cmd_active() {
    local active_id=$(python3 -c "import json; print(json.load(open('$PROJECTS_FILE'))['active_project'] or '')")
    
    if [[ -z "$active_id" ]]; then
        echo "Nenhum projecto activo. Use: manage-projects.sh switch <nome>"
        exit 0
    fi
    
    local project=$(get_project "$active_id")
    local name=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
    local path=$(echo "$project" | python3 -c "import sys,json; print(json.load(sys.stdin)['path'])")
    
    echo "Projecto activo: $name ($path)"
}

update_session() {
    local name="$1"
    local path="$2"
    
    if [[ ! -f "$SESSAO_FILE" ]]; then
        return 0
    fi
    
    python3 << PYEOF
import yaml
with open('$SESSAO_FILE') as f:
    data = yaml.safe_load(f)

if 'sessao' not in data:
    data['sessao'] = {}

data['sessao']['projecto'] = '$name'
data['sessao']['projecto_path'] = '$path'

with open('$SESSAO_FILE', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
PYEOF
}

show_help() {
    echo "manage-projects.sh — Gestao de Projectos Makan72"
    echo ""
    echo "Uso: manage-projects.sh <comando> [argumentos]"
    echo ""
    echo "Comandos:"
    echo "  create <nome> [path]            Criar novo projecto"
echo "  create <nome> --template=web    Criar com template Web"
echo "  create <nome> --template=api    Criar com template API"
echo "  create <nome> --template=mobile  Criar com template Mobile"
echo "  create <nome> --template=desktop Criar com template Desktop"
echo "  create <nome> --template=cli-tool Criar com template CLI"
    echo "  register <path>        Registar projecto existente"
    echo "  list                   Listar projectos registados"
    echo "  switch <nome_ou_id>    Mudar projecto activo"
    echo "  info [nome_ou_id]      Detalhes do projecto"
    echo "  remove <nome_ou_id>    Remover do registo"
    echo "  active                 Ver projecto activo"
}

CMD="${1:-help}"
shift 2>/dev/null || true

case "$CMD" in
    create)  cmd_create "$@" ;;
    register) cmd_register "$@" ;;
    list)    cmd_list "$@" ;;
    switch)  cmd_switch "$@" ;;
    info)    cmd_info "$@" ;;
    remove)  cmd_remove "$@" ;;
    active)  cmd_active "$@" ;;
    help|--help|-h) show_help ;;
    *)       error "Comando desconhecido: $CMD. Use 'manage-projects.sh help'" ;;
esac
