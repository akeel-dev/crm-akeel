# FILA — seções da Onda 0 (arquivadas no portão de 2026-11-25)

## 2026-11-24 (manhã) — substituída pela seção abaixo

**Onde paramos:** o projeto acabou de ser aberto com o time-padrao 0.1.0. Não há
código. A spec v1.1 está na raiz e o estudo do Pipedrive em `pipedrive/`.

### Decidido em 24/11 (`decisoes/2026-11-24.md §6`)

Modo leve com rigor completo nos 8 módulos; Paperclip como piloto depois da Onda 1;
kit publicado num GitHub privado (P-03); commit inicial feito. O lugar e o nome do
projeto (`~/Desktop/crm-akeel`) ficam como estão.

**Só o humano pode fazer:**
- [x] Plugins instalados em 24/11: time-padrao 0.1.0 e Ponytail 5.3.3 (este desligado no escopo de usuário e ligado só pelo `.claude/settings.json` do projeto), Archify 3.3 como skill global.
- [x] `.claude/settings.json` gravado pelo Pedro em 24/11 (idêntico ao modelo do kit).
- [ ] Puxar com a Akeel as pendências que travam o prazo: **P-07** (fim da assinatura do Pipedrive) e **P-15** (realm `sed` compartilhado), que afetam a fundação.

### Próxima ação de cada papel

| Papel | Próxima ação | Bloqueada por |
|---|---|---|
| arquiteto | **ADR 0001 — a stack.** Registrar D-03 a D-07 e D-22 da spec e propor os `comandos` e os caminhos de `qa` e `dev` do `time.yml`. Decidir as duas escolhas que a spec deixou para o início: jobs (JobRunr ou db-scheduler) e S3 (P-17) | nada: pronto para despachar |
| planejador | Onda 0 (fundação, spec §3.2: CI, Keycloak, outbox e jobs, design system, backups, e-mail) | ADR 0001 aceito |
| qa, dev, revisor, devops | — | Onda 0 |

### Em voo

Nada.

## 2026-11-24 (tarde) — substituída pela seção abaixo

**Onde paramos:** o Arquiteto escreveu o `docs/adr/0001-stack.md` (**proposto**) e um
`SISTEMA.md` mínimo. Ele recomenda **db-scheduler** para jobs e **Garage** (nó único)
para S3, além de Maven com wrapper e um repositório só (`backend/` + `frontend/`).
O ADR traz o bloco proposto para `comandos` e `escrita` do `time.yml`. A statusline do
Ponytail foi ligada no `~/.claude/settings.json` do Pedro.

**Evidência:** o `pre_requisito` proposto, rodado nesta máquina, dá exit 1 só no Java
(`java -version` → 17.0.12). Docker ok, Node v23.11.0 ok.

### Para mostrar ao humano

**Decidido** (`decisoes §7–§10`): ADR 0001 rev. 2 **aceito**; dois repositórios git
(`backend/`, `frontend/`) ignorados pelo raiz; Garage na VPS, com R2 plugável por
configuração; "o caminho mais específico vence"; backup com destino em aberto, trocável
por configuração; paralelo entre backend e frontend, em série dentro de cada repositório;
raiz num GitHub privado. O `time.yml` foi atualizado pelo Orquestrador, com autorização
pontual. JDK 25 instalado.

**Evidência:** o `pre_requisito` do `time.yml` dá exit 1 só por `test -d backend/.git`
(os clones não existem). Java 25, Docker e Node passam.

**Onda 0 fatiada e destravada** (`planning/ondas/onda-0.md`, stories 0-01 a 0-20).
ADRs 0001, 0002 e 0003 aceitos (`decisoes §10–§11`). Tokens do Keycloak sem cifra,
anotado no ADR 0003. A paleta do Pedro (`decisoes/2026-11-24-paleta.md`) entrou na 0-17.
Raiz commitado e publicado em `github.com/akeel-dev/crm-akeel` (privado).

**Decidido em §12–§14:** identidade provisória (`bg-dark #122428`, Inter self-hosted,
"CRM Akeel", wordmark em texto); backup no Brasil, com o provedor a definir. Keycloak real:
realm `crm` em `akpannel.akeel.com.br`, operado pela TI. **P-18:** BFF mantido. **P-19:**
o CRM manda nos papéis e sincroniza `/Perfis/*`. **A spec está na v1.2** (o Orquestrador
foi autorizado a mantê-la atual, §13). ADRs 0001 e 0003 emendados; stories 0-02, 0-09,
0-17, 0-19 e 0-20 ajustadas.

