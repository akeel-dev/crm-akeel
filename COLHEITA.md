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
**`processo`** — 1
**`ferramenta`** — (nenhum ainda)
**`bug conhecido`** — (nenhum ainda)
**`ambiente`** — (nenhum ainda)

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
