# Onda 0 — A fundação técnica existe, roda localmente de ponta a ponta e está guardada por teste

Dono: Planejador. Data: 2026-11-24. Spec lida: `especificacao-crm-akeel-v1.1.md` (**v1.2**,
o nome do arquivo não mudou), §0, §2, §3.1, §3.2, §4, §5.1, §5.2, §5.7, §6.1, §6.3
(`company`, `app_user`), §6.4, §9.5, §9.17, §9.20, §10.1, §10.4, §11, §12, §13, §14.1
(com P-18 e P-19). Também: `docs/adr/0001-stack.md`
(revisão 2, aceito em `decisoes/2026-11-24.md §10`), `docs/adr/0002-eventos-api-worker.md`
e `docs/adr/0003-sessao-bff.md` (aceitos em `decisoes/2026-11-24.md §11`),
`decisoes/2026-11-24.md §5–§15`, ADR 0003 com as emendas P-18 (§14) e §15,
`decisoes/2026-11-24-paleta.md` (com o complemento de §12),
`time.yml` de 2026-11-24.

## Objetivo

No fim da onda existe, e não existia antes:

- os dois repositórios de produto (`backend/`, `frontend/`) e o ambiente local em Docker
  Compose (PostgreSQL, Keycloak com o realm de teste `crm`, igual ao real, com os clientes
  `crm-bff`, `crm-api` e `crm-web` e os grupos `/Perfis/*` e `/Equipes/*`, nome por
  `KEYCLOAK_REALM`, Garage, Mailpit);
- um backend Java 25 / Spring Boot 4 que roda nos modos `api`, `worker` e `migrate`, com
  jobs persistidos (db-scheduler), eventos de domínio na mesma transação entregues pelo
  `worker`, e-mail só por fila, arquivos por S3 só via `platform.storage`, e login BFF pelo
  cliente confidencial (`crm-bff`, P-18), com renovação do token no servidor e logout pelo
  `end_session`;
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
desativação: RF-IAM-01 a 05) é da Onda 1, inclusive a sincronização do grupo `/Perfis/*`
pela Admin API (P-19). Nada nesta onda autoriza por `roles` ou `groups` (0-09, critério 14).

## Stories

