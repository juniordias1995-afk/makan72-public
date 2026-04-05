# 10-tools — Sistema de Ferramentas Criativas Makan72

**Versao:** 1.1
**Data:** 2026-04-05
**Status:** 16/16 funcional (14 originais + 2 substitutos)

---

## O Que E

O `10-tools/` e o directorio central de ferramentas criativas do Makan72. Contem:

- **Registry central** (`tools.json`) — Lista todas as ferramentas disponiveis
- **Instalador** (`install-tools.sh`) — Instala ferramentas com um comando
- **Wrapper scripts** (`wrappers/`) — Interfaces Python simplificadas para cada ferramenta
- **Modelos AI** (`models/`) — Pasta para modelos de IA (gitignored)

---

## Instalacao Rapida

```bash
cd ~/.Makan72/10-tools

# Ver status
bash install-tools.sh status

# Instalar ferramentas base (FFmpeg, ImageMagick, etc.)
bash install-tools.sh fase1

# Instalar tudo
bash install-tools.sh all
```

---

## Ferramentas Disponiveis

### Video
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| FFmpeg Video | `ffmpeg` | 6.1.1 | OK |

### Imagem
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| ImageMagick | `convert` | 6.9.12 | OK |
| GIMP | `gimp` | 2.10.36 | OK |
| rembg | `rembg` | 2.0.74 | OK |

### Audio
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| FFmpeg Audio | `ffmpeg` | 6.1.1 | OK |
| Whisper | `whisper` | 20250625 | OK |
| edge-tts | `edge-tts` | 7.2.8 | OK (substitui Coqui TTS) |
| Bark | python | 0.0.1a0 | OK |

### Jogos
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| Pygame | python | 2.6.1 | OK |
| Godot | `godot` | 4.4.1 | OK (~/.local/bin/godot) |
| Tiled | `tiled` | 1.8.2 | OK |

### 3D
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| Blender | `blender` | 4.0.2 | OK |
| Open3D | python | 0.19.0 | OK |

### Animacao
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| Manim | `manim` | 0.20.1 | OK |

### IA
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| diffusers | python | 0.37.1 | OK (substitui ComfyUI) |

### Download
| Ferramenta | Binary | Versao | Status |
|------------|--------|--------|--------|
| yt-dlp | `yt-dlp` | 2026.03.17 | OK |

---

## Substituicoes

| Original | Substituto | Motivo |
|----------|-----------|--------|
| Coqui TTS | **edge-tts** | Coqui incompativel com Python 3.12 |
| ComfyUI | **diffusers** | ComfyUI requer CUDA 13.0 (driver e 12.8), partia o torch |

---

## GPU

| Campo | Valor |
|-------|-------|
| GPU | NVIDIA GeForce RTX 3060 Laptop |
| VRAM | 5.7 GB |
| Driver | 570.211.01 |
| CUDA | 12.8 |
| torch | 2.10.0+cu128 |
| torchaudio | 2.10.0+cu128 |
| torchvision | 0.25.0+cu128 |

**REGRA:** NAO instalar pacotes que exijam CUDA > 12.8 sem venv isolado.

---

## Como Usar

### Via Wrapper Scripts

```bash
cd ~/.Makan72/10-tools

# Video
python3 wrappers/tool_video.py convert input.mp4 output.webm
python3 wrappers/tool_video.py cut video.mp4 clip.mp4 --start 00:01:00 --end 00:02:00

# Imagem
python3 wrappers/tool_image.py resize image.png small.png --width 800
python3 wrappers/tool_image.py remove-bg photo.png no-bg.png

# Audio
python3 wrappers/tool_audio.py transcribe podcast.mp3 --model medium --language pt
edge-tts --voice pt-PT-RaquelNeural --text 'Ola mundo' --write-media output.mp3

# AI
python3 wrappers/tool_ai.py generate 'a fantasy castle' output.png --steps 20

# Download
python3 wrappers/tool_download.py download 'https://youtube.com/...' output_dir/
```

### Vozes edge-tts (PT)

| Voz | Genero | Variante |
|-----|--------|----------|
| pt-PT-RaquelNeural | Feminina | Portugal |
| pt-PT-DuarteNeural | Masculino | Portugal |
| pt-BR-FranciscaNeural | Feminina | Brasil |
| pt-BR-AntonioNeural | Masculino | Brasil |
| pt-BR-ThalitaMultilingualNeural | Feminina | Brasil (multilingual) |

---

## Fases de Instalacao

### Fase 1 — Base
- FFmpeg (video + audio)
- ImageMagick
- GIMP
- yt-dlp
- rembg

### Fase 2 — Criativa
- Blender (3D)
- Manim (animacao)
- Pygame (jogos 2D)
- Godot (jogos 2D/3D)
- Tiled (mapas)
- Open3D

### Fase 3 — AI/GPU
- Whisper (transcricao)
- edge-tts (voz — substitui Coqui TTS)
- Bark (audio expressivo)
- diffusers (geracao de imagens — substitui ComfyUI)

---

## Estrutura de Pastas

```
10-tools/
├── README.md              <- Esta documentacao
├── tools.json             <- Registry central (FONTE UNICA)
├── install-tools.sh       <- Instalador master
├── wrappers/              <- Wrapper scripts Python
│   ├── tool_video.py      <- FFmpeg wrapper
│   ├── tool_image.py      <- ImageMagick + rembg
│   ├── tool_audio.py      <- FFmpeg + Whisper + edge-tts + Bark
│   ├── tool_3d.py         <- Blender + Open3D
│   ├── tool_animation.py  <- Manim
│   ├── tool_game.py       <- Pygame + Godot + Tiled
│   ├── tool_ai.py         <- diffusers
│   └── tool_download.py   <- yt-dlp
└── models/                <- Modelos AI (gitignored)
    └── .gitkeep
```

---

## Integracao com Agentes

Os wrappers sao automaticamente injectados no contexto de todos os agentes via `run-agent.sh`.

---

**Makan72 — 100% local, 0 logins, 0 pagamentos**
