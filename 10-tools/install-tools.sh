#!/usr/bin/env bash
# install-tools.sh — Instalador de Ferramentas Makan72
# Autor: QWEN (MC)
# Data: 2026-04-04

set -uo pipefail

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"
TOOLS_DIR="$MAKAN72_HOME/10-tools"
TOOLS_JSON="$TOOLS_DIR/tools.json"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
install-tools.sh — Instalador de Ferramentas Makan72

Uso: install-tools.sh <comando>

COMANDOS:
  all          Instalar todas as ferramentas
  fase1        Instalar ferramentas base (FFmpeg, ImageMagick, GIMP, yt-dlp, rembg)
  fase2        Instalar ferramentas criativas (Blender, Manim, Pygame, Godot, Tiled, Open3D)
  fase3        Instalar ferramentas AI/GPU (Whisper, Coqui TTS, Bark, ComfyUI)
  <tool_id>    Instalar ferramenta específica (ex: ffmpeg-video, blender)
  status       Mostrar estado de instalação de todas as ferramentas

EXEMPLOS:
  bash install-tools.sh fase1
  bash install-tools.sh ffmpeg-video
  bash install-tools.sh status
EOF
}

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Verificar se ferramenta está instalada
is_installed() {
    local tool_id="$1"
    local binary
    local python_import
    
    binary=$(jq -r --arg id "$tool_id" '.tools[] | select(.id==$id) | .binary' "$TOOLS_JSON" 2>/dev/null)
    
    # Se binary for null ou vazio, verificar python import
    if [[ -z "$binary" || "$binary" == "null" ]]; then
        # Mapear tool_id para python import
        case "$tool_id" in
            pygame) python_import="pygame" ;;
            bark) python_import="bark" ;;
            comfyui) 
                # Verificar se diretório comfyui existe
                [[ -d "$TOOLS_DIR/comfyui" ]] && return 0 || return 1
                ;;
            *) python_import="" ;;
        esac
        
        if [[ -n "$python_import" ]]; then
            python3 -c "import $python_import" 2>/dev/null
            return $?
        fi
        return 1
    fi
    
    # Verificar binary
    command -v "$binary" &>/dev/null
    return $?
}

# Actualizar tools.json
update_installed_status() {
    local tool_id="$1"
    local status="$2"
    
    python3 -c "
import json
with open('$TOOLS_JSON', 'r') as f:
    data = json.load(f)
for tool in data['tools']:
    if tool['id'] == '$tool_id':
        tool['installed'] = $status
        break
with open('$TOOLS_JSON', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Instalar ferramenta
install_tool() {
    local tool_id="$1"
    local install_cmd
    local binary
    
    # Obter install_cmd do JSON
    install_cmd=$(jq -r --arg id "$tool_id" '.tools[] | select(.id==$id) | .install_cmd' "$TOOLS_JSON" 2>/dev/null)
    binary=$(jq -r --arg id "$tool_id" '.tools[] | select(.id==$id) | .binary' "$TOOLS_JSON" 2>/dev/null)
    
    if [[ -z "$install_cmd" || "$install_cmd" == "null" ]]; then
        log_error "Ferramenta '$tool_id' não encontrada"
        return 1
    fi
    
    # Verificar se já está instalada
    if is_installed "$tool_id"; then
        log_info "$tool_id: Já instalada"
        update_installed_status "$tool_id" true
        return 0
    fi
    
    log_info "$tool_id: Instalando..."
    
    # Casos especiais
    case "$tool_id" in
        comfyui)
            install_comfyui
            local result=$?
            if [[ $result -eq 0 ]]; then
                update_installed_status "$tool_id" true
                log_success "$tool_id: Instalada com sucesso"
            else
                log_error "$tool_id: Falha na instalação"
            fi
            return $result
            ;;
    esac
    
    # Executar install_cmd
    if eval "$install_cmd" 2>/dev/null; then
        # Verificar se instalou
        sleep 1
        if is_installed "$tool_id"; then
            update_installed_status "$tool_id" true
            log_success "$tool_id: Instalada com sucesso"
            return 0
        else
            log_warn "$tool_id: Comando executado mas binary não encontrado"
            return 1
        fi
    else
        log_error "$tool_id: Falha na instalação"
        return 1
    fi
}

# Instalar ComfyUI (caso especial)
install_comfyui() {
    log_info "comfyui: Clonando repositório..."
    
    if [[ -d "$TOOLS_DIR/comfyui" ]]; then
        log_info "comfyui: Diretório já existe"
    else
        git clone https://github.com/comfyanonymous/ComfyUI.git "$TOOLS_DIR/comfyui" 2>/dev/null || {
            log_error "comfyui: Falha ao clonar"
            return 1
        }
    fi
    
    log_info "comfyui: Instalando dependências..."
    (cd "$TOOLS_DIR/comfyui" && pip install --break-system-packages -r requirements.txt 2>/dev/null) || {
        log_error "comfyui: Falha ao instalar dependências"
        return 1
    }
    
    log_info "comfyui: Download do modelo SD 1.5..."
    mkdir -p "$TOOLS_DIR/models"
    local model_url="https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
    
    if [[ ! -f "$TOOLS_DIR/models/sd-v1-5.safetensors" ]]; then
        wget -O "$TOOLS_DIR/models/sd-v1-5.safetensors" "$model_url" 2>/dev/null || {
            log_warn "comfyui: Falha ao download modelo (continuar mesmo assim)"
        }
    fi
    
    # Symlink para comfyui
    mkdir -p "$TOOLS_DIR/comfyui/models/checkpoints"
    if [[ -f "$TOOLS_DIR/models/sd-v1-5.safetensors" ]]; then
        ln -sf "$TOOLS_DIR/models/sd-v1-5.safetensors" "$TOOLS_DIR/comfyui/models/checkpoints/" 2>/dev/null || true
    fi
    
    log_success "comfyui: Instalado"
    return 0
}

