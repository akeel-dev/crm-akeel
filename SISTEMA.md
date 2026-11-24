# SISTEMA — crm-akeel

Dono: Arquiteto. Descreve **o que existe**, não o que vai existir.

Atualizado: 2026-11-24

Existem os dois repositórios de produto (`test -d backend/.git` e `test -d frontend/.git`,
exit 0): `backend/` no commit `f2f6a38` e `frontend/` no commit `2b172f9`. A stack está em
`docs/adr/0001-stack.md`.

O backend: Spring Boot 4.2.0 com servidor web (`spring-boot-starter-webmvc`), Flyway 12.11.0
e jOOQ 3.21.9 gerenciados pelo Boot, e o enforcer `requireJavaVersion [25,)`. Além de
`CrmApplication`, existe um módulo: `platform`, só com `platform.openapi` (0-08), que publica o
contrato pelo springdoc 3.1.0 (`springdoc-openapi-starter-webmvc-api`, sem Swagger UI) e o
versiona em `backend/openapi/openapi.json`. Não há `application.yml`. Em teste, Spring
Modulith 2.2.0 (BOM) e ArchUnit 1.5.1.

Os testes de arquitetura (0-06, padrões de `platform` ancorados em `77a5ded`) rodam em
`comandos.arquitetura` e estão em `backend/src/test/java/br/com/akeel/crm/architecture/`; as
regras e os módulos estão em `docs/arquitetura/modulos.md`. Medido em 2026-11-24:
`[ModularityTest] módulos detectados (1): platform`, `Tests run: 13, Failures: 0`,
`BUILD SUCCESS`. As bibliotecas que eles proíbem fora do lugar (db-scheduler, AWS SDK, JPA,
Spring Security, AG-UI) ainda não estão no classpath: as regras casam por nome e foram
sabotadas com stubs.

Também existe, uma linha cada:

- Design system do frontend (0-17, fechada): tokens, `Button`, `TextField`, `Dialog`, `Toast` e
  `Wordmark` em `frontend/src/design/`, com a Inter self-hosted.
- Formatos (0-16, fechada): data, hora e BRL no fuso explícito, com relógio injetável, só em
  `frontend/src/format/`.
- CI dos dois repositórios (0-07 no backend, 0-15 no frontend), verde no GitHub segundo
  `planning/FILA.md` (runs 45462660612 e 45461152294); não conferido daqui (sem `gh`).
- Ambiente local (0-02, fechada): `compose.yaml` do raiz com PostgreSQL, Keycloak de teste (realm
  `crm`), Garage e Mailpit; conferência em `deploy/local/verificar.sh`.
- Backup (0-03, em revisão): scripts cifrados do PostgreSQL (pgBackRest) e dos arquivos em
  `deploy/backup/`, destino só por `BACKUP_S3_*`, portabilidade em `verificar-portabilidade.sh`.

Máquina de desenvolvimento: JDK 25.0.5.1 e Node v24.22.3 (faixa do projeto
`^22.13 || ^24 || >=26`). O `~/.mavenrc` força `JAVA_HOME` para o JDK 25; para rodar o
Maven com outro JDK (a sabotagem do enforcer com o JDK 17), use `MAVEN_SKIP_RC=true`.

Fora deste repositório, e não operado pelo CRM: o Keycloak 26.8.2 da TI em
`https://akpannel.akeel.com.br`, realm `crm`. Conferido em 2026-11-24 pelo discovery
público: issuer `https://akpannel.akeel.com.br/realms/crm`. Os clientes `crm-bff` e
`crm-bff-dev` existem segundo a TI (§15), mas não foram conferidos daqui (pedem segredo).
Os segredos ficam fora do repositório.