| Id | Story | Repositório | Papéis | Requisitos da spec | Rigor | Depende de |
|---|---|---|---|---|---|---|
| 0-01 | Os dois repositórios de produto existem e o raiz os ignora | raiz + back + front | devops | D-03, D-04; ADR dec. 2 | leve | — |
| 0-02 | Ambiente local inteiro com um comando | raiz | devops | §4.5 Local, D-05, D-06, D-07, §5.1, §5.2 (grupos), RF-NOT-09, RF-SEC-03 | leve (realm exercido por 0-09/0-20) | 0-01 |
| 0-03 | Backup cifrado, restaurável, sem provedor fixo | raiz | devops | §4.6, RNF-07, RNF-14, P-17 (mecanismo) | leve + gêmeo por presença | 0-02 |
| 0-04 | Homologação local pelo mesmo caminho do deploy; um host, proxy com os quatro prefixos da BFF | raiz | devops | §4.5 passos 4–5, RNF-13, RF-SEC-03, §5.1 (mesmo domínio); ADR 0003 emenda §15 | leve | 0-03, 0-07, 0-10, 0-15, 0-20 |
| 0-05 | Backend compila em Java 25, sobe e migra contra PostgreSQL real | back | qa, dev | D-03, D-05, §4.2, §12 | leve | 0-01 |
| 0-06 | Fronteiras da arquitetura viram teste | back + raiz (docs) | arquiteto | D-03, §4.1, §4.2, §4.3, §12 | leve + gêmeo por presença | 0-05 |
| 0-07 | CI do backend e imagem | back | devops | §4.5 passos 1–3, RNF-09, RF-SEC-03 | leve | 0-06 |
| 0-08 | Contrato OpenAPI versionado no backend | back | qa, dev | §4.2 Contrato, §12, §13.2 | leve | 0-07 |
| 0-09 | Login BFF pelo Keycloak (`crm-bff`); o navegador só recebe cookie; sessão no PostgreSQL; token renovado no servidor; logout pelo `end_session`; callback atrás do proxy; back-channel desligado | back | qa, arquiteto, dev | D-07, D-09, §5.1, P-18, P-19, RF-SEC-03, RNF-13; ADR 0003 (com as emendas P-18 e §15) | **completo (IAM)** | 0-08 |
| 0-10 | Modos api / worker / migrate e jobs persistidos | back | qa, dev | §4.1, §4.2 Jobs, §4.5 passo 5, RNF-13 | leve | 0-06 |
| 0-11 | E-mail do sistema só por fila, com novas tentativas | back | qa, arquiteto, dev | D-10, §10.4, RF-NOT-05 (parcial), 07, 08, 09 | leve | 0-10 |
| 0-12 | Evento na `outbox_event` na mesma transação; só o worker repassa e entrega | back | arquiteto, qa, dev | §0.4.3, §4.1, §4.4, §10.1 (formato); ADR 0002 | leve | 0-10 |
| 0-13 | Arquivos por URL pré-assinada, qualquer S3 por configuração | back | qa, dev | §4.2 Arquivos, RNF-14, RF-SEC-03 | leve | 0-06 |
| 0-14 | Frontend sobe, testa e constrói; rotas, cache, i18n pt-BR | front | qa, dev | D-04, §4.2, RF-UI-03 (idioma) | leve | 0-01 |
| 0-15 | CI do frontend e imagem estática | front | devops | §4.5 passos 1–3, RNF-09 | leve | 0-14 |
| 0-16 | Datas, horas e dinheiro no formato brasileiro e no fuso do usuário | front | qa, dev | RF-UI-03, RF-UI-04, §6.1, §12, D-02 | leve | 0-14 |
| 0-17 | Componentes base acessíveis sobre tokens; cores da paleta do Pedro + `bg-dark`, Inter self-hosted, "CRM Akeel" com wordmark e favicon, tudo provisório | front | qa, dev | §4.2 Componentes, RF-UI-03 (texto fixo, crit. 14), RF-UI-07, 08, 09, RNF-10, D-22; P-12 (provisória, `decisoes §12`; nome por `§13`) | leve | 0-16 |
| 0-18 | Cliente TS gerado do contrato, igual ao do backend | front | qa, dev | §4.2 Contrato, §12, §13.2 | leve | 0-17; entre repos: 0-09 |
| 0-19 | SPA leva ao login, mostra quem entrou, nunca toca em token | front | qa, dev | D-07, §5.1, P-19, RF-UI-03, RF-UI-07 | **completo (IAM)** | 0-18 |
| 0-20 | Ponta a ponta: login no Keycloak local e o nome na tela | front | qa, dev | D-07, §5.1, P-18, §12 e2e, RNF-11 (parcial) | **completo (IAM)** | 0-19; entre repos: 0-09, 0-02 |

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
| 6 | — | 0-09 | — | F espera 0-09 (0-18 precisa de `GET /api/session` no contrato); 0-09 tem Arquiteto (regra do back-channel no `ArchitectureTest`) e QA juntos, arquivos diferentes |
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
`backend/openapi/openapi.json` (0-08, 0-09); `ArchitectureTest` (0-06, 0-09: a regra do
back-channel do ADR 0003; 0-11, 0-12: as duas regras do ADR 0002); `compose.yaml` (0-02, 0-03, 0-04); `.gitignore` do raiz (0-01,
0-02); `frontend/package.json` e `frontend/src/**` (0-14, 0-16 a 0-20);
`frontend/eslint.config.js` (0-14, 0-16, 0-17, 0-19); `frontend/index.html` e
`frontend/public/**` (0-14, 0-17: título e favicon).

## Cobertura

### A. A fundação da spec (§3.2, observação 1)

