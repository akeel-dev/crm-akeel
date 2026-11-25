# Estado — crm-akeel

Dono: Orquestrador. **Reescrito, não acrescido**, a cada fechamento de sessão ou portão. Limite:
`limites.estado_linhas` do `time.yml`.

Atualizado: 2026-11-25 11:15 · Onda: **0 (fundação), 16/20 stories fechadas + 0-11 aprovada (falta conferir a regra `65c7928`)** · Máquina: macOS (Darwin 25.6.0)

## Onde estamos

A fundação técnica está quase pronta. Existe código nos dois repositórios de produto, ignorados
pelo raiz: `backend/` (github.com/akeel-dev/crm-akeel-backend) e `frontend/`
(github.com/akeel-dev/crm-akeel-frontend). O raiz (github.com/akeel-dev/crm-akeel) guarda método,
spec, planejamento, ADRs, reviews e deploy.

O que funciona hoje (medido):
- **Login BFF** pelo Keycloak (realm `crm` local no compose; o real é da TI em akpannel), sessão no
  Postgres, nenhum token no navegador, recusa de domínio/não verificado, logout por `end_session`.
  Provado num navegador real (e2e Playwright, 160/160).
- **Tela inicial** com a identidade provisória (paleta, Inter, cor de erro, pt-BR) e o design system base.
- **Jobs** (db-scheduler) com novas tentativas; modos `api`/`worker`/`migrate` validados.
- **E-mail do sistema** por fila, 5 novas tentativas, relay configurável (nunca o real nos testes).
- **Backup** cifrado (pgBackRest + rclone), destino trocável por configuração, falha fechado.
- **Ambiente local** com um comando (`deploy/local/`), **CI verde** no GitHub nos dois repositórios.

## Última medição

| Comando | Resultado | Data | Máquina |
|---|---|---|---|
| `comandos.pre_requisito` | exit 0 | 2026-11-25 | macOS |
| `comandos.suite` | **exit 0** — backend 132/132 (3:31 min), frontend 239/239, `cmp` do contrato 0, portabilidade do backup ok | 2026-11-25 11:12 | macOS |
| e2e (`cd frontend && npm run e2e`, fora da suite) | 160/160 em `--repeat-each=20` (QA) | 2026-11-25 | macOS |

HEADs: raiz ver `git log`; backend `c07d095`; frontend `63752e9`.

## O que não existe ainda

- Onda 0: **0-12** (eventos api→worker, ADR 0002), **0-13** (arquivos no Garage), **0-04**
  (homologação local: deploy como código + e2e) e o **portão** da onda.
- Nenhum módulo de negócio (Onda 1 em diante: IAM/USR, PIP, DEA, ACT, BRD, TRS…).
- Deploy real na VPS: **espera o Pedro** e não bloqueia nada (`decisoes §24`).

## Pendências que bloqueiam

| Identificador | O que bloqueia | Quem decide |
|---|---|---|
| UUID v4 na 0-11 (`reviews/0-11.md` N2) | a 0-12 (a spec §6.1 pede v7) | nada a decidir: corrigir para v7 na 0-11 (`decisoes §27`) |
| P-07 (spec) | o prazo do projeto | Akeel |
| P-01 a P-06 (spec) | AUT, WPP, PRP, RPT, PRJ, MIG | Akeel |
| Sessões de estudo do Pipedrive | módulos 🟡 | Pedro |
