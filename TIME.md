<!-- Cópia de time-padrao 0.1.0 (commit 26927d1), feita em 2026-11-24. Para atualizar, compare com o METODO.md do kit. -->

# O método do time-padrao

`time-padrao 0.1.0` · 2026-11-24

Este arquivo é a fonte do método. Na abertura de um projeto ele é copiado para
o `TIME.md` do projeto, com a versão no topo. A cópia é de propósito: o projeto
precisa funcionar numa máquina sem este kit (o brecho quebrou duas vezes em troca
de máquina por depender de arquivo fora do repositório).

**Origem.** O método foi extraído do `brecho-apiTeam`, que o operou de setembro a
novembro de 2026, e do `akeel-crm-insta`, que o copiou à mão em 16/11/2026. O que
mudou em relação ao brecho está em "O que mudou do brecho", no fim.

---

## 1. Os papéis

| Papel | Quem é | O que produz |
|---|---|---|
| **Orquestrador** | a sessão raiz, a conversa que o humano abriu | despacha, consolida, mantém FILA e ESTADO, registra as decisões do humano |
| `planejador` | agente | ondas e stories, a partir da spec |
| `arquiteto` | agente | ADRs, `SISTEMA.md`, o teste de arquitetura, os diagramas |
| `qa` | agente | o teste que falha, **antes** do Dev |
| `dev` | agente, N em paralelo | o código que faz o teste do QA passar |
| `revisor` | agente, sessão limpa | achados em `reviews/`; não conserta |
| `devops` | agente | deploy, CI, operação; nunca valor de segredo |
| **Humano (PO)** | você | a spec, as decisões, `TIME.md`, `time.yml` e `.claude/` |

**Onde cada um escreve é um fato estruturado, e o dono dele é o `time.yml`**
(seção `escrita`). Este arquivo não repete os caminhos: quem precisar, lê lá.

**A spec é do humano.** Nenhum papel edita a spec. O Planejador fatia; quem achar
que a spec está errada abre `conflitos/`.

## 2. O fluxo

```
Abertura → Planejamento → Ondas ───────────────────────────→ Fechamento
  │            │            │                                    │
time.yml    ondas e      por story: QA (vermelho) → Dev (verde)  colheita
TIME.md     stories      → Revisor; portão no fim da onda       local → kit
```

1. **Abertura** (`/abrir-projeto`): estrutura, `time.yml`, primeira decisão do
   humano, primeira entrada da FILA.
2. **Planejamento:** o Arquiteto decide a stack num ADR, e o humano ratifica. O
   Planejador escreve a onda e as stories dela.
3. **Ondas** (`/despachar`): cada story passa por QA → Dev → Revisor.
4. **Portão** (`/portao`): no fim de cada onda. Fecha a onda ou devolve o que falta.
5. **Fechamento** (`/colher`): o que a onda ensinou vai para o `COLHEITA.md`
   local, e o que se repetiu em dois projetos é proposto ao kit.

## 3. A story é a unidade de despacho

Uma story é um arquivo em `planning/stories/`, escrito pelo Planejador a partir do
modelo `story.md`. Ela carrega **tudo** o que o papel precisa:

- os requisitos da spec que ela cumpre, pelo identificador (RF, T, D…);
- os arquivos que ela toca, por papel;
- o critério de aceite e o comando que o verifica;
- as pendências que a bloqueiam, se houver.

O Orquestrador despacha dizendo **qual story** e **qual papel**, e não reescreve a
story em prosa no despacho. É assim que ele deixa de ser o gargalo (no brecho ele
fez 259 dos 766 commits).

## 4. As regras de despacho (não negociáveis)

1. **QA antes de Dev** na mesma story. Teste escrito por quem implementou confirma
   a implementação, não a spec.
2. **Revisor em sessão limpa**, só com a story, o diff e os testes. Nunca com o
   histórico do Orquestrador.
3. **Não nomeie a conclusão no despacho.** Peça a medição, não a confirmação. No
   brecho, dois papéis em modelos diferentes erraram junto porque o despacho já
   trazia a resposta.
