#!/usr/bin/env python3
"""tool_ai.py — Wrapper para ComfyUI + Stable Diffusion 1.5
Uso: python3 tool_ai.py <comando> [argumentos]
     python3 tool_ai.py --help
"""
import subprocess
import sys
import argparse
import json
import urllib.request
import urllib.error
import time
from pathlib import Path


# Diretório do ComfyUI
COMFYUI_DIR = Path.home() / ".Makan72" / "10-tools" / "comfyui"
MODELS_DIR = Path.home() / ".Makan72" / "10-tools" / "models"
SERVER_URL = "http://127.0.0.1:8188"


def check_comfyui():
    """Verificar se ComfyUI está instalado."""
    if not COMFYUI_DIR.exists():
        print("ERRO: ComfyUI não instalado. Correr: install-tools.sh fase3", file=sys.stderr)
        sys.exit(1)


def ensure_comfyui_running():
    """Verificar se ComfyUI está a correr, senão iniciar."""
    try:
        urllib.request.urlopen(f"{SERVER_URL}/system_stats", timeout=2)
        return True
    except Exception:
        # Iniciar servidor em background
        cmd = [
            "python3", str(COMFYUI_DIR / "main.py"),
            "--listen", "127.0.0.1",
            "--port", "8188"
        ]
        
        # Iniciar em background
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
        
        # Aguardar inicialização
        print("A iniciar ComfyUI...")
        for _ in range(30):
            time.sleep(1)
            try:
                urllib.request.urlopen(f"{SERVER_URL}/system_stats", timeout=2)
                print("ComfyUI pronto!")
                return True
            except Exception:
                continue
        
        print("ERRO: ComfyUI não iniciou em 30s", file=sys.stderr)
        return False


def get_default_txt2img_workflow(prompt, negative_prompt="", steps=20, width=512, height=512, seed=None):
    """Gerar workflow JSON padrão para txt2img."""
    import random
    if seed is None:
        seed = random.randint(0, 2**32 - 1)
    
    workflow = {
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "cfg": 8,
                "denoise": 1,
                "latent_image": ["5", 0],
                "model": ["4", 0],
                "negative": ["7", 0],
                "positive": ["6", 0],
                "sampler_name": "euler",
                "scheduler": "normal",
                "seed": seed,
                "steps": steps
            }
        },
        "4": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {
                "ckpt_name": "sd-v1-5.safetensors"
            }
        },
        "5": {
            "class_type": "EmptyLatentImage",
            "inputs": {
                "batch_size": 1,
                "height": height,
                "width": width
            }
        },
        "6": {
            "class_type": "CLIPTextEncode",
            "inputs": {
                "clip": ["4", 1],
                "text": prompt
            }
        },
        "7": {
            "class_type": "CLIPTextEncode",
            "inputs": {
                "clip": ["4", 1],
                "text": negative_prompt
            }
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {
                "samples": ["3", 0],
                "vae": ["4", 2]
            }
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {
                "filename_prefix": "ComfyUI",
                "images": ["8", 0]
            }
        }
    }
    
    return workflow


def get_img2img_workflow(prompt, input_image, negative_prompt="", steps=20, strength=0.7, width=512, height=512):
    """Gerar workflow JSON padrão para img2img."""
    import random
    seed = random.randint(0, 2**32 - 1)
    
    workflow = {
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "cfg": 8,
                "denoise": strength,
                "latent_image": ["5", 0],
                "model": ["4", 0],
                "negative": ["7", 0],
                "positive": ["6", 0],
                "sampler_name": "euler",
                "scheduler": "normal",
                "seed": seed,
                "steps": steps
            }
        },
        "4": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {
                "ckpt_name": "sd-v1-5.safetensors"
            }
        },
        "5": {
            "class_type": "VAEEncode",
            "inputs": {
                "pixels": ["10", 0],
                "vae": ["4", 2]
            }
        },
        "6": {
            "class_type": "CLIPTextEncode",
            "inputs": {
                "clip": ["4", 1],
                "text": prompt
            }
        },
        "7": {
            "class_type": "CLIPTextEncode",
            "inputs": {
                "clip": ["4", 1],
                "text": negative_prompt
            }
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {
                "samples": ["3", 0],
                "vae": ["4", 2]
            }
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {
                "filename_prefix": "ComfyUI",
                "images": ["8", 0]
            }
        },
        "10": {
            "class_type": "LoadImage",
            "inputs": {
                "image": Path(input_image).name
            }
        }
    }
    
    return workflow


def queue_prompt(workflow):
    """Enviar workflow para ComfyUI."""
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(f"{SERVER_URL}/prompt", data=data, headers={"Content-Type": "application/json"})
    
    try:
        response = urllib.request.urlopen(req)
        result = json.loads(response.read())
        return result["prompt_id"]
    except urllib.error.URLError as e:
        print(f"ERRO: Falha ao enviar workflow: {e}", file=sys.stderr)
        sys.exit(1)


def wait_for_prompt(prompt_id):
    """Aguardar conclusão do prompt."""
    while True:
        try:
            response = urllib.request.urlopen(f"{SERVER_URL}/history/{prompt_id}")
            history = json.loads(response.read())
            
            if prompt_id in history:
                return history[prompt_id]["outputs"]
        except Exception:
            pass
        
        time.sleep(1)


