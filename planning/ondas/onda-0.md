# Onda 0 — A fundação técnica existe, roda localmente de ponta a ponta e está guardada por teste

Dono: Planejador. Data: 2026-11-24. Spec lida: `especificacao-crm-akeel-v1.1.md` (v1.1),
§0, §2, §3.1, §3.2, §4, §5.1, §5.2, §5.7, §6.1, §6.3 (`company`, `app_user`), §6.4, §9.5,
§9.17, §9.20, §10.1, §10.4, §11, §12, §13, §14.1. Também: `docs/adr/0001-stack.md`
(revisão 2, aceito em `decisoes/2026-11-24.md §10`), `docs/adr/0002-eventos-api-worker.md`
e `docs/adr/0003-sessao-bff.md` (aceitos em `decisoes/2026-11-24.md §11`),
`decisoes/2026-11-24.md §5–§11`, `decisoes/2026-11-24-paleta.md`, `time.yml` de 2026-11-24.

## Objetivo

No fim da onda existe, e não existia antes:

- os dois repositórios de produto (`backend/`, `frontend/`) e o ambiente local em Docker
  Compose (PostgreSQL, Keycloak com realm `sed` de teste, Garage, Mailpit);
- um backend Java 25 / Spring Boot 4 que roda nos modos `api`, `worker` e `migrate`, com
  jobs persistidos (db-scheduler), eventos de domínio na mesma transação entregues pelo
  `worker`, e-mail só por fila, arquivos por S3 só via `platform.storage`, e login BFF;
- uma SPA com formatos brasileiros, componentes base acessíveis sobre tokens, cliente gerado
  do contrato OpenAPI e a casca autenticada;
- o teste de arquitetura (`ModularityTest`, `ArchitectureTest`, `StorageConfigTest`) e os
  guardas do ADR 0001 (`verificar-portabilidade.sh`, `cmp` do contrato);
- backup cifrado e restaurável, com destino só por `BACKUP_S3_*`;
- CI em cada repositório de produto e o deploy no raiz, **todos verificáveis localmente**,
  sem depender de remoto no GitHub nem da VPS;
- um teste ponta a ponta em que uma pessoa da Akeel (fictícia) entra pelo Keycloak local e
  vê o seu nome.

Nenhum módulo de negócio (§4.3) nasce nesta onda. O IAM de negócio (convite, vínculo,
desativação: RF-IAM-01 a 05) é da Onda 1.

## Stories

