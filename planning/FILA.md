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

Nada.

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
| 0-05 | **fechada** (14:49–15:20) · QA `7ed1b96` · Dev `5b29975` · remedido 15:12: 7/7, exit 0 | `reviews/0-05.md` sem bloqueantes; N1 (teste de fuso em UTC) em correção pelo Dev; N2 resolvido na emenda do ADR 0001; N3/N4 baixos |
| 0-14 | **fechada** (14:49–15:10, ~21 min) · QA `2c46456` · Dev `0e63a74` · remedido: 5/5 verdes, exit 0 | `reviews/0-14.md` sem bloqueantes; Registro a preencher (Planejador). N1 Node corrigido: QA `1021044`, Dev `2c0a12c`, remedido 5/5, 0 EBADENGINE |
| 0-02 | **fechada** (14:49–15:40) · DevOps `b7e15ca` · remedido 15:20: 21/21 ok | `reviews/0-02.md` sem bloqueantes. **N1 (média):** `crm-api` leva 401 na Admin API local (falta o escopo `kc-admin-api`); **corrigido** `b172688` (GET users 200, PUT realm 403). Perguntar à TI se o realm real tem o mesmo problema |
| 0-15 | **fechada** · DevOps `5aa603f` · `reviews/0-15.md` sem bloqueantes · **CI verde no GitHub** (run 45459445549: suíte, lint, audit, build, imagem) | N1–N4 baixos (gatilho duplo em PR, imagens por tag, `EXPOSE` redundante, lint fora do "Como verificar") |
| 0-06 | **fechada** · Arquiteto backend `27ecdcc` + raiz `5c6ba71` · Dev `516d5f1` · correções N1/N2/N4 `77a5ded` · remedido backend 20/20 | `reviews/0-06.md` sem bloqueantes; ADR 0001/SISTEMA.md ainda citam o padrão antigo `..platform..` (Arquiteto alinha depois da 0-03) |
| 0-16 | **fechada** · QA `4aeffd1` + `287f1a6` · Dev `afc8659` + `c36e0c2` · remedido 62/62 · CI verde no GitHub (run 45461152294) | `reviews/0-16.md` sem bloqueantes |
| 0-03 | **fechada** · DevOps `80ddb50` + correções `9cd125a` (falha fechada §19 provada, guarda sem os buracos N1, permissões 711/644 medidas em Linux) · ADR emendado `03ebce1` · remedido: portabilidade 0, verificar 0 | `reviews/0-03.md` sem bloqueantes; observar desligamento não limpo do postgres com destino quebrado quando houver alerta (RNF-12) |
| 0-08 | **fechada** · QA `427acf8` · Dev `f2f6a38` · remedido 27/27 · `reviews/0-08.md` sem bloqueantes | N1 (teste de estabilidade na mesma JVM é fraco), N4 (`/v3/api-docs` anônimo: decidir na 0-09), N5 (`cmp` do raiz vermelho até a 0-18) |
| 0-09 | QA `ac8b867` · Dev `ad9b009` · 87/87 · sabotagens 12/12 + critério 18 ✅ · **revisão NÃO PASSA** (`reviews/0-09.md`): B1 os nomes do CSRF não estão no contrato | correção depois do Dev da 0-10 (backend em série): QA (B1 + N2 sessão sem cliente autorizado) → Dev → reconferência. N3 §26; N4 doc CRM_PUBLIC_URL (DevOps); N1 Registro (Planejador) |
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
frontend. (3) clones no scratchpad compartilhado somem entre agentes, e um `cd` que falha roda o comando no lugar errado (dois Revisores hoje): cada agente usa um diretório único e aborta se o `cd` falhar. (4) `rclone --checksum` sobre remote `crypt` compara só o tamanho (0-03).
