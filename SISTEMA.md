# SISTEMA — crm-akeel

Dono: Arquiteto. Descreve **o que existe**, não o que vai existir.

Atualizado: 2026-11-24

Existem os dois repositórios de produto (conferido em 2026-11-24: `test -d backend/.git`
e `test -d frontend/.git`, exit 0): `backend/` no commit `27ecdcc` e `frontend/` no commit
`0e63a74` (esqueleto da SPA, 0-14). A stack está em `docs/adr/0001-stack.md`.

O backend é o esqueleto da 0-05: Spring Boot 4.2.0, com Flyway 12.11.0 e jOOQ 3.21.9
gerenciados pelo Boot, e o enforcer `requireJavaVersion [25,)`. Só existe
`br.com.akeel.crm.CrmApplication`; não há nenhum módulo (o `ModularityTest` imprime
`módulos detectados (0)`) nem `application.yml`. Em teste, Spring Modulith 2.2.0 (BOM) e
ArchUnit 1.5.1 (commit `516d5f1`).

Os testes de arquitetura (0-06) rodam em `comandos.arquitetura` e estão em
`backend/src/test/java/br/com/akeel/crm/architecture/`; as regras e os módulos estão em
`docs/arquitetura/modulos.md`. As bibliotecas que eles proíbem fora do lugar
(db-scheduler, AWS SDK, JPA, Spring Security, AG-UI) ainda não estão no classpath: as
regras casam por nome e foram sabotadas com stubs.

Máquina de desenvolvimento: JDK 25.0.5.1 e Node v24.22.3 (faixa do projeto
`^22.13 || ^24 || >=26`). O `~/.mavenrc` força `JAVA_HOME` para o JDK 25; para rodar o
Maven com outro JDK (a sabotagem do enforcer com o JDK 17), use `MAVEN_SKIP_RC=true`.

Fora deste repositório, e não operado pelo CRM: o Keycloak 26.8.2 da TI em
`https://akpannel.akeel.com.br`, realm `crm`. Conferido em 2026-11-24 pelo discovery
público: issuer `https://akpannel.akeel.com.br/realms/crm`. Os clientes `crm-bff` e
`crm-bff-dev` existem segundo a TI (§15), mas não foram conferidos daqui (pedem segredo).
Os segredos ficam fora do repositório.