| Item da spec | Story | Ou: fora desta onda, porque |
|---|---|---|
| CI/CD | 0-07, 0-15 (CI), 0-04 (deploy, local) | execução real no GitHub e na VPS: pendências "remoto" e "VPS" |
| Keycloak | 0-02, 0-09, 0-19, 0-20 (realm local `crm`, igual ao real, nome só por `KEYCLOAK_REALM`) | login contra o realm real: clientes criados (`decisoes §15`); em dev só à mão, pelo `crm-bff-dev`; homologação com o real espera a Onda 1 e o cadastro de `https://crm.akeel.com.br/` (pendência) |
| Outbox | 0-12 (ADR 0002) | purga das tabelas: *depois, se* pesarem |
| Jobs | 0-10 | — |
| Design system | 0-17 (estrutura, tokens, componentes base, cores da paleta do Pedro e `bg-dark`, tipografia, nome, wordmark e favicon provisórios) | identidade definitiva e logo gráfico: P-12 (não bloqueia; troca por tokens) |
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
| PostgreSQL (completo diário + WAL, fora da VPS) | 0-03 | o "fora da VPS, no Brasil" real: P-17 (no Brasil confirmado em `decisoes §12`; provedor indefinido) |
| Arquivos (S3), replicação diária | 0-03 | idem |
| Keycloak no mesmo esquema | 0-02 (banco no PostgreSQL, local), 0-03 | o Keycloak real fica em `akpannel.akeel.com.br`, fora da VPS do CRM (§5.1 v1.2): o backup dele não é do CRM; confirmar com a TI (pendência) |
| RPO ≤ 15 min · RTO ≤ 4 h | 0-03 (WAL contínuo; restauração local medida) | medição na VPS: pendência "VPS" |
| Teste de restauração mensal documentado | 0-03 (roteiro em `docs/operacao/backup.md`) | a execução mensal começa com produção |
| Retenção 35 + 12 | 0-03 | conflito com titulares: P-08 |

### D. Autenticação (§5.1)

| Item | Story | Ou: fora |
|---|---|---|
| Realm `crm` em `akpannel.akeel.com.br`; issuer e discovery | 0-02 (realm local `crm`), 0-09 (crit. 3, 12) | realm real: só configuração; login real espera o `crm-bff` |
| Clientes do realm: `crm-bff`, `crm-api`, `crm-web` | 0-02 (os três espelhados), 0-09 (login só pelo confidencial, `client_id` por configuração) | `crm-web-dev`: não espelhado (o CRM não faz login por cliente público, P-18). `crm-bff` e `crm-bff-dev` reais: criados pela TI (`decisoes §15`); `crm-bff-dev` não espelhado (só para dev à mão contra o real) |
| Nome do realm e `client_id` só por configuração | 0-02 (crit. 9), 0-09 (crit. 12), 0-19 (crit. 9), 0-20 (crit. 1, 6) | — |
| Grupos `/Perfis/*` e `/Equipes/*`; `preferred_username` = e-mail; claims `roles` e `groups` | 0-02 (espelho local), 0-09 (crit. 14) | — |
| P-19: `roles` e `groups` não autorizam nada | 0-09 (crit. 14), 0-19 (Fora) | — |
| BFF, Authorization Code + PKCE, cliente confidencial (P-18) | 0-09, 0-20 | — |
| Access token de 5 min renovado pelo refresh token | 0-09 (crit. 13) | — |
| Logout pelo `end_session` com `id_token_hint` e `post_logout_redirect_uri` | 0-09 (crit. 9), 0-19 (crit. 5), 0-20 (crit. 4) | — |
| Validação do JWT na API (issuer, JWKS, `aud` contendo `crm-api`) | 0-09 (crit. 6: Bearer não abre a BFF) | Resource Server da API pública: módulo API |
| Tokens só no servidor | 0-09, 0-19, 0-20 | — |
| Cookie `HttpOnly`, `Secure`, `SameSite=Lax` | 0-09, 0-20 | — |
| CSRF em toda escrita | 0-09, 0-19 | — |
| Nenhum token no `localStorage` | 0-19, 0-20 | — |
| Login com Google restrito a `akeel.com.br` | — | provedor Google no realm real `crm` (configuração da TI) |
| Backend confere de novo o domínio | 0-09, 0-19, 0-20 | — |
| MFA obrigatório para administradores | — | depende do realm real, de `is_admin` (Onda 1) e de P-09 |
| Sessão 8 h inativa / 30 dias absoluta | 0-09 (absoluta pelo `CREATION_TIME` do banco) | — |
| Sessão sobrevive à troca de instância (RNF-13) | 0-09 (ADR 0003, critério 8) | cifra dos tokens em repouso: sem cifra na v1 (`decisoes/2026-11-24.md §11`), gatilhos no ADR 0003 |
| Callback `/login/oauth2/code/keycloak` com o host público (cabeçalhos encaminhados) | 0-09 (crit. 15), 0-04 (crit. 9) | — |
| Mesmo domínio: `/api/`, `/oauth2/authorization/`, `/login/oauth2/code/`, `/logout` para o backend; o resto para a SPA | 0-04 (crit. 8, homologação local), 0-19 (crit. 8, proxy do Vite), 0-02 (crit. 8, documento) | fumaça contra `crm.akeel.com.br` real: pendência "VPS" |
| Segredos de `crm-bff`/`crm-bff-dev` só por variável (`KEYCLOAK_CLIENT_SECRET`, sem padrão) | 0-09 (crit. 10), 0-04 (crit. 10, segredo do Docker), 0-02 (crit. 8, documento) | — |
| Sem backchannel logout na v1; sessão encerrada no Keycloak cai em ≤ 5 min | 0-09 (crit. 16, 17) | back-channel ligado: *depois, se* um dos gatilhos do ADR 0003 (emenda §15) |
| Exceção do `id_token_hint` no logout | 0-09 (crit. 2) | — |