| Id | Story | Repositório | Papéis | Requisitos da spec | Rigor | Depende de |
|---|---|---|---|---|---|---|
| 0-01 | Os dois repositórios de produto existem e o raiz os ignora | raiz + back + front | devops | D-03, D-04; ADR dec. 2 | leve | — |
| 0-02 | Ambiente local inteiro com um comando | raiz | devops | §4.5 Local, D-05, D-06, D-07, §5.1, RF-NOT-09, RF-SEC-03 | leve (realm exercido por 0-09/0-20) | 0-01 |
| 0-03 | Backup cifrado, restaurável, sem provedor fixo | raiz | devops | §4.6, RNF-07, RNF-14, P-17 (mecanismo) | leve + gêmeo por presença | 0-02 |
| 0-04 | Homologação local pelo mesmo caminho do deploy | raiz | devops | §4.5 passos 4–5, RNF-13, RF-SEC-03 | leve | 0-03, 0-07, 0-10, 0-15, 0-20 |
| 0-05 | Backend compila em Java 25, sobe e migra contra PostgreSQL real | back | qa, dev | D-03, D-05, §4.2, §12 | leve | 0-01 |
| 0-06 | Fronteiras da arquitetura viram teste | back + raiz (docs) | arquiteto | D-03, §4.1, §4.2, §4.3, §12 | leve + gêmeo por presença | 0-05 |
| 0-07 | CI do backend e imagem | back | devops | §4.5 passos 1–3, RNF-09, RF-SEC-03 | leve | 0-06 |
| 0-08 | Contrato OpenAPI versionado no backend | back | qa, dev | §4.2 Contrato, §12, §13.2 | leve | 0-07 |
| 0-09 | Login BFF pelo Keycloak; o navegador só recebe cookie; sessão no PostgreSQL | back | qa, dev | D-07, §5.1, RF-SEC-03, RNF-13; ADR 0003 | **completo (IAM)** | 0-08 |
| 0-10 | Modos api / worker / migrate e jobs persistidos | back | qa, dev | §4.1, §4.2 Jobs, §4.5 passo 5, RNF-13 | leve | 0-06 |
| 0-11 | E-mail do sistema só por fila, com novas tentativas | back | qa, arquiteto, dev | D-10, §10.4, RF-NOT-05 (parcial), 07, 08, 09 | leve | 0-10 |
| 0-12 | Evento na `outbox_event` na mesma transação; só o worker repassa e entrega | back | arquiteto, qa, dev | §0.4.3, §4.1, §4.4, §10.1 (formato); ADR 0002 | leve | 0-10 |
| 0-13 | Arquivos por URL pré-assinada, qualquer S3 por configuração | back | qa, dev | §4.2 Arquivos, RNF-14, RF-SEC-03 | leve | 0-06 |
| 0-14 | Frontend sobe, testa e constrói; rotas, cache, i18n pt-BR | front | qa, dev | D-04, §4.2, RF-UI-03 (idioma) | leve | 0-01 |
| 0-15 | CI do frontend e imagem estática | front | devops | §4.5 passos 1–3, RNF-09 | leve | 0-14 |
| 0-16 | Datas, horas e dinheiro no formato brasileiro e no fuso do usuário | front | qa, dev | RF-UI-03, RF-UI-04, §6.1, §12, D-02 | leve | 0-14 |
| 0-17 | Componentes base acessíveis sobre tokens; cores da paleta do Pedro, tipografia e logo provisórios | front | qa, dev | §4.2 Componentes, RF-UI-07, 08, 09, RNF-10, D-22; P-12 (cores) | leve | 0-16 |
| 0-18 | Cliente TS gerado do contrato, igual ao do backend | front | qa, dev | §4.2 Contrato, §12, §13.2 | leve | 0-17; entre repos: 0-09 |
| 0-19 | SPA leva ao login, mostra quem entrou, nunca toca em token | front | qa, dev | D-07, §5.1, RF-UI-03, RF-UI-07 | **completo (IAM)** | 0-18 |
| 0-20 | Ponta a ponta: login no Keycloak local e o nome na tela | front | qa, dev | D-07, §5.1, §12 e2e, RNF-11 (parcial) | **completo (IAM)** | 0-19; entre repos: 0-09, 0-02 |

**Ciclo por papel.** Stories com `qa` seguem QA → Dev → Revisor. Stories só de `devops`
(0-01, 0-02, 0-03, 0-04, 0-07, 0-15) seguem DevOps → Revisor, com a verificação pelo
comando da story. 0-06 é do Arquiteto, que faz o papel do QA (o teste de arquitetura é dele).

**A `comandos.suite` durante a onda.** Ela só fica executável inteira quando existem
`frontend/openapi/openapi.json` (0-18) e `deploy/backup/verificar-portabilidade.sh` (0-03).
Antes disso, cada story verifica com `suite_backend` ou `suite_frontend`; a falha do `cmp`
ou do script ausente é "inexecutável", não vermelho.

## Tabela de colisão

**Regra (`decisoes/2026-11-24.md §10`):** paralelo só **entre** repositórios; **em série
dentro** de cada repositório. O raiz é um terceiro repositório com a mesma regra. Por isso
há três trilhas, e as stories de uma trilha nunca rodam juntas, mesmo quando os arquivos
não se cruzam. 0-01 toca os três repositórios e roda sozinha.

