# 02-bots/tests/ — Testes do Bot

## Como Correr Testes

```bash
cd ~/.Makan72/02-bots
bash tests/test_integration.sh
```

## Testes Disponíveis

| Teste | Descrição |
|-------|-----------|
| `test_integration.sh` | Teste completo do sistema |
| `test_inbox.sh` | Teste do módulo inbox |
| `test_heartbeat.sh` | Teste do módulo heartbeat |
| `test_handoff.sh` | Teste do módulo handoff |
| `test_cleanup.sh` | Teste do módulo cleanup |
| `test_sleep.sh` | Teste do módulo sleep |
| `test_notify.sh` | Teste do módulo notify |
| `test_guardrails.sh` | Teste do módulo guardrails |
| `test_critique.sh` | Teste do módulo critique |
| `test_visualizer.sh` | Teste do módulo visualizer |

## Estrutura

```
tests/
├── README.md
├── test_integration.sh    ← Teste completo
├── test_*.sh              ← Testes por módulo
└── fixtures/
    └── mock_agents.json   ← Dados mock para testes
```

## Critérios de Passagem

- Todos os testes devem retornar exit code 0
- Output deve mostrar "PASS" para cada teste
- Cobertura mínima: 80% das funções públicas
