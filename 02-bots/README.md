# 02-bots/ — Automação Modular

**Propósito:** Bots que executam tarefas **AUTOMATICAMENTE** sem intervenção humana.
O principal é o `team-bot.sh` que organiza e mantém o sistema.

## Diferença entre 02-bots e 05-scripts

| 02-bots/ (AUTOMAÇÃO) | 05-scripts/ (FERRAMENTAS) |
|-----------------------|---------------------------|
| Executa SOZINHO | CEO ou agente EXECUTA |
| Programado/agendado | Manual ou por comando |
| Exemplo: limpeza automática | Exemplo: backup manual |

## Estrutura

```
02-bots/
├── README.md                    ← Este ficheiro
├── team-bot.sh                  ← Bot principal (orquestrador)
├── config/
│   └── BOT_RULES.yaml           ← Regras de protecção do bot
├── lib/                         ← Módulos do bot (9 módulos)
│   ├── inbox.sh                 ← Processar inbox
│   ├── heartbeat.sh             ← Monitorizar heartbeats
│   ├── handoff.sh               ← Processar handoffs
│   ├── cleanup.sh               ← Limpar ficheiros expirados
│   ├── sleep.sh                 ← Consolidação de memória
│   ├── notify.sh                ← Notificações
│   ├── guardrails.sh            ← Verificar limites
│   ├── critique.sh              ← Verificar CRITIQUE.md
│   └── visualizer.sh            ← Gerar diagramas
├── orchestrator/                ← Orquestrador de agentes (futuro)
│   ├── README.md
│   └── orchestrator.sh
└── tests/                       ← Testes do bot
    ├── README.md
    ├── test_integration.sh
    ├── test_inbox.sh
    ├── test_heartbeat.sh
    └── ...
```

## Comandos do team-bot.sh

```bash
# Operações core
team-bot.sh process-inbox      # Processar tarefas pendentes
team-bot.sh check-heartbeats   # Verificar agentes vivos
team-bot.sh process-handoffs   # Processar entregas entre agentes
team-bot.sh check-guardrails   # Verificar limites de acção

# Manutenção
team-bot.sh cleanup            # Limpar ficheiros expirados
team-bot.sh sleep              # Consolidação de memória (fim de sessão)
team-bot.sh notify             # Enviar notificações

# Validação
team-bot.sh validate           # Validação completa do sistema

# Info
team-bot.sh status             # Estado do bot e módulos
team-bot.sh modules            # Listar módulos carregados
team-bot.sh help               # Ajuda

# Daemon (opcional)
team-bot.sh daemon             # Modo automático (30s ciclo)
team-bot.sh daemon-stop        # Parar daemon
```

## Como criar um novo módulo

1. Criar ficheiro em `lib/{nome}.sh`
2. Seguir estrutura obrigatória (header, configuração, funções públicas)
3. Adicionar comando ao `team-bot.sh`
4. Criar teste em `tests/test_{nome}.sh`

## Regras para módulos

1. **Nenhum módulo pode quebrar outro** — módulos são independentes
2. **Falha graceful** — se um módulo falha, team-bot.sh continua com os outros
3. **Configuração em BOT_RULES.yaml** — cada módulo lê config do YAML, não hardcoded
4. **Logs obrigatórios** — cada módulo escreve em `08-logs/bot-{modulo}.log`
5. **Testes obrigatórios** — cada módulo tem `tests/test_{modulo}.sh`
