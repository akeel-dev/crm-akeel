# Conflito — story 0-06: o Dev tocou o pom.xml

Aberto por: Orquestrador, 2026-11-24.

**O quê:** a story 0-06 diz "dev: nada nesta story", mas os testes de arquitetura precisam
de `spring-modulith-bom` 2.2.0 (import), `spring-modulith-starter-test` (test) e
`archunit-junit5` 1.5.1 (test). O `backend/pom.xml` é do Dev, então o Arquiteto parou e o
Orquestrador despachou o Dev: commit `516d5f1` no backend, 7/7 verdes, todas as
dependências em escopo test.

**Para o Revisor:** não é excesso de escopo; foi despacho do Orquestrador.
**Para o Planejador:** acrescentar a linha do Dev na tabela de papéis da 0-06.

**Estado: resolvido** — o Planejador acrescentou a linha do Dev à 0-06; revisão da 0-06 fechada.