4. **Stories independentes vão em paralelo.** Vários Devs ao mesmo tempo, desde que
   a tabela de colisão da onda diga que eles não tocam os mesmos arquivos. Cada um
   em um worktree.
5. **Consolidação por `cherry-pick`, e a suíte é remedida no `main`.** Nunca herdar
   o número medido no worktree.
6. **Todo papel escreve só no conjunto dele.** Se precisar de fora, abre
   `conflitos/<papel>-<assunto>.md`.
7. **Pendência vai para o artefato.** Dita na conversa, ela morre no despacho
   seguinte.
8. **Relatório de subagente não é artefato.** Papel despachado só para ler precisa
   ser despachado de novo para gravar.

## 5. Os dois modos

O `time.yml` declara `modo: leve` ou `modo: completo`, e a lista
`rigor_completo_em` declara onde o modo completo vale mesmo num projeto leve.

| | Leve | Completo |
|---|---|---|
| Ciclo por story | QA → Dev → Revisor | o mesmo |
| Evidência | o comando e a saída, com data | + procedência marcada (✅ execução, ✅ leitura, ⚠️ hipótese) |
| Teste novo | falha pelo motivo certo antes do Dev | + ritual de sabotagem persistido no arquivo de teste |
| Checagem por ausência | quando for a única prova | sempre com gêmeo por presença |
| Revisão ampla | no fim da fase | no fim de cada onda |

**Regra de escolha:** dinheiro, permissão, visibilidade de dados, migração de dados
e integração externa vão para `rigor_completo_em`. CRUD, telas e cadastro ficam no
leve.

## 6. As réguas

- **Evidência, não afirmação.** "Rodei e saiu isto" vale; "funciona" não vale.
  Toda medição tem data e máquina.
- **Registrar não é implementar.** Nada fora da story vira código.
- **Fato estruturado tem um dono; o resto referencia.** Prosa divergente só é pega
  por quem presta atenção. Por isso, quando der, o fato vira teste.
- **Suíte inexecutável não é suíte vermelha.** Antes de concluir algo de um build
  que falhou, confira o pré-requisito do `time.yml` (`comandos.pre_requisito`).
- **Cite por nome, não por linha.** `arquivo:linha` apodrece em horas (entradas 11
  e 22 do COLHEITA do kit).
- **Substituir, não apagar.** Frase falsa sai com a substituta datada no lugar.

## 7. Os documentos de estado têm limite

O brecho deixou a FILA chegar a 5.223 linhas e o ESTADO a 343 KB. Aqui:

- `planning/FILA.md`: só a seção ⛳ mais nova e as anteriores da onda em curso.
  Passou de `limites.fila_linhas`, o Orquestrador move as seções velhas para
  `planning/arquivo/FILA-<onda>.md` no portão.
- `ESTADO.md`: reescrito (não acrescido) no portão de cada onda. Passou de
  `limites.estado_linhas`, está errado.
- O `/portao` mede os dois e acusa.

## 8. O humano e a sessão fria

- **Decisões do humano** ficam em `planning/decisoes/AAAA-MM-DD.md`, numeradas por
  parágrafo (§1, §2…). Quem escreve é o Orquestrador, com as palavras do humano
  citadas.
- **A primeira resposta numa sessão fria** (`/retomar`) começa pelo bloco "Para
  mostrar ao humano" da ⛳ mais nova: as decisões pendentes, cada uma com
  recomendação, e as tarefas que só ele pode fazer. Depois, o `planning/roteiro.md`.
- **Antes de apresentar**, conferir `git status` e `git log origin/main..HEAD`.
  Trabalho não commitado não aparece em `git log`.
- `TIME.md`, `time.yml` e `.claude/` são do humano. O Orquestrador propõe a
  mudança; o humano escreve ou autoriza.

## 9. `conflitos/`

A saída legítima de todo papel. Nome com prefixo de papel, nunca numeração. Quem
consolida os conflitos é o Orquestrador; quem decide os que travam é o humano. Não
há timeout automático: conflito travado, o Orquestrador escala.