**§15:** ADR 0004 aceito (sem AG-UI); exceção do `id_token_hint` aceita. A TI entregou o
realm `crm` (Keycloak 26.8.2; `crm-bff` e `crm-bff-dev` criados; sessão de 8 h/30 d). Os
secrets estão **fora do repositório**, em `~/.config/crm-akeel/keycloak.env` (permissão 600).
Respostas à TI no ADR 0003, emenda §15, e na spec P-18: callback
`/login/oauth2/code/keycloak`; sem backchannel logout na v1; front e BFF no mesmo domínio.

**Nenhuma decisão pendente do Pedro.**

**Pendências do humano e da TI (nenhuma bloqueia a 0-01):**
- [ ] Pedro → TI: manter redirects exatos (sem curinga) e confirmar *Valid post logout redirect URIs*
- [ ] Pedro: mapear os conjuntos de permissões nos 4 perfis (P-19, Onda 1).
- [ ] Trocar todos os secrets e o token do GitHub antes da produção (combinado com o Pedro).
- [ ] Com a Akeel: P-07 (data), provedor do backup no Brasil.

### Onda 0: andamento

| Story | Estado | Evidência |
|---|---|---|
| 0-01 | **fechada** (14:40–14:46, ~6 min) | `pre_requisito` exit 0 remedido no `main`; `reviews/0-01.md` sem bloqueantes; raiz `cb1bff4` + `0759a7f`, backend `e60799f`, frontend `ce18bd6` |
| 0-05 | **fechada** (14:49–15:20) · QA `7ed1b96` · Dev `5b29975` · remedido 15:12: 7/7, exit 0 | `reviews/0-05.md` sem bloqueantes; N1 (teste de fuso em UTC) em correção pelo Dev; N2 resolvido na emenda do ADR 0001; N3/N4 baixos |
| 0-14 | **fechada** (14:49–15:10, ~21 min) · QA `2c46456` · Dev `0e63a74` · remedido: 5/5 verdes, exit 0 | `reviews/0-14.md` sem bloqueantes; Registro a preencher (Planejador). N1 Node corrigido: QA `1021044`, Dev `2c0a12c`, remedido 5/5, 0 EBADENGINE |
| 0-02 | **fechada** (14:49–15:40) · DevOps `b7e15ca` · remedido 15:20: 21/21 ok | `reviews/0-02.md` sem bloqueantes. **N1 (média):** `crm-api` leva 401 na Admin API local (falta o escopo `kc-admin-api`); **corrigido** `b172688` (GET users 200, PUT realm 403). Perguntar à TI se o realm real tem o mesmo problema |
| 0-15 | **fechada** · DevOps `5aa603f` · `reviews/0-15.md` sem bloqueantes · **CI verde no GitHub** (run 45459445549: suíte, lint, audit, build, imagem) | N1–N4 baixos (gatilho duplo em PR, imagens por tag, `EXPOSE` redundante, lint fora do "Como verificar") |
| 0-06 | **fechada** · Arquiteto backend `27ecdcc` + raiz `5c6ba71` · Dev `516d5f1` · correções N1/N2/N4 `77a5ded` · remedido backend 20/20 | `reviews/0-06.md` sem bloqueantes; ADR 0001/SISTEMA.md ainda citam o padrão antigo `..platform..` (Arquiteto alinha depois da 0-03) |
| 0-16 | **fechada** · QA `4aeffd1` + `287f1a6` · Dev `afc8659` + `c36e0c2` · remedido 62/62 · CI verde no GitHub (run 45461152294) | `reviews/0-16.md` sem bloqueantes |
| 0-03 | **fechada** · DevOps `80ddb50` + correções `9cd125a` (falha fechada §19 provada, guarda sem os buracos N1, permissões 711/644 medidas em Linux) · ADR emendado `03ebce1` · remedido: portabilidade 0, verificar 0 | `reviews/0-03.md` sem bloqueantes; observar desligamento não limpo do postgres com destino quebrado quando houver alerta (RNF-12) |
| 0-08 | **fechada** · QA `427acf8` · Dev `f2f6a38` · remedido 27/27 · `reviews/0-08.md` sem bloqueantes | N1 (teste de estabilidade na mesma JVM é fraco), N4 (`/v3/api-docs` anônimo: decidir na 0-09), N5 (`cmp` do raiz vermelho até a 0-18) |
| 0-09 | QA `ac8b867` + `66218ed` · Dev `ad9b009` + `59c1156` (B1 contrato CSRF, N2 sessão sem cliente → 401) · remedido 105/105 | reconferência do Revisor em voo; cópia do contrato no frontend sendo atualizada |
| 0-10 | QA `ae84ea4` · Dev `ffa2bf5` · critério 10 ✅ (`planning/arquivo/0-10-arquiteto.md`) · **revisão NÃO PASSA**: B1 modo desconhecido sobe api+worker juntos | correção em voo: QA (B1 + N1 saúde do worker) → Dev |
| 0-18 | **fechada** · QA `0f2656d` · DevOps `725039b` · Dev `d8c7b2f` · remedido 170/170 · `reviews/0-18.md` sem bloqueantes | **suíte completa do raiz exit 0 pela 1ª vez (17:31)**; overrides do TS em §23 |
| 0-19 | **fechada** · QA `ffaf0b4` + `7c0449c` + `a826164` · Dev `ec25124` + `9d37f99` · remedido 239/239 · `reviews/0-19.md` sem bloqueantes; 13/14 sabotagens do QA vermelhas, a 14ª virou teste | N2: o ADR 0003 ainda diz `csrf.spa()` (§22 aceitou o handler simples) → Arquiteto; N6: tela em branco fora de 200/401 → candidata a story; Registro → Planejador |
| 0-07 | **fechada** · DevOps `d18f77d` · `reviews/0-07.md` sem bloqueantes · **CI verde no GitHub** (run 45462660612: suíte, Trivy, imagem) | N1 (média): a spec pede análise estática e a story não pediu (Planejador decide); N2–N5 baixos |
| 0-17 | **fechada** · QA `5bbb4fb` + `78b110b` · Dev `ec80562` + `2b172f9` · remedido 159/159 | `reviews/0-17.md`: B1/B2 fechados; N1 (COLOR_PAIRS sem amarração ao CSS) e N2 (foco `accent-ink` sobre escuro) para a fila; **falta cor de erro na paleta** (identidade, §12) |

