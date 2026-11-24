# Story 0-19 — sabotagens contra o código real (evidência, rigor completo)

Transcrito pelo Orquestrador do relatório do QA (2026-11-24), clone do frontend em `ec25124`.
Procedência: ✅ execução. Verde depois de restaurar em todas (exit 0).

| # | Sabotagem | Resultado |
|---|---|---|
| 1 | Tirar `X-XSRF-TOKEN` de `client.ts` | exit 1, 7 falhas (`expected null to be '4b1d…'`) |
| 2 | Gravar a sessão no `localStorage` | exit 1, 1 falha (fluxo sem token) |
| 3 | Login por `fetch` em vez de `window.location.assign` | exit 1, 9 falhas |
| 4 | Sair por `fetch` com `preventDefault` | exit 1, 4 falhas |
| 5 | `localStorage.setItem` em `src/planted.ts` | exit 1 (`src/ itself has no storage error`) |
| 6 | `'/realms/crm'` em `src/planted.ts` | exit 1 |
| 7 | Borda de erro com `var(--color-danger)` | exit 1 |
| 8 | Mensagem de erro com `var(--color-danger)` | exit 1 |
| 9 | Par `danger-ink on bg-dark` em COLOR_PAIRS | exit 1 (par "Nunca") |
| 10 | Par `danger on offwhite` em COLOR_PAIRS | exit 1 (par "Nunca") |
| 11 | `#b42318` → `#c42318` | exit 1, 3 falhas (contraste 5.3026 vs 5.98) |
| 12 | `#f97066` → `#f97067` | exit 1, 1 falha |
| a | Rota lembrada aceitando `//` | **exit 0 — não pega**: virou o teste do commit `a826164` |
| b | CSRF lido uma vez no carregamento | exit 1, 6 falhas |

O teste de `a826164`, contra `ec25124`, falhou nas variantes `/\evil.example` e `/%5Cevil.example`
(a SPA ia a `/evil.example`, na mesma origem; o Revisor mediu que não saía da origem). Corrigido
em `9d37f99`: 239/239.