| Trilha | Ordem (em série) |
|---|---|
| **R (raiz)** | 0-01 → 0-02 → 0-03 → … → 0-04 (a última da onda) |
| **B (backend)** | 0-05 → 0-06 → 0-07 → 0-08 → **0-09** → 0-10 → 0-11 → **0-12** → 0-13 |
| **F (frontend)** | 0-14 → 0-15 → 0-16 → 0-17 → 0-18 → 0-19 → 0-20 |

Rodadas sugeridas (na mesma linha, podem rodar juntas):

| Rodada | Trilha R | Trilha B | Trilha F | Observação |
|---|---|---|---|---|
| 1 | 0-01 | — | — | sozinha: cria os três `.gitignore` e os dois repositórios |
| 2 | 0-02 | 0-05 | 0-14 | |
| 3 | — | 0-06 | 0-15 | 0-06 também commita no raiz (`SISTEMA.md`, `docs/`): por isso a trilha R fica parada nesta rodada |
| 4 | 0-03 | 0-07 | 0-16 | |
| 5 | — | 0-08 | 0-17 | |
| 6 | — | 0-09 | — | F espera 0-09 (0-18 precisa de `GET /api/session` no contrato) |
| 7 | — | 0-10 | 0-18 | |
| 8 | — | 0-11 | 0-19 | 0-11 tem Arquiteto e QA juntos (arquivos diferentes, mesma story) |
| 9 | — | 0-12 | 0-20 | 0-12 tem Arquiteto e QA juntos (arquivos diferentes, mesma story); 0-20 usa o compose de 0-02 e o backend de 0-09; não escreve neles |
| 10 | — | 0-13 | — | |
| 11 | 0-04 | — | — | depende das imagens (0-07, 0-15), do modo `migrate` (0-10) e do e2e (0-20) |

**Se 0-09 ou 0-12 atrasarem:** Q-ARQ-1 e Q-ARQ-2 já estão respondidas (ADRs 0002 e
0003), então nada as bloqueia por decisão. Se uma delas emperrar na execução, dentro da
trilha B 0-10, 0-11 e 0-13 não dependem de 0-09 nem de 0-12 e podem subir na ordem; a
série continua sendo uma story por vez. Se 0-09 atrasar, a trilha F para em 0-17 (0-18
espera o contrato com a sessão).

**Arquivos que mais de uma story toca (sempre na mesma trilha, nunca juntas):**
`backend/pom.xml` e `backend/src/main/resources/db/migration/**` (0-05, 0-08 a 0-13);
`backend/openapi/openapi.json` (0-08, 0-09); `ArchitectureTest` (0-06, 0-11, 0-12: as duas
regras do ADR 0002); `compose.yaml` (0-02, 0-03, 0-04); `.gitignore` do raiz (0-01,
0-02); `frontend/package.json` e `frontend/src/**` (0-14, 0-16 a 0-20);
`frontend/eslint.config.js` (0-14, 0-16, 0-17, 0-19).

## Cobertura

### A. A fundação da spec (§3.2, observação 1)

| Item da spec | Story | Ou: fora desta onda, porque |
|---|---|---|
| CI/CD | 0-07, 0-15 (CI), 0-04 (deploy, local) | execução real no GitHub e na VPS: pendências "remoto" e "VPS" |
| Keycloak | 0-02, 0-09, 0-19, 0-20 | realm real `sed`: P-15 |
| Outbox | 0-12 (ADR 0002) | purga das tabelas: *depois, se* pesarem |
| Jobs | 0-10 | — |
| Design system | 0-17 (estrutura, tokens, componentes base, cores da paleta do Pedro) | tipografia, logotipo, nome e o hex de `bg-dark`: P-12 |
| Backups | 0-03 (mecanismo, local) | destino real: P-17; alerta de falha: observabilidade, fora |
| Envio de e-mail | 0-11 | verificação de dentro do `worker` na VPS: pendência "VPS" |

### B. Pipeline de CI/CD (§4.5)

