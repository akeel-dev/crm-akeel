# FILA — crm-akeel

Dono: Orquestrador. Diz **qual é a próxima ação e de quem ela é**. Limite:
`limites.fila_linhas` do `time.yml`; no portão, as seções velhas vão para
`planning/arquivo/`.

Como saber que esta FILA está velha: a data da ⛳ mais nova é anterior ao último
commit de outro papel. Nesse caso, o artefato datado vence.

---

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


**Bloqueio de ambiente (humano):** liberar disco no Mac e reiniciar o Docker Desktop. Depois: remedir 0-05, rodar de novo a verificação da 0-02 (DevOps) e `docker compose down -v` dos restos.

## 2026-11-24 (tarde) — ⛳ LEIA ESTA SEÇÃO PRIMEIRO

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
| 0-05 | QA `7ed1b96` vermelho (exit 127, sem build) · Dev `5b29975`: 7/7 verdes **no relato do Dev** | **remedição do Orquestrador falhou por ambiente** (Docker somente leitura): suíte inexecutável, não vermelha |
| 0-14 | **fechada** (14:49–15:10, ~21 min) · QA `2c46456` · Dev `0e63a74` · remedido: 5/5 verdes, exit 0 | `reviews/0-14.md` sem bloqueantes; Registro da story a preencher (Planejador) |
| 0-02 | DevOps: arquivos prontos, **sem commit** | bloqueada: Docker somente leitura (disco do Mac 99%, 2,1 GiB livres) |

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
| devops | 0-02 (ambiente local: compose) — trilha R | nada |
| qa → dev | 0-05 (backend Java 25 + Postgres) — trilha B | nada |
| qa → dev | 0-14 (esqueleto do frontend) — trilha F | nada |
| orquestrador | criar os remotos `crm-akeel-backend` e `crm-akeel-frontend` no GitHub | autorização do Pedro |

### Em voo


**Bloqueio de ambiente (humano):** liberar disco no Mac e reiniciar o Docker Desktop. Depois: remedir 0-05, rodar de novo a verificação da 0-02 (DevOps) e `docker compose down -v` dos restos.
