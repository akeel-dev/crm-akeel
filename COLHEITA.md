# O que esta casa já aprendeu — crm-akeel

**A caneta:** propor é de qualquer papel; consolidar é do Orquestrador; auditar é do
Revisor na revisão ampla. Número é endereço: nunca é reescrito.

| Categoria | O que entra | Vai para o kit? |
|---|---|---|
| `padrão` | forma que valeria em outro projeto | sim, depois de dois projetos |
| `processo` | mudança de processo feita aqui, com o porquê | não |
| `ferramenta` | script, comando ou configuração que resolveu dor recorrente | não |
| `bug conhecido` | sintoma, causa, conserto, **como reconhecer de novo** | só num pacote de stack |
| `ambiente` | máquina, toolchain, contêiner | só num pacote de stack |

**Herança.** O kit traz regras promovidas e candidatos (`COLHEITA.md` do
time-padrao). Eles não são copiados para cá: entrada desta casa é o que
**aconteceu aqui**. Quando acontecer aqui algo que já é candidato no kit, a entrada
daqui cita o número do kit. É assim que o segundo contexto aparece.

---

## Índice

**`padrão`** — (nenhum ainda)
**`processo`** — 1, 2, 3, 4, 5, 11
**`ferramenta`** — 10
**`bug conhecido`** — 6, 7, 8, 9
**`ambiente`** — 10

---

<!-- Modelo de entrada:

### N. `categoria` — título que diz a forma, não o caso

**O que aconteceu (AAAA-MM-DD, máquina):** ...
**Evidência:** commit, arquivo, saída medida.
**Conserto:** ...
**Como reconhecer de novo:** ...
**Kit:** candidato nº X do kit, se for o caso.
-->

### 1. `processo` — a abertura foi feita à mão, sem o plugin instalado

**O que aconteceu (2026-11-24, macOS):** o projeto foi aberto pelo Orquestrador
seguindo o texto de `commands/abrir-projeto.md` do time-padrao, porque os plugins
ainda não estavam instalados na sessão. A estrutura foi copiada do kit (commit
`26927d1`) e conferida: o estudo do Pipedrive copiado inteiro (`diff` das listas de
arquivos vazio) e a spec idêntica à original (`cmp` sem diferença).

**O que isso deixa sem medir:** as pendências P-02 (`${CLAUDE_PLUGIN_ROOT}` no
comando), P-04 e P-05 (filtro do Ponytail por subagente) do kit continuam abertas.
Elas fecham no primeiro despacho com os plugins instalados.

**Ajuste que o kit pode absorver:** o `time.yml` modelo tem `spec: SPEC.md` e
`humano: [SPEC.md, ...]`; quando a spec já existe com outro nome, as duas linhas
mudam juntas, e o comando só fala da primeira.

### 2. `processo` — sabotagem e revisão só em clone de diretório único, fixado no commit

**O que aconteceu (2026-11-24, macOS):** dois Revisores rodaram comandos no repositório real quando o clone sumiu ou o `cd` falhou (frontend ficou em HEAD destacado; um `node_modules/.vitest-cache` apareceu no raiz).
**Conserto:** cada agente cria o próprio diretório (`mktemp -d`), faz `git checkout <commit da story>` e usa `cd … || exit`.
**Como reconhecer de novo:** um agente relata "o clone sumiu" ou o `git status` de um repositório real aparece sujo depois de uma revisão.

### 3. `processo` — o scratchpad é compartilhado entre agentes

**O que aconteceu (2026-11-25):** um Arquiteto apagou `*.log` do scratchpad sem listar antes; podia ter apagado evidência de outro agente.
**Conserto:** nada de curinga no scratchpad; evidência que importa vai para `planning/arquivo/`.

### 4. `processo` — um escritor por repositório por vez; o Revisor da story anterior mede num clone fixado

**O que aconteceu (2026-11-24/25):** o commit de testes vermelhos de uma story quebrou a compilação do `main` do backend enquanto a story anterior era revisada; dois `npm ci` no mesmo `frontend/` se atropelaram.
**Conserto:** QA, Dev e Arquiteto escrevem em série no repositório real (sem worktree: os repositórios de produto são aninhados no raiz, e um worktree do raiz não os leva); Revisor e sabotagens rodam em clone fixado no commit.

### 5. `processo` — medir antes de classificar a gravidade

**O que aconteceu (2026-11-24):** o Orquestrador chamou de "redirecionamento aberto" um achado da 0-19 sem medir; o Revisor mediu e era robustez (o `replaceState` não sai da origem).
**Conserto:** a gravidade de um achado leva a mesma procedência (✅ medido / ⚠️ hipótese) que a evidência.

### 6. `bug conhecido` — Spring Boot 4.2: `server.request.header.forwarded.strategy=native` não existe

**Sintoma:** `No enum constant …ForwardedHeaderStrategy.native` na subida. **Conserto:** `web-server` (o `native` antigo foi absorvido por ele). **Evidência:** `conflitos/qa-0-09-forwarded-strategy.md`, ADR 0003.

### 7. `bug conhecido` — cookie enviado pelo navegador marcado `required: true` no OpenAPI

**Sintoma:** o cliente TS gerado (openapi-typescript) passa a exigir `params.cookie`, e o `tsc` quebra. **Conserto:** `required: false`. **Evidência:** `conflitos/dev-logout-cookie-obrigatorio.md`.

### 8. `bug conhecido` — Keycloak 26 recusa parênteses em nome/sobrenome

**Sintoma:** o login trava em "Update Account Information" (VERIFY_PROFILE), "Value contains invalid character". **Causa:** validador `person-name-prohibited-characters` do perfil padrão. **Conserto:** nomes sem parênteses no realm de teste; `verificar.sh` recusa usuário com `requiredActions` (raiz `11e7a9b`).

### 9. `bug conhecido` — `rclone --checksum` sobre remote `crypt` compara só o tamanho

**Sintoma:** objeto sobrescrito com conteúdo do mesmo tamanho não vai para o backup. **Conserto:** sem `--checksum`. **Evidência:** story 0-03.

### 10. `ambiente` / `ferramenta` — db-scheduler sem `scheduler-name` faz lookup de hostname (5 s no macOS)

**Sintoma:** "Hostname-lookup took 5037ms" em cada contexto do Spring; a suíte do backend foi a 19 min. **Conserto:** `db-scheduler.scheduler-name: ${HOSTNAME:crm}` (backend `c07d095`): 0 lookups, ~4–6 min.

### 11. `processo` — o método praticado nesta casa difere do `TIME.md` em dois pontos

Sem worktree e sem `cherry-pick` (ver 4), e a evidência de sabotagem vai para `planning/arquivo/` e `reviews/`, não para comentário (regra do Pedro, `decisoes §17/§18`). O `/ponytail-debt` do portão procura `shortcut:` em comentários e vai voltar vazio: os atalhos estão nos relatórios e em `planning/arquivo/`. Registrado em `decisoes §27`.