Não bloqueantes da 0-14 (`reviews/0-14.md`), que vão para stories seguintes:
- N1: a versão de Node diverge entre `time.yml` (`v22+`), `package.json` (`>=22.12`), o lock
  (`^22.13 || ^24 || >=26`) e o ADR (26 LTS). **Proposta:** `engines` = `^22.13 || ^24 || >=26`
  e o mesmo no `pre_requisito` (o `time.yml` é do Pedro). A máquina usa o Node 23, fora do suporte.
- N2: a regra de lint pt-BR não pega atributos (`aria-label`, `title`, `placeholder`) nem
  `{"texto"}` (RF-UI-03). Para 0-16 ou 0-17.
- N3: o lint fica fora do `npm test` e da `suite`. Para 0-15 (CI).

Não bloqueante, que fica registrado: `!.env.example` nos três `.gitignore` libera um `.env*`
para versionamento (reviews/0-01.md item 3). Fica enquanto o arquivo não existir; o Revisor
confere quando ele aparecer.

### Próxima ação de cada papel

| Papel | Próxima ação | Bloqueada por |
|---|---|---|
| qa → dev → revisor | 0-09 login BFF (backend, rigor completo) | em voo (QA) |
| qa → dev | 0-18 cliente TS do contrato (frontend) | 0-09 |
| qa → dev | 0-10 a 0-13 (backend: jobs, e-mail, eventos, arquivos) | 0-09 (mesmo repositório, em série) |
| devops | 0-04 homologação local (atenção: o `ambiente-local.md` exporta `CRM_DB_PASSWORD`/`CRM_STORAGE_*`, que o backend não lê; o backend lê `SPRING_DATASOURCE_*` — ver `docs/operacao/variaveis-backend.md`) | 0-07 ✓, 0-10, 0-15 ✓, 0-20 |

### Em voo

- qa: 0-09.

**Com o Pedro:** nada pendente.

