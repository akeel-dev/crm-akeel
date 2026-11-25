# Estado — crm-akeel

Dono: Orquestrador. **Reescrito, não acrescido**, no portão de cada onda. Limite:
`limites.estado_linhas` do `time.yml`.

Atualizado: 2026-11-25 17:40 · **Onda 0 (fundação) fechada** · Próxima: Onda 1 (a fatiar) · Máquina: macOS (Darwin 25.6.0)

## Onde estamos

A fundação técnica está pronta. Três repositórios no GitHub (`akeel-dev`): o raiz `crm-akeel` (método,
spec v1.2, planejamento, ADRs, reviews, deploy) e os de produto `crm-akeel-backend` e
`crm-akeel-frontend`, aninhados e ignorados pelo raiz. Ainda **não há nenhum módulo de negócio**.

O que funciona (medido):
- **Login BFF** pelo Keycloak (realm `crm`; o real é da TI em akpannel), sessão no Postgres, nenhum token
  no navegador, recusa de domínio/não verificado, logout por `end_session` — provado em navegador (e2e).
- **Tela inicial** com a identidade provisória (paleta, cor de erro, Inter, pt-BR) e o design system base.
- **Plataforma do backend:** ids UUIDv7, jobs (db-scheduler) com modos `api`/`worker`/`migrate`, e-mail do
  sistema por fila, eventos de domínio pelo outbox (ADR 0002), arquivos por URL pré-assinada no Garage,
  contrato OpenAPI versionado e copiado para o frontend (`cmp`).
- **Arquitetura guardada por teste:** 16 testes (Modulith + 12 regras ArchUnit + configuração de storage).
- **Operação:** ambiente local com um comando, backup cifrado (falha fechado), homologação local pelo
  mesmo caminho do deploy, CI verde no GitHub, workflow de produção pronto e só manual.

## Última medição

| Comando | Resultado | Data | Máquina |
|---|---|---|---|
| `comandos.pre_requisito` | exit 0 | 2026-11-25 | macOS |
| `comandos.suite` (com `caffeinate -i`) | exit 0 — backend 177/177 (0 pulados, 8:48 min), frontend 239/239, `cmp` 0, portabilidade ok | 2026-11-25 17:30 | macOS |
| `comandos.arquitetura` | exit 0 — 16/0 | 2026-11-25 17:20 | macOS |
| e2e na homologação local | 8/8 | 2026-11-25 | macOS |

HEADs: backend `46e767a`, frontend `63752e9`; raiz ver `git log`.

## O que não existe ainda

- Todos os módulos de negócio da spec (§3.1): Onda 1 em diante.
- Deploy real na VPS: espera o Pedro (`decisoes §24`); condições em `§29`.
- Observabilidade (RNF-12).

## Pendências que bloqueiam

| Identificador | O que bloqueia | Quem decide |
|---|---|---|
| Início da Onda 1 | o fatiamento pelo Planejador | Pedro |
| Sessão de estudo 5 do Pipedrive + P-19 | USR (permissões) | Pedro |
| Demais sessões de estudo (§14.2) | módulos 🟡 | Pedro |
| P-07 | o prazo do projeto | Akeel |
| P-01 a P-06 | AUT, WPP, PRP, RPT, PRJ, MIG | Akeel |
