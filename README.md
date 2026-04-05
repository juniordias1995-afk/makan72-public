# Makan72

**Sistema de Orquestração de Agentes AI**

Coordena múltiplos agentes de IA (Claude, Gemini, Qwen, DeepSeek, etc.) numa equipa organizada com comunicação, memória partilhada e automação.

---

## O que faz

- **Multi-agente:** Vários modelos AI a trabalhar em equipa, cada um com o seu papel
- **Comunicação:** Sistema de inbox, handoff e dispatch entre agentes via Zellij
- **Memória:** Fonte única de verdade — os agentes lembram contexto entre sessões
- **Automação:** Bots, health-checks, backups, integridade de ficheiros
- **CLI:** Comando `makan72` para gerir agentes, projectos e sessões
- **Portável:** Funciona em Linux, macOS, Fedora, Arch, Debian

## Arquitectura

```
~/.Makan72/
├── 00-global/       # Memória central (verdade, vacinas, CVs)
├── 01-config/       # Configuração (agentes, projectos, prompts)
├── 02-bots/         # Automação (team-bot, orchestrator, testes)
├── 03-inbox/        # Comunicação entre agentes
├── 04-bus/          # Heartbeat, status, handoff em tempo real
├── 05-scripts/      # Scripts operacionais (gate, retry, health)
├── 06-reports/      # Relatórios gerados
├── 07-archive/      # Arquivo histórico
├── 08-logs/         # Logs e cache
├── 09-workspace/    # Área de trabalho activa
└── 10-tools/        # Ferramentas MCP e wrappers
```

## Stack

| Componente | Tecnologia |
|------------|------------|
| Scripts | Bash 4+ |
| Configs | JSON + YAML |
| Memória | Markdown |
| Terminal | Zellij (multi-tab) |
| Sandbox | Docker (opcional) |

## Requisitos

- Bash 4+
- jq
- Python 3.10+ (opcional)
- Zellij (opcional, para multi-tab)
- Pelo menos 1 agente AI CLI instalado

## Instalação

Distribuição **por convite**. Para obter acesso, contactar o autor.

---

**Licença Proprietária** — © 2026 Marcilei Pedro Dias Junior. Todos os direitos reservados.  
Proibido copiar, distribuir ou vender sem autorização escrita do autor.
