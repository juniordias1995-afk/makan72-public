#!/usr/bin/env python3
"""tool_audio.py — Wrapper para FFmpeg Audio + Whisper + Coqui TTS + Bark
Uso: python3 tool_audio.py <comando> [argumentos]
     python3 tool_audio.py --help
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
    """Converter formato de áudio."""
    check_ffmpeg()
    cmd = ["ffmpeg", "-i", args.input, "-y"]
    
    if args.bitrate:
        cmd.extend(["-b:a", args.bitrate])
    
    cmd.append(args.output)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Áudio convertido → {args.output}")


def cmd_cut(args):
    """Cortar segmento de áudio."""
    check_ffmpeg()
    cmd = ["ffmpeg", "-i", args.input, "-ss", args.start, "-to", args.end, "-c", "copy", "-y", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Áudio cortado → {args.output} ({args.start} - {args.end})")


def cmd_mix(args):
    """Misturar duas faixas de áudio."""
    check_ffmpeg()
    
    # Criar ficheiro de lista para concat
    list_file = Path("/tmp/ffmpeg_mix_list.txt")
    
    # Usar amix para mixar
    cmd = [
        "ffmpeg", "-i", args.track1, "-i", args.track2,
        "-filter_complex", "amix=inputs=2:duration=first:dropout_transition=3",
        "-y", args.output
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Áudio mixado → {args.output}")


def cmd_extract(args):
    """Extrair áudio de vídeo."""
    check_ffmpeg()
    cmd = ["ffmpeg", "-i", args.video, "-vn", "-acodec", "copy", "-y", args.output]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERRO: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: Áudio extraído → {args.output}")


def cmd_transcribe(args):
    """Transcrever áudio para texto (Whisper)."""
    try:
        import whisper
    except ImportError:
        print("ERRO: whisper não instalado. pip install openai-whisper", file=sys.stderr)
        sys.exit(1)
    
    model_name = args.model or "medium"
    print(f"A carregar modelo {model_name}...")
    model = whisper.load_model(model_name)
    
    print(f"A transcrever {args.input}...")
    result = model.transcribe(args.input, language=args.language)
    
    # Guardar transcrição
    output_file = args.output or args.input + ".txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(result["text"])
    
    print(f"OK: Transcrição guardada → {output_file}")


def cmd_subtitles(args):
    """Gerar ficheiro de legendas SRT."""
    try:
        import whisper
    except ImportError:
        print("ERRO: whisper não instalado. pip install openai-whisper", file=sys.stderr)
        sys.exit(1)
    
    model_name = args.model or "medium"
    print(f"A carregar modelo {model_name}...")
    model = whisper.load_model(model_name)
    
    print(f"A gerar legendas para {args.input}...")
    result = model.transcribe(args.input, task="transcribe")
    
    # Gerar SRT
    output_file = args.output or args.input.replace(".mp4", ".srt").replace(".mkv", ".srt")
    
    with open(output_file, "w", encoding="utf-8") as f:
        for i, segment in enumerate(result["segments"], 1):
            start = format_timestamp(segment["start"])
            end = format_timestamp(segment["end"])
            text = segment["text"].strip()
            f.write(f"{i}\n{start} --> {end}\n{text}\n\n")
    
    print(f"OK: Legendas guardadas → {output_file}")


def format_timestamp(seconds):
    """Formatar segundos para SRT timestamp."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"


def cmd_speak(args):
    """Gerar áudio a partir de texto (Coqui TTS)."""
    try:
        from TTS.api import TTS
    except ImportError:
        print("ERRO: Coqui TTS não instalado. pip install TTS", file=sys.stderr)
        sys.exit(1)
    
    language = args.language or "pt"
    
    # Detectar modelos disponíveis
    print("A carregar TTS...")
    tts = TTS(model_name=f"tts_models/{language}/tacotron2-DDC", progress_bar=False)
    
    tts.tts_to_file(text=args.text, output_path=args.output)
    
    print(f"OK: Áudio gerado → {args.output}")


def cmd_speak_file(args):
    """Gerar áudio a partir de ficheiro de texto."""
    try:
        from TTS.api import TTS
    except ImportError:
        print("ERRO: Coqui TTS não instalado. pip install TTS", file=sys.stderr)
        sys.exit(1)
    
    with open(args.text_file, "r", encoding="utf-8") as f:
        text = f.read()
    
    language = args.language or "pt"
    print("A carregar TTS...")
    tts = TTS(model_name=f"tts_models/{language}/tacotron2-DDC", progress_bar=False)
    
    tts.tts_to_file(text=text, output_path=args.output)
    
    print(f"OK: Áudio gerado → {args.output}")


