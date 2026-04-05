#!/usr/bin/env python3
"""tool_animation.py — Wrapper para Manim
Uso: python3 tool_animation.py <comando> [argumentos]
     python3 tool_animation.py --help
"""
import subprocess
import sys
import argparse
import shutil
from pathlib import Path


def check_manim():
    """Verificar se Manim está instalado."""
    if not shutil.which("manim"):
        print("ERRO: Manim não encontrado. pip install manim", file=sys.stderr)
        sys.exit(1)


def cmd_render(args):
    """Renderizar cena Manim."""
    check_manim()
    
    quality_map = {
        "low": "-ql",
        "medium": "-qm",
        "high": "-qh",
        "4k": "-qk"
    }
    
    quality = quality_map.get(args.quality, "-qm")
    
    cmd = ["manim", quality, args.scene_file, args.class_name]
    
    if args.output_dir:
        cmd.extend(["--output_file", args.output_dir])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    
    # Output padrão do Manim vai para media/
    print(f"OK: Animação renderizada → media/")


def cmd_render_all(args):
    """Renderizar todas as cenas de um ficheiro."""
    check_manim()
    
    quality_map = {
        "low": "-ql",
        "medium": "-qm",
        "high": "-qh",
        "4k": "-qk"
    }
    
    quality = quality_map.get(args.quality, "-qm")
    
    cmd = ["manim", quality, args.scene_file, "--write-all"]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    
    print(f"OK: Todas as cenas renderizadas → media/")


def main():
    parser = argparse.ArgumentParser(description="Manim wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # render
    p_render = subparsers.add_parser("render", help="Renderizar cena Manim")
    p_render.add_argument("scene_file", help="Ficheiro .py com a cena")
    p_render.add_argument("class_name", help="Nome da classe Scene")
    p_render.add_argument("--quality", choices=["low", "medium", "high", "4k"], default="medium")
    p_render.add_argument("--output_dir", help="Diretório de saída")
    
    # render-all
    p_render_all = subparsers.add_parser("render-all", help="Renderizar todas as cenas")
    p_render_all.add_argument("scene_file", help="Ficheiro .py com as cenas")
    p_render_all.add_argument("--quality", choices=["low", "medium", "high", "4k"], default="medium")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "render": cmd_render,
        "render-all": cmd_render_all,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
