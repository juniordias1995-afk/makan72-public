---
versao: "1.0"
data_criacao: "2026-03-03"
criado_por: "Makan72"
ultima_actualizacao: "2026-03-14"
actualizado_por: "QWEN"
---

# 05-scripts/ — Ferramentas

**Propósito:** Scripts que o CEO ou agentes executam **MANUALMENTE**.
Diferente dos bots (02-bots/) que executam automaticamente.

## Diferença entre 02-bots e 05-scripts

| 02-bots/ (AUTOMAÇÃO) | 05-scripts/ (FERRAMENTAS) |
|-----------------------|---------------------------|
| Executa SOZINHO | CEO ou agente EXECUTA |
| Programado/agendado | Manual ou por comando |
| Exemplo: limpeza automática | Exemplo: backup manual |

## Estrutura

```
05-scripts/
├── README.md                    ← Este ficheiro
├── core/                        ← Scripts ESSENCIAIS
│   ├── manage-agents.sh         ← Gerir agentes (add/remove/list)
│   ├── run-agent.sh             ← Lançar agente com memória
│   ├── gate.sh                  ← Validação de qualidade
│   └── shield.sh                ← Escudo de segurança
├── utils/                       ← Scripts ÚTEIS
│   ├── start-session.sh         ← Iniciar sessão
│   ├── health-check.sh          ← Verificar saúde
│   ├── backup.sh                ← Backup manual
│   ├── restore.sh               ← Restaurar backup
│   ├── cleanup-bus.sh           ← Limpar bus
│   ├── show-status.sh           ← Mostrar status
│   └── checkpoint.sh            ← Time-travel snapshots
└── migration/                   ← Scripts de MIGRAÇÃO
    ├── migrate-from-team.sh     ← Migrar de ~/.team/
    └── verify-migration.sh      ← Verificar migração
```

## Comandos Essenciais

```bash
# Gerir agentes
./05-scripts/core/manage-agents.sh list
./05-scripts/core/manage-agents.sh add CLAUDE "Claude Opus 4.6" claude

# Lançar agente
./05-scripts/core/run-agent.sh CLAUDE

# Validação
./05-scripts/core/gate.sh full ficheiro.py

# Saúde do sistema
./05-scripts/utils/health-check.sh

# Backup
./05-scripts/utils/backup.sh --desc "pre-migration"
```