**Para a COLHEITA:** (1) o Revisor da 0-17 rodou sabotagens no `frontend/` real quando o clone
sumiu (desfeito, sem perda): sabotagem só em clone, e conferir o `cd` antes. (2) dois agentes
rodando `npm ci` no mesmo `frontend/node_modules` se atropelam: não paralelizar a suíte do
frontend. (3) clones no scratchpad compartilhado somem entre agentes, e um `cd` que falha roda o comando no lugar errado (dois Revisores hoje): cada agente usa um diretório único e aborta se o `cd` falhar. (4) não apagar arquivos do scratchpad por curinga (`rm *.log`): é compartilhado entre agentes. (5) `rclone --checksum` sobre remote `crypt` compara só o tamanho (0-03).

## 2026-11-24 (noite, 19:00) — substituída pela seção abaixo

**Onde paramos:** o Pedro pediu para parar os agentes depois das tarefas em voo. Nenhum
agente rodando. Onda 0 com **13/20 fechadas** (0-01, 0-02, 0-03, 0-05, 0-06, 0-07, 0-08, 0-14,
0-15, 0-16, 0-17, 0-18, 0-19). Tudo commitado e publicado nos três repositórios.

**Última medição (Orquestrador, 19:00, macOS):** backend `./mvnw -B verify` → 117/117, exit 0
(HEAD `872f94f`); frontend `npm test` → 239/239 (HEAD `9d37f99`). A `comandos.suite` do raiz
**fica vermelha no `cmp`** até a cópia do contrato ser refeita no frontend (passo 1 abaixo):
o backend mudou o contrato do `POST /logout` (`59c1156`, `4c95c03`).

### Para mostrar ao humano

Nada pendente com o Pedro. Decisões do dia: `decisoes/2026-11-24.md` §1–§26 (a §25 foi descartada).
Regra que vale em todo despacho: código sem comentários (§17/§18, também no `CLAUDE.md`).

### Próxima ação, em ordem

| # | Papel | Ação | Detalhe |
|---|---|---|---|
| 1 ✅ | dev (frontend) | feito: `299c66a`, `cmp` 0, 239/239; **0-09 fechada** | o cookie `XSRF-TOKEN` agora é `required: false` (`conflitos/dev-logout-cookie-obrigatorio.md`); o `cmp` volta a 0. Isso fecha a **0-09** |
| 2 ✅ | revisor | **0-10 fechada**: reconferência PASSA (`reviews/0-10.md`); N4 (`crm.mode=migrate` só em yml sobe api) e N10 ficam na fila | B1 (modo inválido falha) e N1 (saúde do worker). Ponto do Dev: a validação no contexto mora no bean do scheduler (`db-scheduler.enabled=false` a pularia) |
| 3 | planejador | Registros finais de 0-09 e 0-10 | evidência em `planning/arquivo/0-09-sabotagens.md` e `0-10-arquiteto.md`; QA `66218ed`/`ea8ebbf`, Dev `59c1156`/`4c95c03`/`872f94f` |
| 4 | qa → dev → revisor | **0-11** e-mail: QA `9e4aa2f`, Dev `5c8d747`, 131/131; regra do Arquiteto e Revisor em voo | já inclui a named interface de `platform.jobs` (critério 9) |
| 5 | qa → dev → revisor | 0-12 eventos, 0-13 arquivos (backend, em série) | |
| 6 ✅ | qa → dev → revisor | **0-20 fechada** (QA `2a296c7`+`4999d2d`, Dev `43ce802`, `reviews/0-20.md` sem bloqueantes, 120/120). N1 intermitência e N3 `id_token_hint` em correção pelo QA | depende de 0-09 fechada e do compose |
| 7 | devops | 0-04 homologação local | último; ver a nota de variáveis em `docs/operacao/variaveis-backend.md` |
| 8 | orquestrador | `/portao 0` | reescrever o `ESTADO.md`; levar as lições abaixo para a `COLHEITA.md` (`/colher`) |

### Para a COLHEITA (lições do dia)

1. Sabotagem só em clone de diretório único; abortar se o `cd` falhar (dois Revisores rodaram no lugar errado).
2. Não apagar arquivos do scratchpad por curinga: é compartilhado.
3. Dois agentes com `npm ci` no mesmo `frontend/` se atropelam: não paralelizar a suíte do frontend.
4. Commit de testes vermelhos quebra a compilação do `main` do backend: o Revisor da story anterior mede num clone fixado no commit dela.
5. `rclone --checksum` sobre remote `crypt` compara só o tamanho.
6. No Spring Boot 4.2, `server.request.header.forwarded.strategy=native` não existe (é `web-server`).
7. Parâmetro de cookie `required: true` no OpenAPI vira parâmetro obrigatório no cliente gerado; cookie que o navegador envia é `required: false`.

