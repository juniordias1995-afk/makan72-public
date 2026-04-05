#!/usr/bin/env python3
"""tool_3d.py — Wrapper para Blender + Open3D
Uso: python3 tool_3d.py <comando> [argumentos]
     python3 tool_3d.py --help
"""
import subprocess
import sys
import argparse
import shutil
from pathlib import Path


def check_blender():
    """Verificar se Blender está instalado."""
    if not shutil.which("blender"):
        print("ERRO: Blender não encontrado. Instale: sudo apt install blender", file=sys.stderr)
        sys.exit(1)


def cmd_render(args):
    """Renderizar cena .blend para imagem."""
    check_blender()
    
    cmd = [
        "blender", "--background", args.blend_file,
        "--render-output", args.output,
        "--render-frame", "1",
    ]
    
    if args.engine:
        cmd.extend(["--engine", args.engine])
    
    if args.samples:
        script = f"import bpy; bpy.context.scene.cycles.samples = {args.samples}"
        cmd.extend(["--python-expr", script])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Renderizado → {args.output}")


def cmd_render_animation(args):
    """Renderizar animação .blend para frames ou vídeo."""
    check_blender()
    
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)
    
    format_map = {"PNG": "PNG", "JPEG": "JPEG", "OPEN_EXR": "OPEN_EXR", "MP4": "FFMPEG"}
    output_format = args.format or "PNG"
    
    cmd = [
        "blender", "--background", args.blend_file,
        "--render-output", str(Path(args.output_dir) / "frame_####"),
        "--engine", args.engine or "CYCLES",
        "-a",  # Render animation
    ]
    
    if args.fps:
        script = f"import bpy; bpy.context.scene.render.fps = {args.fps}"
        cmd.extend(["--python-expr", script])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Animação renderizada → {args.output_dir}/")


def cmd_run_script(args):
    """Executar script Python no Blender headless."""
    check_blender()
    
    cmd = ["blender", "--background", args.blend_file, "--python", args.script]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Script executado → {args.script}")


def cmd_export(args):
    """Exportar cena para outro formato."""
    check_blender()
    
    format_map = {
        "GLTF": "gltf", "GLB": "glb",
        "FBX": "fbx", "OBJ": "obj",
        "STL": "stl", "DAE": "dae"
    }
    
    export_format = args.format.upper() if args.format else "GLTF"
    
    # Script Python para exportar
    export_script = f"""
import bpy
bpy.ops.export_scene.{format_map.get(export_format, 'gltf')}(filepath='{args.output}', export_format='{export_format}')
"""
    
    cmd = ["blender", "--background", args.blend_file, "--python-expr", export_script]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Exportado → {args.output}")


def cmd_open3d_view(args):
    """Visualizar mesh/point cloud (render para imagem)."""
    try:
        import open3d as o3d
    except ImportError:
        print("ERRO: Open3D não instalado. pip install open3d", file=sys.stderr)
        sys.exit(1)
    
    # Carregar ficheiro
    ext = Path(args.input).suffix.lower()
    if ext in [".ply", ".pcd"]:
        geometry = o3d.io.read_point_cloud(args.input)
    elif ext in [".obj", ".stl", ".ply"]:
        geometry = o3d.io.read_triangle_mesh(args.input)
    else:
        print(f"ERRO: Formato não suportado: {ext}", file=sys.stderr)
        sys.exit(1)
    
    # Renderizar para imagem
    vis = o3d.visualization.Visualizer()
    vis.create_window(visible=False)
    vis.add_geometry(geometry)
    vis.poll_events()
    vis.update_renderer()
    vis.capture_screen_image(args.output)
    vis.destroy_window()
    
    print(f"OK: Renderizado → {args.output}")


def cmd_open3d_convert(args):
    """Converter formatos 3D."""
    try:
        import open3d as o3d
    except ImportError:
        print("ERRO: Open3D não instalado. pip install open3d", file=sys.stderr)
        sys.exit(1)
    
    # Carregar
    ext_input = Path(args.input).suffix.lower()
    if ext_input in [".ply", ".pcd"]:
        geometry = o3d.io.read_point_cloud(args.input)
    elif ext_input in [".obj", ".stl", ".ply"]:
        geometry = o3d.io.read_triangle_mesh(args.input)
    else:
        print(f"ERRO: Formato de entrada não suportado: {ext_input}", file=sys.stderr)
        sys.exit(1)
    
    # Guardar
    ext_output = Path(args.output).suffix.lower()
    if ext_output == ".ply":
        o3d.io.write_point_cloud(args.output, geometry)
    elif ext_output in [".obj", ".stl"]:
        o3d.io.write_triangle_mesh(args.output, geometry)
    else:
        print(f"ERRO: Formato de saída não suportado: {ext_output}", file=sys.stderr)
        sys.exit(1)
    
    print(f"OK: Convertido → {args.output}")


def main():
    parser = argparse.ArgumentParser(description="Blender + Open3D wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # render (Blender)
    p_render = subparsers.add_parser("render", help="Renderizar cena .blend para imagem")
    p_render.add_argument("blend_file", help="Ficheiro .blend")
    p_render.add_argument("output", help="Ficheiro de saída")
    p_render.add_argument("--engine", choices=["CYCLES", "BLENDER_EEVEE"], help="Motor de render")
    p_render.add_argument("--samples", type=int, help="Samples (Cycles)")
    
    # render-animation (Blender)
    p_anim = subparsers.add_parser("render-animation", help="Renderizar animação")
    p_anim.add_argument("blend_file", help="Ficheiro .blend")
    p_anim.add_argument("output_dir", help="Diretório de saída")
    p_anim.add_argument("--format", choices=["PNG", "JPEG", "OPEN_EXR", "MP4"], help="Formato")
    p_anim.add_argument("--fps", type=int, default=24, help="FPS (default: 24)")
    p_anim.add_argument("--engine", help="Motor de render")
    
    # run-script (Blender)
    p_script = subparsers.add_parser("run-script", help="Executar script Python no Blender")
    p_script.add_argument("blend_file", help="Ficheiro .blend")
    p_script.add_argument("script", help="Ficheiro .py")
    
    # export (Blender)
    p_export = subparsers.add_parser("export", help="Exportar cena para outro formato")
    p_export.add_argument("blend_file", help="Ficheiro .blend")
    p_export.add_argument("output", help="Ficheiro de saída")
    p_export.add_argument("--format", choices=["GLTF", "GLB", "FBX", "OBJ", "STL"], help="Formato")
    
    # open3d-view
    p_o3d_view = subparsers.add_parser("open3d-view", help="Visualizar mesh/point cloud")
    p_o3d_view.add_argument("input", help="Ficheiro de entrada (.ply, .obj, .stl, .pcd)")
    p_o3d_view.add_argument("output", help="Ficheiro de saída (imagem)")
    
    # open3d-convert
    p_o3d_conv = subparsers.add_parser("open3d-convert", help="Converter formatos 3D")
    p_o3d_conv.add_argument("input", help="Ficheiro de entrada")
    p_o3d_conv.add_argument("output", help="Ficheiro de saída")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "render": cmd_render,
        "render-animation": cmd_render_animation,
        "run-script": cmd_run_script,
        "export": cmd_export,
        "open3d-view": cmd_open3d_view,
        "open3d-convert": cmd_open3d_convert,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
