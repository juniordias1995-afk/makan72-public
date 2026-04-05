#!/usr/bin/env python3
"""tool_video.py — Wrapper para FFmpeg Video
Uso: python3 tool_video.py <comando> [argumentos]
     python3 tool_video.py --help
"""
import subprocess
import sys
import argparse
import shutil
from pathlib import Path


def check_ffmpeg():
    """Verificar se ffmpeg está instalado."""
    if not shutil.which("ffmpeg"):
        print("ERRO: ffmpeg não encontrado. Instale: sudo apt install ffmpeg", file=sys.stderr)
        sys.exit(1)


def cmd_convert(args):
    """Converter formato de vídeo."""
    check_ffmpeg()
    cmd = ["ffmpeg", "-i", args.input, "-y"]
    
    if args.quality:
        crf_map = {"high": "18", "medium": "23", "low": "28"}
        crf = crf_map.get(args.quality, "23")
        cmd.extend(["-crf", crf])
    
    cmd.append(args.output)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Vídeo convertido → {args.output}")


def cmd_cut(args):
    """Cortar segmento de vídeo."""
    check_ffmpeg()
    cmd = ["ffmpeg", "-i", args.input, "-ss", args.start, "-to", args.end, "-c", "copy", "-y", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Vídeo cortado → {args.output} ({args.start} - {args.end})")


def cmd_concat(args):
    """Juntar múltiplos vídeos."""
    check_ffmpeg()
    
    # Criar ficheiro de lista temporário
    list_file = Path("/tmp/ffmpeg_concat_list.txt")
    with open(list_file, "w") as f:
        for video in args.videos:
            f.write(f"file '{video}'\n")
    
    cmd = ["ffmpeg", "-f", "concat", "-safe", "0", "-i", str(list_file), "-c", "copy", "-y", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    list_file.unlink(missing_ok=True)
    
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Vídeos juntados → {args.output}")


def cmd_extract_frames(args):
    """Extrair frames como imagens."""
    check_ffmpeg()
    
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)
    
    fps = args.fps or "1"
    output_pattern = str(Path(args.output_dir) / "frame_%04d.png")
    
    cmd = ["ffmpeg", "-i", args.input, "-vf", f"fps={fps}", "-y", output_pattern]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Frames extraídos → {args.output_dir}/")


def cmd_add_audio(args):
    """Adicionar faixa de áudio a vídeo."""
    check_ffmpeg()
    cmd = ["ffmpeg", "-i", args.video, "-i", args.audio, "-c:v", "copy", "-c:a", "aac", "-y", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Áudio adicionado → {args.output}")


def cmd_resize(args):
    """Redimensionar vídeo."""
    check_ffmpeg()
    
    scale_filter = ""
    if args.width and args.height:
        scale_filter = f"scale={args.width}:{args.height}"
    elif args.width:
        scale_filter = f"scale={args.width}:-1"
    elif args.height:
        scale_filter = f"scale=-1:{args.height}"
    else:
        print("ERRO: Especificar --width ou --height", file=sys.stderr)
        sys.exit(1)
    
    cmd = ["ffmpeg", "-i", args.input, "-vf", scale_filter, "-y", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Vídeo redimensionado → {args.output}")


def main():
    parser = argparse.ArgumentParser(description="FFmpeg Video wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # convert
    p_convert = subparsers.add_parser("convert", help="Converter formato de vídeo")
    p_convert.add_argument("input", help="Ficheiro de entrada")
    p_convert.add_argument("output", help="Ficheiro de saída")
    p_convert.add_argument("--quality", choices=["high", "medium", "low"], default="medium", help="Qualidade")
    
    # cut
    p_cut = subparsers.add_parser("cut", help="Cortar segmento de vídeo")
    p_cut.add_argument("input", help="Ficheiro de entrada")
    p_cut.add_argument("output", help="Ficheiro de saída")
    p_cut.add_argument("--start", required=True, help="Tempo inicial (ex: 00:01:00)")
    p_cut.add_argument("--end", required=True, help="Tempo final (ex: 00:02:30)")
    
    # concat
    p_concat = subparsers.add_parser("concat", help="Juntar múltiplos vídeos")
    p_concat.add_argument("output", help="Ficheiro de saída")
    p_concat.add_argument("videos", nargs="+", help="Vídeos para juntar")
    
    # extract-frames
    p_extract = subparsers.add_parser("extract-frames", help="Extrair frames como imagens")
    p_extract.add_argument("input", help="Ficheiro de entrada")
    p_extract.add_argument("output_dir", help="Diretório de saída")
    p_extract.add_argument("--fps", default="1", help="Frames por segundo (default: 1)")
    
    # add-audio
    p_audio = subparsers.add_parser("add-audio", help="Adicionar faixa de áudio a vídeo")
    p_audio.add_argument("video", help="Ficheiro de vídeo")
    p_audio.add_argument("audio", help="Ficheiro de áudio")
    p_audio.add_argument("output", help="Ficheiro de saída")
    
    # resize
    p_resize = subparsers.add_parser("resize", help="Redimensionar vídeo")
    p_resize.add_argument("input", help="Ficheiro de entrada")
    p_resize.add_argument("output", help="Ficheiro de saída")
    p_resize.add_argument("--width", type=int, help="Largura")
    p_resize.add_argument("--height", type=int, help="Altura")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "convert": cmd_convert,
        "cut": cmd_cut,
        "concat": cmd_concat,
        "extract-frames": cmd_extract_frames,
        "add-audio": cmd_add_audio,
        "resize": cmd_resize,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
