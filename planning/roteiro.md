# Roteiro até o objetivo — crm-akeel

Dono: Orquestrador. O mapa do que falta, na ordem, com o dono de cada passo. É
apresentado ao humano em toda sessão fria, resumido.

**Objetivo:** a Akeel larga o Pipedrive. Os módulos **Must** da spec (§3.1)
funcionando em produção, e a migração ensaiada duas vezes antes da virada (spec
§3.2). O prazo depende da P-07.

| # | Passo | Dono | Depende de | Estado |
|---|---|---|---|---|
| 1 | Plugins instalados e `.claude/settings.json` gravado | humano | — | feito em 24/11 |
| 2 | ADR 0001: a stack, os comandos e os caminhos | arquiteto | 1 | aceito em 24/11 |
| 3 | `time.yml` com `comandos`, `escrita.qa` e `escrita.dev` | humano | 2 | feito em 24/11 (Orquestrador, autorizado) |
| 4 | Onda 0: fundação (spec §4: CI/CD, Keycloak, outbox e jobs, design system, backups, e-mail do sistema), teste de arquitetura e diagrama de módulos | planejador → time | 3 | em andamento: 16/20 em 25/11 (ver `ESTADO.md`) |
| 5 | Ondas do núcleo de vendas, em ordem de dependência: IAM → USR, PIP → DEA → ACT, BRD, TRS (os ✅ primeiro) | time | 4 | pendente |
| 6 | Sessões de estudo do Pipedrive (spec §14.2), em paralelo desde já, para destravar os módulos 🟡 | humano (método RES) | — | pendente |
| 7 | Pendências da Akeel (spec §14.1, P-01 a P-17); as 🔴 travam MIG, PRP, RPT, AUT, WPP e PRJ | humano com a Akeel | — | pendente |
| 8 | Módulos 🟡 e 🔴 conforme as pendências fecham | time | 6, 7 | pendente |
| 9 | Migração: dois ensaios completos (RF-MIG-04) | time + humano | 8, P-06 | pendente |
| 10 | Virada para produção | humano | 9, P-07 | pendente |