def cmd_generate(args):
    """Gerar imagem a partir de prompt de texto."""
    check_comfyui()
    
    if not ensure_comfyui_running():
        sys.exit(1)
    
    print(f"A gerar imagem: '{args.prompt}'...")
    
    workflow = get_default_txt2img_workflow(
        prompt=args.prompt,
        negative_prompt=args.negative or "",
        steps=args.steps,
        width=args.width,
        height=args.height,
        seed=args.seed
    )
    
    prompt_id = queue_prompt(workflow)
    outputs = wait_for_prompt(prompt_id)
    
    # Obter imagem gerada
    for node_id, node_output in outputs.items():
        if "images" in node_output:
            for image in node_output["images"]:
                if image.get("type") == "output":
                    # Download da imagem
                    image_url = f"{SERVER_URL}/view?filename={image['filename']}&subfolder={image['subfolder']}&type={image['type']}"
                    
                    output_path = args.output or "output.png"
                    urllib.request.urlretrieve(image_url, output_path)
                    print(f"OK: Imagem gerada → {output_path}")
                    return
    
    print("ERRO: Imagem não encontrada nos outputs", file=sys.stderr)
    sys.exit(1)


def cmd_img2img(args):
    """Gerar imagem a partir de outra imagem + prompt."""
    check_comfyui()
    
    if not ensure_comfyui_running():
        sys.exit(1)
    
    print(f"A processar img2img: '{args.prompt}'...")
    
    # Copiar imagem para input do ComfyUI
    input_dir = COMFYUI_DIR / "input"
    input_dir.mkdir(exist_ok=True)
    
    import shutil
    shutil.copy(args.input, input_dir / Path(args.input).name)
    
    workflow = get_img2img_workflow(
        prompt=args.prompt,
        input_image=args.input,
        negative_prompt=args.negative or "",
        steps=args.steps,
        strength=args.strength,
        width=args.width,
        height=args.height
    )
    
    prompt_id = queue_prompt(workflow)
    outputs = wait_for_prompt(prompt_id)
    
    # Obter imagem gerada
    for node_id, node_output in outputs.items():
        if "images" in node_output:
            for image in node_output["images"]:
                if image.get("type") == "output":
                    image_url = f"{SERVER_URL}/view?filename={image['filename']}&subfolder={image['subfolder']}&type={image['type']}"
                    
                    output_path = args.output or "output.png"
                    urllib.request.urlretrieve(image_url, output_path)
                    print(f"OK: Imagem gerada → {output_path}")
                    return
    
    print("ERRO: Imagem não encontrada nos outputs", file=sys.stderr)
    sys.exit(1)


def cmd_workflow(args):
    """Executar workflow ComfyUI via API."""
    check_comfyui()
    
    if not ensure_comfyui_running():
        sys.exit(1)
    
    print(f"A executar workflow: {args.workflow_file}...")
    
    with open(args.workflow_file, "r") as f:
        workflow = json.load(f)
    
    prompt_id = queue_prompt(workflow)
    outputs = wait_for_prompt(prompt_id)
    
    output_dir = args.output_dir or "."
    Path(output_dir).mkdir(exist_ok=True)
    
    # Guardar outputs
    for node_id, node_output in outputs.items():
        if "images" in node_output:
            for image in node_output["images"]:
                if image.get("type") == "output":
                    image_url = f"{SERVER_URL}/view?filename={image['filename']}&subfolder={image['subfolder']}&type={image['type']}"
                    
                    output_path = Path(output_dir) / f"node_{node_id}_{image['filename']}"
                    urllib.request.urlretrieve(image_url, output_path)
    
    print(f"OK: Workflow executado → {output_dir}/")


def main():
    parser = argparse.ArgumentParser(description="ComfyUI + Stable Diffusion wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # generate (txt2img)
    p_generate = subparsers.add_parser("generate", help="Gerar imagem a partir de prompt")
    p_generate.add_argument("prompt", help="Prompt de texto")
    p_generate.add_argument("output", nargs="?", help="Ficheiro de saída")
    p_generate.add_argument("--negative", help="Negative prompt")
    p_generate.add_argument("--steps", type=int, default=20, help="Steps (default: 20)")
    p_generate.add_argument("--width", type=int, default=512, help="Largura (default: 512)")
    p_generate.add_argument("--height", type=int, default=512, help="Altura (default: 512)")
    p_generate.add_argument("--seed", type=int, help="Seed (aleatório se não especificado)")
    
    # img2img
    p_img2img = subparsers.add_parser("img2img", help="Gerar imagem a partir de outra imagem")
    p_img2img.add_argument("input", help="Imagem de entrada")
    p_img2img.add_argument("prompt", help="Prompt de texto")
    p_img2img.add_argument("output", nargs="?", help="Ficheiro de saída")
    p_img2img.add_argument("--negative", help="Negative prompt")
    p_img2img.add_argument("--steps", type=int, default=20, help="Steps")
    p_img2img.add_argument("--strength", type=float, default=0.7, help="Strength (default: 0.7)")
    p_img2img.add_argument("--width", type=int, default=512, help="Largura")
    p_img2img.add_argument("--height", type=int, default=512, help="Altura")
    
    # workflow
    p_workflow = subparsers.add_parser("workflow", help="Executar workflow JSON")
    p_workflow.add_argument("workflow_file", help="Ficheiro workflow.json")
    p_workflow.add_argument("output_dir", help="Diretório de saída")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "generate": cmd_generate,
        "img2img": cmd_img2img,
        "workflow": cmd_workflow,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
