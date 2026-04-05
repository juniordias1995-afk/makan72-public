#!/usr/bin/env bash
# OPCIONAL: Este script só é útil se usar Zellij como multiplexer
# O Makan72 funciona sem este script

MAKAN72_HOME="${MAKAN72_HOME:-$HOME/.Makan72}"

# sys-bar.sh — Barra de status do sistema (CPU/GPU/RAM + Inbox)
# Corre no pane SYS do layout Zellij
# Usa echo com clear de linha para compatibilidade com panes Zellij

while true; do
    CPU=$(mpstat 1 1 2>/dev/null | awk 'END{gsub(",",".",$NF); printf "%.0f%%", 100-$NF}')
    GPU=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
    RAM=$(free -h | awk '/Mem/{printf "%s/%s", $3, $2}')

    # Contar inbox por agente (excluindo README.md)
    INBOX_DIR="$MAKAN72_HOME/03-inbox"
    CLAUDE_COUNT=$(find "$INBOX_DIR/CLAUDE" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
    QWEN_COUNT=$(find "$INBOX_DIR/QWEN" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
    GEMINI_COUNT=$(find "$INBOX_DIR/GEMINI" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
    INBOX_STR="C:$CLAUDE_COUNT Q:$QWEN_COUNT G:$GEMINI_COUNT"

    # Usar echo -ne com escape codes para limpar linha e reescrever
    # \033[2K = limpar linha inteira, \r = voltar ao inicio
    echo -ne "\033[2K\r  ⚡ CPU: ${CPU:-??}  │  🖥 GPU: ${GPU:-N/A}%  │  🧠 RAM: ${RAM:-??}  │  📬 $INBOX_STR"

    sleep 3
done