| Passo | Story | Ou: fora |
|---|---|---|
| 1. Build e testes (unitário, Testcontainers, arquitetura) | 0-07, 0-15 | — |
| 2. Análise estática e de dependências | 0-07 (OWASP DC ou equivalente), 0-15 (`npm audit`) | chave da NVD, se faltar: pendência |
| 3. Build das imagens | 0-07, 0-15 | publicar num registro: depende do remoto |
| 4. Homologação + e2e | 0-04 (homologação **local**), 0-20 | homologação na VPS: pendência "VPS" |
| 5. Produção com aprovação manual, Flyway como etapa própria | 0-04 (workflow + script), 0-10 (modo `migrate`) | execução real: pendências "remoto" e "VPS" |

### C. Backups (§4.6)

| Linha | Story | Ou: fora |
|---|---|---|
| PostgreSQL (completo diário + WAL, fora da VPS) | 0-03 | o "fora da VPS, no Brasil" real: P-17 |
| Arquivos (S3), replicação diária | 0-03 | idem |
| Keycloak no mesmo esquema | 0-02 (banco no PostgreSQL), 0-03 | Keycloak de produção pode não ser nosso: P-15 |
| RPO ≤ 15 min · RTO ≤ 4 h | 0-03 (WAL contínuo; restauração local medida) | medição na VPS: pendência "VPS" |
| Teste de restauração mensal documentado | 0-03 (roteiro em `docs/operacao/backup.md`) | a execução mensal começa com produção |
| Retenção 35 + 12 | 0-03 | conflito com titulares: P-08 |

### D. Autenticação (§5.1)

| Item | Story | Ou: fora |
|---|---|---|
| Cliente confidencial no realm `sed` | 0-02 (realm de teste), 0-09 | realm real: P-15 |
| BFF, Authorization Code + PKCE | 0-09, 0-20 | — |
| Tokens só no servidor | 0-09, 0-19, 0-20 | — |
| Cookie `HttpOnly`, `Secure`, `SameSite=Lax` | 0-09, 0-20 | — |
| CSRF em toda escrita | 0-09, 0-19 | — |
| Nenhum token no `localStorage` | 0-19, 0-20 | — |
| Login com Google restrito a `akeel.com.br` | — | provedor Google no realm: P-15 |
| Backend confere de novo o domínio | 0-09, 0-19, 0-20 | — |
| MFA obrigatório para administradores | — | depende do realm real (P-15), de `is_admin` (Onda 1) e de P-09 |
| Sessão 8 h inativa / 30 dias absoluta | 0-09 (absoluta pelo `CREATION_TIME` do banco) | — |
| Sessão sobrevive à troca de instância (RNF-13) | 0-09 (ADR 0003, critério 8) | cifra dos tokens em repouso: sem cifra na v1 (`decisoes/2026-11-24.md §11`), gatilhos no ADR 0003 |

### E. Ciclo de vida do usuário (§5.2)

| Item | Story | Ou: fora |
|---|---|---|
| RF-IAM-01 a RF-IAM-05 | — | Onda 1 (módulo IAM). **Risco:** até lá, qualquer `@akeel.com.br` verificado no realm entra; nenhuma homologação com o realm real antes da Onda 1 |

### F. Requisitos de segurança (§5.7)

| Item | Story | Ou: fora |
|---|---|---|
| RF-SEC-01 (ASVS nível 2) | — | critério transversal; checklist antes da produção |
| RF-SEC-02 (cabeçalhos) | — | Onda 1, junto com o IAM |
| RF-SEC-03 (segredos fora do repositório) | 0-01, 0-02, 0-03, 0-04, 0-07, 0-09, 0-13, 0-15 | — |
| RF-SEC-04 (tokens de terceiros cifrados) | — | WPP |
| RF-SEC-05 (log de segurança) | — | TRS |
| RF-SEC-06 (saída 587 só para quem envia) | — | exige a VPS: pendência |
| RF-SEC-07 (pentest) | — | antes da produção |

### G. E-mail do sistema (§10.4 e RF-NOT)

