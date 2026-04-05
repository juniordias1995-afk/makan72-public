# VACINAS.md — Erros Conhecidos

**Objectivo:** Prevenir recorrência de erros.

---

## #001 — Validação Física
**Problema:** Reportar sucesso sem verificar ficheiros
**Prevenção:** Executar `ls` após cada criação

## #002 — Improviso Arquitectural
**Problema:** Criar soluções fora da arquitectura oficial
**Prevenção:** Ler VERDADE.md antes de implementar

## #003 — Path Hardcoded
**Problema:** Caminhos absolutos nos scripts
**Prevenção:** Usar `$HOME/.Makan72` ou `$MAKAN72_HOME`

## #004 — Declarar Funcional Sem Testar
**Problema:** Agente declara "100% funcional" sem executar testes
**Prevenção:** Testar realmente antes de declarar

---

## REGRAS DE OURO

1. **Path Único:** `~/.Makan72/` — nenhum outro
2. **Validação Física:** `ls` após cada criação
3. **1 Fonte Verdade:** cada info existe em 1 lugar apenas
4. **Limpeza:** testes apagados após uso