### Em voo

Nada.

## 2026-11-25 (11:15) — ⛳ LEIA ESTA SEÇÃO PRIMEIRO

**Onde paramos:** o Pedro pediu para pausar os agentes para reiniciar o computador. **Nenhum
agente rodando.** Tudo commitado e publicado nos três repositórios (raiz, `backend/`, `frontend/`).
O estado completo está no `ESTADO.md`; a evidência do dia, em `planning/arquivo/0-11-e-0-20-evidencia.md`.

**Onda 0 (fundação): 20/20 stories fechadas** em 25/11. Próximo: `/portao 0` — 0-01, 0-02, 0-03, 0-05, 0-06, 0-07, 0-08, 0-09, 0-10,
0-14, 0-15, 0-16, 0-17, 0-18, 0-19, 0-20. A **0-11** (e-mail) foi aprovada pelo Revisor (`reviews/0-11.md`,
PASSA COM RESSALVAS); falta só ele conferir a regra de arquitetura `65c7928`, que entrou depois.
Faltam **0-12** (eventos), **0-13** (arquivos), **0-04** (homologação local) e o **portão**.

**Última medição (Orquestrador, 2026-11-25 11:12):** `comandos.suite` → **exit 0** (backend 132/132 em
3:31 min, frontend 239/239, `cmp` do contrato 0, portabilidade ok). HEADs: backend `c07d095`, frontend `63752e9`.
O compose crm-akeel (`docker compose up -d --wait` no raiz) precisa estar de pé para o e2e e a 0-04;
depois de reiniciar o computador, subir o Docker Desktop e o compose de novo.

### Para mostrar ao humano

**Nenhuma decisão do Pedro bloqueia a próxima ação.** Pendências dele que **não bloqueiam** a Onda 0
(listadas para não se perderem; vinham do ⛳ de 24/11):
- sessões de estudo do Pipedrive para os módulos 🟡 (spec §14.2);
- com a Akeel: P-07 (prazo), P-01–P-06 (AUT, WPP, PRP, RPT, PRJ, MIG), provedor do backup no Brasil (P-17);
- P-19: mapear os conjuntos de permissões nos 4 perfis do Keycloak (necessário na Onda 1, USR);
- com a TI: confirmar *Valid post logout redirect URIs* do `crm-bff` real (spec P-18);
- antes da produção: trocar os secrets do Keycloak e revogar o token antigo do GitHub (§15, §20);
- liberar o deploy real quando quiser (§24).

Decisões em `planning/decisoes/2026-11-24.md` §1–§27 (a §25 foi descartada; a §12 foi corrigida pela §13).
Regras em todo despacho: **código sem comentários** (§17/§18, no `CLAUDE.md`).

### Antes de despachar (depois de reiniciar o computador)

O Pedro abre o Docker Desktop; o Orquestrador sobe o compose (`docker compose up -d --wait` no raiz)
e roda `sh deploy/local/verificar.sh` (exit 0) e o `comandos.pre_requisito`.

### Próxima ação, em ordem