## 10. Ponytail (menos código)

Plugin de terceiros (`DietrichGebert/ponytail`, MIT). Configuração do kit:

- **Modo `full`, injetado só no `dev` e no `revisor`** (variáveis em
  `.claude/settings.json`, modelo `settings.json` do kit). QA, DevOps, Arquiteto e
  Planejador não recebem a injeção.
- **A spec vence o Ponytail.** Requisito com identificador na spec (RF, RNF, D,
  T…) não é especulativo, e não se corta. O Ponytail corta o que a spec não pede.
- **Nunca `ultra`.**
- **Atalho deliberado leva comentário** `shortcut: <limite>, <gatilho para
  rever>`. Atalho sem gatilho é achado do Revisor.
- **No portão**, o `/ponytail-debt` gera o registro de dívida e ele entra no
  fechamento da onda.
- **O Ponytail não é aplicado aos testes.** Teste é o que a spec exige.

## 11. Archify (diagramas)

Skill de terceiros (`tt-a1i/archify`, Apache-2.0). Configuração do kit:

- **Dono dos diagramas: o Arquiteto.** Ficam em `docs/arquitetura/<nome>/`, com o
  `candidate.json` versionado. O HTML é gerado.
- **Modo `on-demand`.** Por padrão o Archify faz páginas sem pedir (relatórios,
  comparações, planos). Isso disputaria espaço com `reviews/` e `planning/`. A
  linha `[archify explainer: on-demand]` vai no `CLAUDE.md` do projeto.
- **Poucos diagramas, os que mudam decisão:** módulos, ciclos de vida de estado,
  fluxos de evento.
- **Diagrama tem conferência.** O de módulos é gerado com `--repo-root`, e o
  Arquiteto compara a lista de módulos do JSON com a do teste de arquitetura.
  Divergência é achado.
- `.archify/` (rascunhos) fica no `.gitignore`.

## 12. A colheita em dois níveis

- **`COLHEITA.md` do projeto:** o que aconteceu aqui. Categorias `padrão`,
  `processo`, `ferramenta`, `bug conhecido`, `ambiente`. Propor é de qualquer
  papel; consolidar é do Orquestrador; auditar é do Revisor. Número é endereço e
  nunca é reescrito.
- **`COLHEITA.md` do kit:** só o que se repetiu em **dois projetos diferentes**.
  Duas ondas do mesmo projeto não são dois contextos. O `/colher` propõe; o humano
  decide e escreve no kit.

## 13. O que este método não tem (dito porque a ausência importa)

- **Nada impede um papel de escrever fora do conjunto dele.** É convenção lida e
  obedecida: mitigação, não mecanismo. O hook que bloquearia isso depende de o
  Claude Code dizer qual agente está escrevendo, e isso ainda não foi medido
  (pendência P-01 do kit).
- **O Revisor roda no mesmo modelo do Dev**, salvo decisão em contrário. O que o
  separa é a sessão limpa e o despacho que não nomeia a conclusão.

## O que mudou do brecho

| Brecho | time-padrao | Por quê |
|---|---|---|
| Método dentro do projeto, com emendas | Método no kit, copiado com versão | um método para todos os projetos |
| Despacho em prosa | Story autocontida | o Orquestrador era o gargalo |
| Um Dev por vez | Devs em paralelo por tabela de colisão | projeto grande não cabe em fila única |
| `planning/` com dois donos | FILA e decisões do Orquestrador; ondas e stories do Planejador | dono único |
| FILA e ESTADO sem limite | Limite no `time.yml`, medido no portão | 5.223 linhas e 343 KB |
| Rigor completo em tudo | Modo leve e completo, por área | o rigor custa onde não há risco |
| Superpowers | Removido; o método é este arquivo | ele pressupõe uma sessão só, e o time separa QA de Dev |
| — | Ponytail no Dev e no Revisor | menos código por story |
| — | Archify no Arquiteto | ver o sistema sem ler prosa |
