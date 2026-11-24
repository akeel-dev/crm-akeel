# Conflito — story 0-01: `git check-ignore -q` com dois caminhos

Aberto por: Orquestrador, 2026-11-24, a partir do relato do DevOps.

**O quê:** o "Como verificar" e o critério 2 da story 0-01 usam `git check-ignore -q backend frontend`.
O git recusa: `fatal: --quiet is only valid with a single pathname` (exit 128).

**Evidência:** remedido pelo Orquestrador no `main` em 2026-11-24 14:42, com
`git check-ignore -q backend && git check-ignore -q frontend`: o bloco sai com 0; `pre_requisito` com 0.

**Correção proposta:**
- Planejador: trocar o comando na story 0-01 (critério 2 e "Como verificar") por dois `check-ignore -q`.
- DevOps: aplicar a mesma troca em `docs/operacao/repositorios.md`, seção "Como conferir".

**Bloqueia?** Não: é um defeito do comando de verificação, não da entrega.

**Resolvido em 2026-11-24:** story corrigida pelo Planejador; documento corrigido pelo DevOps (`0759a7f`). Exit 0 remedido.