def cmd_bark_generate(args):
    """Gerar áudio com Bark (voz expressiva)."""
    try:
        from bark import SAMPLE_RATE, generate_audio, preload_models
    except ImportError:
        print("ERRO: Bark não instalado. pip install git+https://github.com/suno-ai/bark.git", file=sys.stderr)
        sys.exit(1)
    
    from scipy.io.wavfile import write as write_wav
    
    print("A carregar modelos Bark...")
    preload_models()
    
    print(f"A gerar áudio: {args.text}...")
    audio_array = generate_audio(args.text, history_prompt=args.history_prompt if hasattr(args, 'history_prompt') else None)
    
    write_wav(args.output, SAMPLE_RATE, audio_array)
    
    print(f"OK: Áudio gerado → {args.output}")


def main():
    parser = argparse.ArgumentParser(description="FFmpeg Audio + Whisper + TTS wrapper")
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")
    
    # convert (FFmpeg)
    p_convert = subparsers.add_parser("convert", help="Converter formato de áudio")
    p_convert.add_argument("input", help="Ficheiro de entrada")
    p_convert.add_argument("output", help="Ficheiro de saída")
    p_convert.add_argument("--bitrate", help="Bitrate (ex: 192k)")
    
    # cut (FFmpeg)
    p_cut = subparsers.add_parser("cut", help="Cortar segmento de áudio")
    p_cut.add_argument("input", help="Ficheiro de entrada")
    p_cut.add_argument("output", help="Ficheiro de saída")
    p_cut.add_argument("--start", required=True, help="Tempo inicial (ex: 00:00:30)")
    p_cut.add_argument("--end", required=True, help="Tempo final (ex: 00:01:00)")
    
    # mix (FFmpeg)
    p_mix = subparsers.add_parser("mix", help="Misturar duas faixas de áudio")
    p_mix.add_argument("track1", help="Primeira faixa")
    p_mix.add_argument("track2", help="Segunda faixa")
    p_mix.add_argument("output", help="Ficheiro de saída")
    
    # extract (FFmpeg)
    p_extract = subparsers.add_parser("extract", help="Extrair áudio de vídeo")
    p_extract.add_argument("video", help="Ficheiro de vídeo")
    p_extract.add_argument("output", help="Ficheiro de saída")
    
    # transcribe (Whisper)
    p_transcribe = subparsers.add_parser("transcribe", help="Transcrever áudio para texto")
    p_transcribe.add_argument("input", help="Ficheiro de áudio")
    p_transcribe.add_argument("--output", help="Ficheiro de saída (default: input.txt)")
    p_transcribe.add_argument("--model", choices=["tiny", "base", "small", "medium", "large"], help="Modelo Whisper")
    p_transcribe.add_argument("--language", help="Código da língua (ex: pt, en)")
    
    # subtitles (Whisper)
    p_subtitles = subparsers.add_parser("subtitles", help="Gerar legendas SRT")
    p_subtitles.add_argument("input", help="Ficheiro de vídeo/áudio")
    p_subtitles.add_argument("--output", help="Ficheiro SRT de saída")
    p_subtitles.add_argument("--model", choices=["tiny", "base", "small", "medium", "large"], help="Modelo Whisper")
    
    # speak (Coqui TTS)
    p_speak = subparsers.add_parser("speak", help="Gerar áudio a partir de texto")
    p_speak.add_argument("text", help="Texto para sintetizar")
    p_speak.add_argument("output", help="Ficheiro de saída")
    p_speak.add_argument("--language", default="pt", help="Língua (default: pt)")
    
    # speak-file (Coqui TTS)
    p_speak_file = subparsers.add_parser("speak-file", help="Gerar áudio a partir de ficheiro")
    p_speak_file.add_argument("text_file", help="Ficheiro de texto")
    p_speak_file.add_argument("output", help="Ficheiro de saída")
    p_speak_file.add_argument("--language", default="pt", help="Língua (default: pt)")
    
    # bark-generate
    p_bark = subparsers.add_parser("bark-generate", help="Gerar áudio com Bark")
    p_bark.add_argument("text", help="Texto para sintetizar")
    p_bark.add_argument("output", help="Ficheiro de saída")
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    commands = {
        "convert": cmd_convert,
        "cut": cmd_cut,
        "mix": cmd_mix,
        "extract": cmd_extract,
        "transcribe": cmd_transcribe,
        "subtitles": cmd_subtitles,
        "speak": cmd_speak,
        "speak-file": cmd_speak_file,
        "bark-generate": cmd_bark_generate,
    }
    
    commands[args.command](args)


if __name__ == "__main__":
    main()
