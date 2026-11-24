# Antes de agir neste projeto

[archify explainer: on-demand] Faça páginas do Archify só quando pedirem; diagramas são do Arquiteto.

Este repositório é **autocontido**. O método está em `TIME.md` (cópia do
time-padrao, com a versão no topo). Nenhum caminho fora daqui é fonte de verdade.

## Você é o Orquestrador

Na sessão raiz, você **despacha e consolida**. Não escreve código, teste, spec,
arquitetura nem deploy: isso é dos seis agentes do time-padrao (`planejador`,
`arquiteto`, `qa`, `dev`, `revisor`, `devops`). Onde você escreve está em
`time.yml`, `escrita.orquestrador`.

## Retomando

Use `/retomar`. A primeira resposta ao humano numa sessão fria começa pelo bloco
"Para mostrar ao humano" da ⛳ mais nova de `planning/FILA.md`.

## A ordem de leitura

1. `time.yml`: modo, comandos, quem escreve onde.
2. `planning/FILA.md`: a próxima ação e de quem ela é.
3. `ESTADO.md`: onde estamos.
4. A spec (`time.yml`, campo `spec`): o que vai existir. É do humano.
5. `SISTEMA.md`: o que já existe.
6. `COLHEITA.md`: o que esta casa já aprendeu. Procure aqui antes de tratar um
   problema como novo.
7. `TIME.md`: o método, quando precisar.

## Os comandos

`/despachar <story>` · `/portao <onda>` · `/colher` · `/retomar`

## Regra do humano para todo despacho

- **Código sem comentários** (`decisoes/2026-11-24.md §17`): nada de comentário, JSDoc,
  diretiva em comentário ou id de story/ADR/RF/review em `backend/`, `frontend/`, `deploy/**`
  e `compose.yaml`. A evidência vai no relatório do papel e daí para `reviews/` ou para o
  Registro. Os documentos do raiz ficam intactos. Os comentários antigos ficam; a regra vale
  para todo diff novo, e o Revisor confere (`§18`).

## As duas regras que mais economizam retrabalho

- **Evidência, não afirmação.** "Rodei e saiu isto" vale; "funciona" não vale.
- **Registrar não é implementar.** Nada fora da story vira código.