### E. Ciclo de vida do usuário (§5.2)

| Item | Story | Ou: fora |
|---|---|---|
| RF-IAM-01 a RF-IAM-05 | — | Onda 1 (módulo IAM). **Risco:** até lá, qualquer `@akeel.com.br` verificado no realm entra; nenhuma homologação com o realm real antes da Onda 1 |
| RF-IAM-02: sincronizar o grupo `/Perfis/*` pela Admin API (`crm-api`) ao convidar e ao mudar o papel (P-19, D-09) | — | Onda 1 (módulo IAM), com o mapeamento dos conjuntos de permissões nos 4 perfis (P-19, Pedro) |
| `client_id` do link de convite (`execute-actions-email`, hoje `crm-web`) | — | Onda 1 (RF-IAM-02); a confirmar com a TI (P-18) |

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
| RF-UI-03 | 0-14 (idioma), 0-16 (formatos), 0-17 crit. 14 (texto fixo em atributos e expressões; N2 de `reviews/0-14.md`) | — |
| RF-UI-04 | 0-16 | origem do fuso (`app_user.time_zone`): Onda 1 |
| RF-UI-05 (tempo real) | — | SSE + `LISTEN/NOTIFY` entram com a primeira tela que os pede, com a regra de "Notas para stories futuras" (fechar com a sessão e o token) |
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
| Tempo real (SSE + `LISTEN/NOTIFY`) | nenhuma tela desta onda muda por ação de outro usuário; nenhuma story da Onda 0 abre SSE. Requisito para a story futura: ver "Notas para stories futuras" |
| PDF (Gotenberg) | primeiro uso em PRP; fora até do compose (Ponytail, 0-02) |
| Observabilidade (Micrometer, OpenTelemetry, logs JSON, Sentry; RNF-12) | **não está na lista da §3.2**; candidata à Onda 1. O alerta de falha de backup e de fila parada depende dela |
| Resource Server (API pública), com `aud` contendo `crm-api` | módulo API |
| dnd-kit, react-hook-form + zod | entram com o primeiro quadro e o primeiro formulário |
| Geração de código do jOOQ | Ponytail: `DSLContext` sem geração até a primeira tabela de negócio (0-05) |

## Notas para stories futuras

- **SSE fecha quando a sessão some ou o token vence** (ADR 0003, emenda §15,
  "Consequências"; RF-UI-05). Nenhuma story da Onda 0 abre SSE. A primeira story que criar
  uma conexão SSE (§4.2, tempo real) precisa ter, como critério de aceite com teste: a
  conexão aberta **fecha** quando a sessão do servidor some (logout, expiração, linha
  apagada de `SPRING_SESSION`, idade absoluta) **e** quando o access token da sessão vence
  sem renovação bem-sucedida. Motivo: uma conexão SSE não passa pelo filtro de renovação a
  cada evento e, sem isso, escapa da janela de ≤ 5 min (0-09, crit. 16) e do logout
  (0-09, crit. 9). Gêmeo por presença: com a sessão válida e o token renovado, a conexão
  continua aberta.

