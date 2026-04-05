#!/usr/bin/env python3
"""tool_game.py — Wrapper para Pygame + Godot + Tiled
Uso: python3 tool_game.py <comando> [argumentos]
     python3 tool_game.py --help
"""
import subprocess
import sys
import argparse
import shutil
import os
from pathlib import Path


def cmd_pygame_run(args):
    """Executar jogo pygame."""
    try:
        import pygame
    except ImportError:
        print("ERRO: Pygame não instalado. pip install pygame", file=sys.stderr)
        sys.exit(1)
    
    cmd = ["python3", args.script]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Jogo executado → {args.script}")


def cmd_pygame_test(args):
    """Testar jogo sem display (headless)."""
    try:
        import pygame
    except ImportError:
        print("ERRO: Pygame não instalado. pip install pygame", file=sys.stderr)
        sys.exit(1)
    
    # Configurar ambiente headless
    env = os.environ.copy()
    env["SDL_VIDEODRIVER"] = "dummy"
    env["SDL_AUDIODRIVER"] = "dummy"
    
    # Script de teste que importa o jogo e verifica erros
    test_script = f"""
import sys
sys.path.insert(0, '{str(Path(args.script).parent)}')

# Tentar importar o script do jogo
try:
    exec(open('{args.script}').read())
    print("OK: Script valida sem erros")
except Exception as e:
    print(f"ERRO: {{e}}")
    sys.exit(1)
"""
    
    result = subprocess.run(
        ["python3", "-c", test_script],
        capture_output=True,
        text=True,
        env=env
    )
    
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Teste headless passed → {args.script}")


def cmd_godot_export(args):
    """Exportar projecto Godot."""
    # Procurar godot
    godot_bin = shutil.which("godot")
    if not godot_bin:
        # Tentar path comum
        godot_bin = str(Path.home() / ".local" / "bin" / "godot")
        if not Path(godot_bin).exists():
            print("ERRO: Godot não encontrado. Download: https://godotengine.org/download/linux/", file=sys.stderr)
            sys.exit(1)
    
    project_dir = Path(args.project_dir)
    project_file = project_dir / "project.godot"
    
    if not project_file.exists():
        print(f"ERRO: project.godot não encontrado em {args.project_dir}", file=sys.stderr)
        sys.exit(1)
    
    # Mapear plataforma para preset
    platform_map = {
        "linux": "Linux/X11",
        "windows": "Windows Desktop",
        "macos": "macOS",
        "web": "Web",
        "android": "Android"
    }
    
    preset = platform_map.get(args.platform, "Linux/X11")
    
    output_path = args.output or str(project_dir / "export" / f"game_{args.platform}")
    
    cmd = [
        godot_bin, "--path", str(project_dir),
        "--export-release", preset,
        output_path
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Projecto exportado → {output_path}")


def cmd_godot_run(args):
    """Executar cena Godot."""
    godot_bin = shutil.which("godot")
    if not godot_bin:
        godot_bin = str(Path.home() / ".local" / "bin" / "godot")
        if not Path(godot_bin).exists():
            print("ERRO: Godot não encontrado", file=sys.stderr)
            sys.exit(1)
    
    project_dir = Path(args.project_dir)
    
    cmd = [godot_bin, "--path", str(project_dir)]
    
    if args.scene:
        cmd.append(args.scene)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Cena executada → {args.scene or project_dir}")


def cmd_tiled_export(args):
    """Exportar mapa Tiled para JSON."""
    if not shutil.which("tiled"):
        print("ERRO: Tiled não encontrado. sudo apt install tiled", file=sys.stderr)
        sys.exit(1)
    
    # Tiled não tem CLI de export directa, usar Python
    try:
        import json
        # Tentar parse TMX manualmente
        import xml.etree.ElementTree as ET
        
        tree = ET.parse(args.tmx_file)
        root = tree.getroot()
        
        # Converter para estrutura JSON simples
        data = {
            "version": root.get("version", "1.0"),
            "width": int(root.get("width", 0)),
            "height": int(root.get("height", 0)),
            "tilewidth": int(root.get("tilewidth", 0)),
            "tileheight": int(root.get("tileheight", 0)),
            "layers": []
        }
        
        for layer in root.findall(".//layer"):
            layer_data = {
                "name": layer.get("name"),
                "width": int(layer.get("width", 0)),
                "height": int(layer.get("height", 0)),
            }
            data["layers"].append(layer_data)
        
        with open(args.output, "w") as f:
            json.dump(data, f, indent=2)
        
        print(f"OK: Mapa exportado → {args.output}")
        
    except Exception as e:
        print(f"ERRO: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Pygame + Godot + Tiled wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # run (Pygame)
    p_run = subparsers.add_parser("run", help="Executar jogo pygame")
    p_run.add_argument("script", help="Ficheiro .py do jogo")
    
    # test (Pygame headless)
    p_test = subparsers.add_parser("test", help="Testar jogo sem display")
    p_test.add_argument("script", help="Ficheiro .py do jogo")
    p_test.add_argument("--headless", action="store_true", help="Modo headless")
    
    # godot-export
    p_godot_export = subparsers.add_parser("godot-export", help="Exportar projecto Godot")
    p_godot_export.add_argument("project_dir", help="Diretório do projecto")
    p_godot_export.add_argument("--platform", choices=["linux", "windows", "macos", "web", "android"])
    p_godot_export.add_argument("--output", help="Ficheiro/caminho de saída")
    
    # godot-run
    p_godot_run = subparsers.add_parser("godot-run", help="Executar cena Godot")
    p_godot_run.add_argument("project_dir", help="Diretório do projecto")
    p_godot_run.add_argument("--scene", help="Cena específica (.tscn)")
    
    # tiled-export
    p_tiled = subparsers.add_parser("tiled-export", help="Exportar mapa Tiled para JSON")
    p_tiled.add_argument("tmx_file", help="Ficheiro .tmx")
    p_tiled.add_argument("output", help="Ficheiro JSON de saída")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "run": cmd_pygame_run,
        "test": cmd_pygame_test,
        "godot-export": cmd_godot_export,
        "godot-run": cmd_godot_run,
        "tiled-export": cmd_tiled_export,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
