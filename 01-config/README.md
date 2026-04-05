---
versao: "1.0"
data_criacao: "2026-03-03"
criado_por: "Makan72"
ultima_actualizacao: "2026-03-14"
actualizado_por: "QWEN"
---

# 01-config/ — Configuração Técnica

**Propósito:** COMO o sistema funciona. Configuração técnica, não memória.

## Diferença entre 00-global e 01-config

| 00-global/ (MEMÓRIA) | 01-config/ (CONFIGURAÇÃO) |
|-----------------------|---------------------------|
| O que o sistema SABE | Como o sistema FUNCIONA |
| Agentes lêem antes de trabalhar | Scripts lêem para executar |
| Muda quando se aprende algo | Muda quando se configura algo |

## Conteúdo

| Ficheiro | Descrição |
|----------|-----------|
| team.yaml | Config do SISTEMA (nome, versão, regras gerais) |
| agents.json | FONTE ÚNICA de agentes activos |
| GUARDRAILS.yaml | Limites de acção por tarefa |
| prompts/ | Prompts dos agentes (populado por manage-agents.sh) |
| templates/ | Templates para novos agentes |
| docker/ | Configuração Docker (opcional) |

## Regra Fundamental

**agents.json** é a ÚNICA fonte de verdade sobre agentes.
Todos os scripts, bots e pastas lêem DAQUI. NUNCA duplicar.