| # | Papel | Ação | Detalhe |
|---|---|---|---|
| 1 | qa → dev | **0-11 N2: UUIDv7** | a spec §6.1 e a 0-12 pedem v7 (`decisoes §27`); a 0-11 gerou v4. Gerador v7 em `platform` com teste de ordenação; aplicar ao `mail_delivery`. Corrige a 0-11 antes da 0-12 |
| 2 | revisor | reconferir a **0-11** (num clone): a regra `65c7928` e a correção do UUID | depois disso a 0-11 fecha |
| 3 ✅ | revisor | reconferência da **0-20** PASSA (80/80, sabotagem por asserção) — | reconferir as correções da **0-20** (`63752e9`, N1/N3), que entraram depois do fechamento | num clone; o e2e precisa do compose |
| 4 | arquiteto | atualizar `SISTEMA.md` e `docs/arquitetura/modulos.md` (login, jobs, e-mail existem; `jobs`/`mail` não são "futuro"); criar `docs/arquitetura/atalhos.md` com os atalhos de `planning/arquivo/` e `reviews/` | só docs |
| 5 | planejador | Registros de 0-10, 0-11, 0-20 (hoje vazios/velhos; evidência em `planning/arquivo/`); tirar da 0-04 e da `onda-0.md` o "remoto do raiz não existe" (existe desde 24/11); levar os achados da 0-11 (N1 teste de FAILED, N6 intermitência, N8 `@NamedInterface` de `platform.mail`, N9 STARTTLS na homologação) para as stories certas | só planning |
| 6 | devops | 0-11 N3/N4: `MAIL_*` em `docs/operacao/variaveis-backend.md`; `MAIL_EHLO_NAME` obrigatório na VPS; o comando de verificação de e-mail e a porta da saúde | não bloqueia |
| 7 ✅ | qa → dev → revisor | **0-12 fechada** | QA `5dc05e9`, Dev `9126384`, Arquiteto `4e0d7bb` (regras do critério 7, com sabotagem); remedido 152/152 (5:29 min); evidência em `planning/arquivo/0-12-evidencia.md` |
| 8 ✅ | qa → dev → revisor | **0-13 fechada** | QA `d194a71`, Dev `5e501d7`, Arquiteto critério 8 ✅, `reviews/0-13.md` sem bloqueantes, 168/168. Antes da 0-04: N1 (nada aplica o CORS do bucket) e N3 (tamanho de parte sem validação) → QA → Dev; N2 (docs de `CRM_STORAGE_*`) → DevOps. N4/N5 (checksum `WHEN_REQUIRED` e `url-connection-client` sem necessidade medida) ficam em `docs/arquitetura/atalhos.md` |
| 9 ✅ | devops | **0-04 fechada** | DevOps `ddabcb5` + `a54224a`; `reviews/0-04.md` sem bloqueantes; homologação e e2e verdes. Achados N1–N4/N7 viram condições para liberar o deploy real (`decisoes §29`) |
| 10 | orquestrador | `/portao 0`, depois `/colher` | reescrever o `ESTADO.md`; definir gatilho para os 5 atalhos sem gatilho em `docs/arquitetura/atalhos.md` ("ao menos uma vez", saúde de e-mail desligada, dois contadores de tentativa, sessão relida, tela em branco) |

Os passos 1–6 podem rodar em paralelo, respeitando um escritor por repositório (1 no backend; 3 só lê;
4 e 5 e 6 no raiz em arquivos diferentes — commits em sequência).

### Como despachar (o que aprendemos)

- Backend e frontend são repositórios git separados: **um escritor por repositório por vez**.
  QA, Dev e Arquiteto escrevem no repositório real; Revisor e sabotagens rodam sempre num **clone de
  diretório único fixado no commit** da story (`cd ... || exit`).
- Rigor completo (IAM, USR, TRS, MIG, API, WPP, BIL, LGPD): sabotagens refeitas contra o código real,
  procedência ✅/⚠️, gêmeo por presença; a evidência vai para `planning/arquivo/`, nunca para comentário.
- O Orquestrador remede a suíte depois de cada Dev e faz o push depois de cada story fechada
  (token do GitHub com escopo `repo` + `workflow`, nunca gravado em arquivo).

### Notas para stories futuras (achados da 0-12)

- **N8, dinheiro no payload de evento:** o `payload` volta do banco como `Map<String,Object>` e, numa sonda com Jackson 3 fora do Spring, `BigDecimal("1234.50")` voltou como `Double`. A §6.1 proíbe `double` em dinheiro. A primeira story que publicar valor monetário em evento (DEA) precisa de um teste disso.
- **N5/N6 (baixos):** `correlationId` gerado com `UUID.randomUUID()` em vez do `IdGenerator`; `WorkerEventStaleness` relê o modo em vez de usar `RunModes.mode`. Corrigir na primeira story que tocar `platform.events`.
- **Testes sensíveis a tempo sob carga:** `SystemMailTest#withTheSmtpDown…` e `DomainEventOutboxTest#aFailedConsumerIsNotRetriedBeforeTheMinimumAge…` falharam com carga ~9 e passaram sozinhos. Não rodar duas suítes do backend ao mesmo tempo; observar no CI.

### Lições

Consolidadas na `COLHEITA.md` (entradas 2 a 11) em 25/11.

### Em voo

- Correções da 0-13 feitas: N2 docs (`061284b`), QA N1/N3 (`c799de5`), Dev (`46e767a`). Suíte do raiz exit 0 (backend 177/177, frontend 239/239). 0-04 fechada. Próximo: portão da Onda 0.
