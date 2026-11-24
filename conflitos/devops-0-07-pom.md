# Conflito — devops: a imagem do backend não tem verificação de saúde para responder

Aberto por: devops. Data: 2026-11-24. Story: 0-07. Estado: aberto

## O que está em conflito

O critério 4 da 0-07 pede que a imagem "sobe com a aplicação respondendo à verificação de
saúde contra o PostgreSQL do compose (0-02)". O `backend/pom.xml` (do Dev) não tem
`spring-boot-starter-web` nem `spring-boot-starter-actuator`: não há servidor HTTP nem
endpoint de saúde. A aplicação sobe, o Flyway migra e o processo termina com 0, porque
nada o mantém de pé. O DevOps não pode acrescentar a dependência (o `pom.xml` é do Dev)
e um `HEALTHCHECK` no `Dockerfile` não teria o que consultar (a base `jre-noble` também
não traz `curl`).

## Evidência

`backend/pom.xml` no commit `77a5ded`: as dependências de `compile`/`runtime` são só
`spring-boot-starter-jooq`, `spring-boot-starter-flyway`, `flyway-database-postgresql` e
`postgresql`.

Imagem `crm-backend:local` (story 0-07) contra um `postgres:18.7`, 2026-11-24 15:42 -03,
MacBook-Air-de-Maria.local:

```
Starting CrmApplication v0.0.1-SNAPSHOT using Java 25.0.5.1 with PID 1 (/app/BOOT-INF/classes started by crm in /app)
Migrating schema "public" to version "1 - extensions"
Successfully applied 1 migration to schema "public", now at version v1
Started CrmApplication in 2.717 seconds (process running for 3.196)
APP_EXIT=0
```

## O que eu proponho

O endpoint de saúde nasce com o primeiro servidor HTTP do backend, e não nesta story. A
0-10 já exige "a verificação de saúde existe nos três modos que ficam de pé" (critério 9),
e a 0-08/0-09 trazem o web. Para o Planejador: mover a parte "respondendo à verificação de
saúde" do critério 4 da 0-07 para a 0-10 (ou para a story que trouxer o actuator), com o
`HEALTHCHECK` ou o `healthcheck:` do compose de deploy como passo do DevOps dessa story. O
que a 0-07 prova hoje é "sobe, conecta e migra, como usuário não root".

Se o Planejador preferir fechar aqui: o Dev acrescenta `spring-boot-starter-actuator` (e o
web) ao `pom.xml`, e o DevOps acrescenta a verificação.

## Resolução


**Decisão do Orquestrador (2026-11-24):** levar o "responde à saúde" para a 0-10 (critério 9), sem actuator na 0-07. O critério 4 da 0-07 fecha com "sobe, migra e termina com 0 como não root".