| Item | Story | Ou: fora |
|---|---|---|
| RF-NOT-01 a 04, RF-NOT-06 | — | módulo NOT |
| RF-NOT-05 | 0-11 (fila, novas tentativas, HTML + texto, identidade) | link para a preferência: módulo NOT |
| RF-NOT-07 | 0-11 | — |
| RF-NOT-08 | 0-11 | — |
| RF-NOT-09 | 0-02, 0-11 | — |
| Configuração Jakarta Mail da §10.4 | 0-11 | — |
| Verificar envio de dentro do `worker` e IPv6 | 0-11 (o comando existe) | rodar na VPS: pendência |

### H. Interface transversal (§9.20)

| Item | Story | Ou: fora |
|---|---|---|
| RF-UI-03 | 0-14 (idioma), 0-16 (formatos) | — |
| RF-UI-04 | 0-16 | origem do fuso (`app_user.time_zone`): Onda 1 |
| RF-UI-05 (tempo real) | — | SSE + `LISTEN/NOTIFY` entram com a primeira tela que os pede |
| RF-UI-06 (responsivo) | — | entra com as telas |
| RF-UI-07 | 0-17, 0-19 | — |
| RF-UI-08 | 0-17 | — |
| RF-UI-09 | 0-17 | — |

### I. Guardas do ADR 0001 ("Guardado por")

| Linha | Story |
|---|---|
| Monólito modular (`ModularityTest`) | 0-06 |
| Sem cron nem thread solta | 0-06 |
| db-scheduler isolado | 0-06 (regra), 0-10 (uso) |
| S3 isolado | 0-06 (regra), 0-13 (uso) |
| Nenhum provedor de S3 no código (`StorageConfigTest`) | 0-06 |
| `platform.storage` contra um S3 que não é o de produção | 0-13 |
| jOOQ como acesso principal | 0-06 |
| Contrato OpenAPI igual nos dois repositórios | 0-08, 0-18, 0-04 |
| Backup sem acoplamento | 0-03 |
| D-22 (aviso de copyright) | Revisor, em 0-14 e 0-17 |
| Java 25 / Spring Boot 4 (enforcer) | 0-05 |
| PostgreSQL 17+ | 0-05 (e 0-02 no compose) |

### J. Estratégia de testes (§12)

| Nível | Story | Ou: fora |
|---|---|---|
| Unitário | 0-16, 0-17 | — |
| Integração (PostgreSQL real, migrações, outbox, jobs) | 0-05, 0-10, 0-11, 0-12, 0-13 | — |
| Arquitetura | 0-06 | — |
| Paridade de visibilidade | — | USR |
| Contrato | 0-08, 0-18 | — |
| Ponta a ponta | 0-20 | FL-001 a FL-004: núcleo |
| Paridade de comportamento (T-001 a T-046) | — | nenhuma regra do Apêndice A é desta onda |
| Carga, Segurança (ZAP), Migração | — | sem tela, sem homologação na VPS, sem MIG |

### K. Stack (§4.2), linhas que esta onda não usa

| Linha | Fora, porque |
|---|---|
| Tempo real (SSE + `LISTEN/NOTIFY`) | nenhuma tela desta onda muda por ação de outro usuário |
| PDF (Gotenberg) | primeiro uso em PRP; fora até do compose (Ponytail, 0-02) |
| Observabilidade (Micrometer, OpenTelemetry, logs JSON, Sentry; RNF-12) | **não está na lista da §3.2**; candidata à Onda 1. O alerta de falha de backup e de fila parada depende dela |
| Resource Server (API pública) | módulo API |
| dnd-kit, react-hook-form + zod | entram com o primeiro quadro e o primeiro formulário |
| Geração de código do jOOQ | Ponytail: `DSLContext` sem geração até a primeira tabela de negócio (0-05) |

## Pendências que esta onda não resolve