## Pendências que esta onda não resolve

| Identificador | O que bloqueia | Quem decide |
|---|---|---|
| **TI cadastra `https://crm.akeel.com.br/` (exato, sem curinga) como redirect URI e como post-logout redirect URI no `crm-bff`** (ADR 0003, emenda §15, item 1). Hoje só o callback `https://crm.akeel.com.br/login/oauth2/code/keycloak` está cadastrado; é o `redirect_uri` do convite e o `post_logout_redirect_uri` do logout, e um redirect fora da lista devolve 400. A "Backchannel logout URL" e a de front-channel ficam vazias | **Nada local** (o realm de teste e o `crm-bff-dev` aceitam `localhost`). Bloqueia o logout e o convite contra o Keycloak real em produção | Akeel (TI) |
| `client_id` do link de convite (P-18, segunda parte) | Nada nesta onda; RF-IAM-02 na Onda 1 | Akeel (TI) |
| Mapeamento dos conjuntos de permissões nos 4 perfis `/Perfis/*` (P-19, parte aberta) | Nada nesta onda; a sincronização do grupo na Onda 1 | humano (Pedro) |
| Backup do Keycloak real (fica em `akpannel`, fora da VPS do CRM) | Nada nesta onda; a §4.6 da spec ainda põe o Keycloak no esquema de backup do CRM | Akeel (TI) / Pedro |
| P-12 (identidade visual definitiva) | **Nada.** 0-17 usa valores provisórios e trocáveis (`decisoes §12`, nome por `§13`): `bg-dark #122428`, Inter, "CRM Akeel", wordmark em texto, favicon. Logo gráfico: *depois, se* vier | Akeel (design) / Pedro |
| P-17 (destino do backup) | backup real fora da VPS. **No Brasil**, confirmado em `decisoes §12`; provedor indefinido. O mecanismo de 0-03 não muda | time técnico + TI |
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
| **`bg-dark` sem hex** | Qual o valor de `bg-dark`? | `#122428` (accent 9.69:1, accent-ink 2.47:1): `decisoes/2026-11-24.md §12` e complemento da paleta | 0-17 |
| **P-15** | O CRM usa o realm `sed` compartilhado? | Não: realm próprio, nome por `KEYCLOAK_REALM`: `decisoes/2026-11-24.md §12` | 0-02, 0-09, 0-19, 0-20 |
| **Nome real do realm** | Qual é o realm do CRM? | `crm`, em `https://akpannel.akeel.com.br`, fora da VPS (spec v1.2 §5.1, `decisoes/2026-11-24.md §13`). O realm local passa a se chamar `crm` também (`deploy/keycloak/realm-crm-local.json`) | 0-02, 0-09, 0-19, 0-20 |
| **P-18** | BFF ou o cliente público `crm-web`? | BFF mantido, login por cliente **confidencial** (`crm-bff`, nome provisório); `crm-web` não é usado para login (spec §14.1, `decisoes/2026-11-24.md §14`). A TI criou o `crm-bff` e o `crm-bff-dev` (`decisoes §15`); resta o cadastro de `https://crm.akeel.com.br/` (pendência acima) | 0-02, 0-09, 0-19, 0-20 |
| **Três perguntas da TI** (`decisoes §15`) | Caminho do callback? Endpoint de backchannel logout? Front e BFF no mesmo domínio? | `/login/oauth2/code/keycloak` (registro `keycloak`); back-channel **desligado** na v1 (URL vazia); **mesmo host** `crm.akeel.com.br`, proxy com quatro prefixos para a BFF: ADR 0003, emenda §15; spec v1.2 §5.1 | 0-02, 0-04, 0-09, 0-19, 0-20 |
| **P-19** | Os papéis vivem no Keycloak ou no CRM? | No CRM (D-09); `roles` e `groups` não autorizam nada; o CRM sincroniza `/Perfis/*` pela Admin API (spec §14.1, `decisoes/2026-11-24.md §14`). A sincronização e o mapeamento são da Onda 1 | 0-02, 0-09, 0-19 |
| **Nome do produto** | "Akeel CRM" ou "CRM Akeel"? | "CRM Akeel", o da spec (`decisoes/2026-11-24.md §13`, corrige o §12) | 0-17 |

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
