# VERDADE.md — Fonte da Verdade

**Versão:** 1.0 (Template)
**Objectivo:** Definir stack, estrutura e regras do projecto activo.

---

## 1. Identidade do Sistema

- **Nome:** Makan72
- **Tipo:** Orquestrador de Agentes AI
- **Path:** ~/.Makan72

## 2. Stack

(A preencher pelo utilizador após configuração)

## 3. Estrutura de Pastas

(Gerada automaticamente por setup.sh)

## 4. Regras

1. Fonte única de memória: 00-global/
2. Agentes registados via: `makan72 agent add`
3. Projectos registados via: `makan72 project add`
4. Nunca hardcoded credentials — usar .env
5. Nunca declarar funcional sem testar

## 5. Comandos Úteis

- `makan72 health` — verificar saúde do sistema
- `makan72 agent add` — adicionar agente
- `makan72 project add` — adicionar projecto
- `makan72 launch` — iniciar sessão Zellij
- `makan72 bot health` — health-check completo