| Identificador | O que bloqueia | Quem decide |
|---|---|---|
| **`bg-dark` sem hex** (aberta pelo Planejador, 2026-11-24) | **Não bloqueia 0-17.** A paleta (`decisoes/2026-11-24-paleta.md`) cita `bg-dark` nos usos de `accent` (9.69:1) e de `accent-ink` (2.47:1, proibido) sem dar o valor. 0-17 não cria o token nem inventa hex; as duas conferências de contraste que dependem dele esperam o valor. Bloqueia a primeira tela com superfície escura principal | humano (Pedro) / Akeel (design) |
| P-15 (realm `sed` compartilhado) | realm real, login com Google, MFA, limite de tentativas; a onda usa realm **de teste local** | Akeel (TI) |
| P-12 (identidade visual), **o que resta** | tipografia, logotipo, nome do produto e o hex de `bg-dark` (as cores da paleta já entram em 0-17) | Akeel (design) |
| P-17 (destino do backup, dados no Brasil) | backup real fora da VPS | time técnico + TI |
| P-09 (relay e MFA) | segurança do relay; MFA para todos | Akeel (admin do Workspace) |
| P-08 (retenção x backup) | política de retenção final | Akeel (jurídico) |
| P-07 (fim do Pipedrive) | prazo; se apertar, o ADR prevê a saída "disco local" no lugar do Garage | Akeel (financeiro) |
| Remoto do raiz no GitHub (e de `backend`/`frontend`) | rodar de verdade os workflows de 0-04, 0-07, 0-15; publicar imagens. `decisoes §10` não diz quem cria nem o nome | humano |
| Acesso à VPS (homologação e produção), Cloudflare Tunnel e Access, segredos | deploy real; verificar o relay de dentro do `worker` (§10.4) e a saída 587 só para ele (RF-SEC-06); agendar o backup e o alerta | humano + Akeel (TI) |
| Chave da NVD (se o Dependency-Check exigir) | passo 2 do CI do backend completo localmente | humano |

### Respondidas (2026-11-24)

| Identificador | Pergunta | Resposta | Story ajustada |
|---|---|---|---|
| **Q-ARQ-1** | Como o `worker` entrega eventos publicados pelo `api`, se o registro do Modulith só grava para consumidores do processo que publica? | `outbox_event` no `api`, repasse pelo `worker` (db-scheduler) ao registro do Modulith: `docs/adr/0002-eventos-api-worker.md`, aceito em `decisoes/2026-11-24.md §11` | 0-12 |
| **Q-ARQ-2** | Onde fica a sessão da BFF, com os tokens, para sobreviver à troca de instâncias? | Spring Session JDBC no PostgreSQL, tokens na sessão, sem cifra de aplicação na v1: `docs/adr/0003-sessao-bff.md`, aceito em `decisoes/2026-11-24.md §11` | 0-09 |
| **Q-ORQ-1** | 0-17 pode fazer a estrutura do design system com P-12 aberta? | Sim, e as cores passam a ser as da paleta do Pedro: `decisoes/2026-11-24.md §11` e `decisoes/2026-11-24-paleta.md` | 0-17 |

## Portão

Rodar na raiz, nesta ordem, com data e máquina:

- `comandos.pre_requisito` → exit 0.
- `comandos.suite` → verde: back e front com a contagem medida no portão, **0 falhas, 0
  pulados**; `cmp` do contrato com exit 0; `verificar-portabilidade.sh` com exit 0.
- `comandos.arquitetura` → verde.
- `docker compose down -v && docker compose up -d --wait && sh deploy/local/verificar.sh` → exit 0.
- `docker compose --profile backup-teste up -d --wait && sh deploy/backup/testar-local.sh` → exit 0.
- `docker compose up -d --wait && (cd frontend && npx playwright test)` → verde.
- `sh deploy/deploy.sh homologacao-local` → exit 0 (inclui o e2e contra as imagens).
- actionlint por contêiner no raiz, em `backend/` e em `frontend/` → exit 0 nos três.
- Sem achado bloqueante aberto em `reviews/`.
- **Revisão ampla das stories de IAM (0-09, 0-19, 0-20)**, porque IAM está em
  `rigor_completo_em` e o modo completo pede revisão ampla no fim de cada onda.

## Fechamento

<escrito pelo Orquestrador no /portao: medições com data e máquina, dívida do Ponytail, o
que ficou para depois>
