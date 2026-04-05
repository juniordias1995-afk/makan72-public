#!/usr/bin/env python3
"""tool_image.py — Wrapper para ImageMagick + rembg + GIMP
Uso: python3 tool_image.py <comando> [argumentos]
     python3 tool_image.py --help
"""
import subprocess
import sys
import argparse
import shutil
from pathlib import Path


def check_imagemagick():
    """Verificar se ImageMagick está instalado."""
    if not shutil.which("convert"):
        print("ERRO: ImageMagick (convert) não encontrado. Instale: sudo apt install imagemagick", file=sys.stderr)
        sys.exit(1)


def cmd_convert(args):
    """Converter formato de imagem."""
    check_imagemagick()
    cmd = ["convert", args.input, args.output]
    
    if args.quality:
        cmd.extend(["-quality", args.quality])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Imagem convertida → {args.output}")


def cmd_resize(args):
    """Redimensionar imagem."""
    check_imagemagick()
    
    if args.width and args.height:
        geometry = f"{args.width}x{args.height}!"
    elif args.width:
        geometry = f"{args.width}x"
    elif args.height:
        geometry = f"x{args.height}"
    else:
        print("ERRO: Especificar --width ou --height", file=sys.stderr)
        sys.exit(1)
    
    cmd = ["convert", args.input, "-resize", geometry, args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Imagem redimensionada → {args.output}")


def cmd_compose(args):
    """Sobrepor imagens (compositing)."""
    check_imagemagick()
    
    position = args.position or "0,0"
    cmd = ["convert", args.base, args.overlay, "-geometry", f"+{position.replace(',', '+')}", "-composite", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Imagens compostas → {args.output}")


def cmd_text(args):
    """Adicionar texto a imagem."""
    check_imagemagick()
    
    font_size = args.size or "48"
    color = args.color or "white"
    gravity = args.gravity or "south"
    
    cmd = [
        "convert", args.input,
        "-gravity", gravity,
        "-pointsize", font_size,
        "-fill", color,
        "-annotate", "+0+10", args.text,
        args.output
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Texto adicionado → {args.output}")


def cmd_sprite_sheet(args):
    """Criar sprite sheet a partir de frames."""
    check_imagemagick()
    
    columns = args.columns or "8"
    cmd = ["convert", str(Path(args.frames_dir) / "*.png"), "+append", "-roll", f"+0+0", args.output]
    
    # Abordagem alternativa com montage
    cmd = ["montage", str(Path(args.frames_dir) / "*.png"), "-tile", f"{columns}x", "-geometry", "+0+0", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Sprite sheet criada → {args.output}")


def cmd_remove_bg(args):
    """Remover fundo de imagem (usa rembg)."""
    # Tentar import directo primeiro (mais fiável)
    try:
        from rembg import remove
        from PIL import Image
        
        img = Image.open(args.input)
        output = remove(img)
        output.save(args.output)
        print(f"OK: Fundo removido → {args.output}")
        return
    except ImportError:
        # Fallback para CLI
        if not shutil.which("rembg"):
            print("ERRO: rembg não instalado. pip install rembg", file=sys.stderr)
            sys.exit(1)
        
        cmd = ["rembg", "i", args.input, args.output]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ERRO: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        print(f"OK: Fundo removido → {args.output}")


def cmd_gimp_batch(args):
    """Executar Script-Fu batch no GIMP."""
    if not shutil.which("gimp"):
        print("ERRO: GIMP não encontrado. Instale: sudo apt install gimp", file=sys.stderr)
        sys.exit(1)
    
    cmd = ["gimp", "-i", "-b", f'(load "{args.script}")', "-b", "(gimp-quit 0)"]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Script GIMP executado → {args.script}")


def main():
    parser = argparse.ArgumentParser(description="ImageMagick + rembg wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # convert
    p_convert = subparsers.add_parser("convert", help="Converter formato de imagem")
    p_convert.add_argument("input", help="Ficheiro de entrada")
    p_convert.add_argument("output", help="Ficheiro de saída")
    p_convert.add_argument("--quality", help="Qualidade (ex: 85)")
    
    # resize
    p_resize = subparsers.add_parser("resize", help="Redimensionar imagem")
    p_resize.add_argument("input", help="Ficheiro de entrada")
    p_resize.add_argument("output", help="Ficheiro de saída")
    p_resize.add_argument("--width", type=int, help="Largura")
    p_resize.add_argument("--height", type=int, help="Altura")
    
    # compose
    p_compose = subparsers.add_parser("compose", help="Sobrepor imagens")
    p_compose.add_argument("base", help="Imagem base")
    p_compose.add_argument("overlay", help="Imagem para sobrepor")
    p_compose.add_argument("output", help="Ficheiro de saída")
    p_compose.add_argument("--position", help="Posição X,Y (default: 0,0)")
    
    # text
    p_text = subparsers.add_parser("text", help="Adicionar texto a imagem")
    p_text.add_argument("input", help="Ficheiro de entrada")
    p_text.add_argument("output", help="Ficheiro de saída")
    p_text.add_argument("--text", required=True, help="Texto a adicionar")
    p_text.add_argument("--size", default="48", help="Tamanho da fonte")
    p_text.add_argument("--color", default="white", help="Cor do texto")
    p_text.add_argument("--gravity", default="south", help="Posição (north, south, east, west, center)")
    
    # sprite-sheet
    p_sprite = subparsers.add_parser("sprite-sheet", help="Criar sprite sheet")
    p_sprite.add_argument("frames_dir", help="Diretório com frames")
    p_sprite.add_argument("output", help="Ficheiro de saída")
    p_sprite.add_argument("--columns", type=int, default=8, help="Colunas (default: 8)")
    
    # remove-bg
    p_bg = subparsers.add_parser("remove-bg", help="Remover fundo de imagem")
    p_bg.add_argument("input", help="Ficheiro de entrada")
    p_bg.add_argument("output", help="Ficheiro de saída")
    
    # gimp-batch
    p_gimp = subparsers.add_parser("gimp-batch", help="Executar Script-Fu batch")
    p_gimp.add_argument("script", help="Ficheiro .scm")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "convert": cmd_convert,
        "resize": cmd_resize,
        "compose": cmd_compose,
        "text": cmd_text,
        "sprite-sheet": cmd_sprite_sheet,
        "remove-bg": cmd_remove_bg,
        "gimp-batch": cmd_gimp_batch,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
