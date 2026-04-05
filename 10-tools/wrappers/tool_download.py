#!/usr/bin/env python3
"""tool_download.py — Wrapper para yt-dlp
Uso: python3 tool_download.py <comando> [argumentos]
     python3 tool_download.py --help
"""
import subprocess
import sys
import argparse
import shutil
from pathlib import Path


def check_ytdlp():
    """Verificar se yt-dlp está instalado."""
    if not shutil.which("yt-dlp"):
        print("ERRO: yt-dlp não encontrado. pip install yt-dlp", file=sys.stderr)
        sys.exit(1)


def cmd_download(args):
    """Download de vídeo."""
    check_ytdlp()
    
    output_template = str(Path(args.output_dir) / "%(title)s.%(ext)s")
    cmd = ["yt-dlp", "-o", output_template]
    
    if args.format:
        cmd.extend(["-f", args.format])
    
    if args.audio_only:
        cmd.append("-x")
    
    cmd.append(args.url)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Download concluído → {args.output_dir}/")


def cmd_download_audio(args):
    """Download apenas áudio."""
    check_ytdlp()
    
    cmd = ["yt-dlp", "-x", "--audio-format", args.format or "mp3"]
    
    if args.output:
        cmd.extend(["-o", args.output])
    
    cmd.append(args.url)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Áudio descarregado → {args.output or 'diretório actual'}")


def cmd_info(args):
    """Ver informações do vídeo sem download."""
    check_ytdlp()
    
    cmd = ["yt-dlp", "--dump-json", args.url]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    
    # Parse JSON e mostrar info resumida
    import json
    try:
        info = json.loads(result.stdout)
        print(f"Título: {info.get('title', 'N/A')}")
        print(f"Duração: {info.get('duration', 0)}s")
        print(f"Uploader: {info.get('uploader', 'N/A')}")
        print(f"Views: {info.get('view_count', 0):,}")
        print(f"Data: {info.get('upload_date', 'N/A')}")
        print(f"URL: {info.get('webpage_url', args.url)}")
    except json.JSONDecodeError:
        print(result.stdout)


def main():
    parser = argparse.ArgumentParser(description="yt-dlp wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # download
    p_download = subparsers.add_parser("download", help="Download de vídeo")
    p_download.add_argument("url", help="URL do vídeo")
    p_download.add_argument("output_dir", help="Diretório de saída")
    p_download.add_argument("--format", "-f", help="Formato (ex: mp4, webm)")
    p_download.add_argument("--audio-only", "-x", action="store_true", help="Apenas áudio")
    
    # download-audio
    p_audio = subparsers.add_parser("download-audio", help="Download apenas áudio")
    p_audio.add_argument("url", help="URL do vídeo")
    p_audio.add_argument("--output", "-o", help="Ficheiro de saída")
    p_audio.add_argument("--format", default="mp3", help="Formato de áudio (default: mp3)")
    
    # info
    p_info = subparsers.add_parser("info", help="Ver informações do vídeo")
    p_info.add_argument("url", help="URL do vídeo")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "download": cmd_download,
        "download-audio": cmd_download_audio,
        "info": cmd_info,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