# Mostrar status
show_status() {
    echo ""
    echo "=== STATUS DAS FERRAMENTAS ==="
    echo ""
    printf "%-20s %-15s %-15s %-10s\n" "ID" "STATUS" "BINARY" "IMPORT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    jq -r '.tools[] | "\(.id)|\(.binary // "null")"' "$TOOLS_JSON" 2>/dev/null | while IFS='|' read -r tool_id binary; do
        local status_icon status_text python_import
        
        if is_installed "$tool_id"; then
            status_icon="✅"
            status_text="INSTALADA"
        else
            status_icon="❌"
            status_text="NAO INST"
        fi
        
        # Mapear import Python
        case "$tool_id" in
            pygame) python_import="pygame" ;;
            bark) python_import="bark" ;;
            *) python_import="-" ;;
        esac
        
        [[ -z "$binary" || "$binary" == "null" ]] && binary="-"
        
        printf "%-20s %-15s %-15s %-10s\n" "$tool_id" "$status_icon $status_text" "$binary" "$python_import"
    done
    
    echo ""
}

# Listar ferramentas por fase
get_fase_tools() {
    local fase="$1"
    case "$fase" in
        fase1)
            echo "ffmpeg-video ffmpeg-audio imagemagick gimp yt-dlp rembg"
            ;;
        fase2)
            echo "blender manim pygame godot tiled open3d"
            ;;
        fase3)
            echo "whisper coqui-tts bark comfyui"
            ;;
        all)
            jq -r '.tools[].id' "$TOOLS_JSON" 2>/dev/null
            ;;
    esac
}

# Main
CMD="${1:-help}"

case "$CMD" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    status)
        show_status
        exit 0
        ;;
    fase1|fase2|fase3|all)
        log_info "Instalando ferramentas: $CMD"
        echo ""
        
        installed=0
        skipped=0
        failed=0
        
        for tool_id in $(get_fase_tools "$CMD"); do
            if is_installed "$tool_id"; then
                skipped=$((skipped + 1))
                continue
            fi
            
            if install_tool "$tool_id"; then
                installed=$((installed + 1))
            else
                failed=$((failed + 1))
            fi
        done
        
        echo ""
        echo "=== RESUMO ==="
        echo "Instaladas: $installed"
        echo "Já existiam: $skipped"
        echo "Falharam: $failed"
        ;;
    *)
        # Instalar ferramenta específica
        install_tool "$CMD"
        ;;
esac
