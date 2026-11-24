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

**Pendências do humano (nenhuma bloqueia a 0-01):**
- [ ] `bg-dark` sem hex na paleta (a 0-17 não cria o token até lá).
- [ ] Revogar o token do GitHub colado na conversa de 24/11 e gerar outro.
- [ ] Com a Akeel: P-07 (data), P-15 (realm `sed`), resto da P-12 (tipografia, logo),
      destino do backup com dados no Brasil.

### Próxima ação de cada papel

| Papel | Próxima ação | Bloqueada por |
|---|---|---|
| devops | 0-01: criar os repositórios de produto (`crm-akeel-backend`, `crm-akeel-frontend`) | nada |
| qa, dev, revisor | trilhas B e F, depois de 0-01 | 0-01 |
| arquiteto, planejador | — | — |

### Em voo

Nada.
