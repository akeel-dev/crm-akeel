# ADR 0003 — A sessão da BFF, com os tokens, fica no PostgreSQL pelo Spring Session JDBC

Dono: Arquiteto. Data: 2026-11-24. Estado: aceito pelo humano em 2026-11-24 (planning/decisoes/2026-11-24.md §11)

Responde a **Q-ARQ-2** da Onda 0 (trava a story 0-09).

## Contexto

D-07 e §5.1: BFF com Authorization Code + PKCE, tokens **só no servidor**, cookie
`HttpOnly`/`Secure`/`SameSite=Lax`, CSRF, sessão inativa 8 h e absoluta 30 dias. §4.5
passo 5 e RNF-13: deploy por troca de instâncias, "sem parada perceptível". RF-SEC-03:
segredos em arquivo de segredos do Docker. RF-SEC-04 exige cifra no banco para tokens
**de terceiros** (WhatsApp, Google), não para os do Keycloak. A infraestrutura da spec
(§4.1) não tem Redis.

Sessão em memória: todo deploy desloga todo mundo, e um login iniciado numa instância
falha se o callback cair em outra (o pedido de autorização, com `state` e o
`code_verifier` do PKCE, fica na `HttpSession`:
`HttpSessionOAuth2AuthorizationRequestRepository`, padrão do Spring Security,
docs.spring.io/spring-security/reference/servlet/oauth2/client/authorization-grants.html).

**Duas armadilhas conferidas** (2026-11-24):

| Fato | Evidência |
|---|---|
| Spring Boot 4.2 autoconfigura sessão em JDBC com `spring-boot-starter-session-jdbc`; propriedades `spring.session.jdbc.*` (tabela padrão `SPRING_SESSION`, limpeza `cleanup-cron` padrão `0 * * * * *`, `initialize-schema` padrão `embedded`, ou seja, **não** cria a tabela no PostgreSQL) e `spring.session.timeout` | docs.spring.io/spring-boot/reference/web/spring-session.html; docs.spring.io/spring-boot/appendix/application-properties/index.html (versão estável 4.2.0) |
| **Os tokens não ficam na sessão por padrão.** O Boot registra um `OAuth2AuthorizedClientRepository` que usa um `OAuth2AuthorizedClientService`, cujo padrão é `InMemoryOAuth2AuthorizedClientService`: com Spring Session, o usuário continuaria logado na outra instância, mas sem os tokens | docs.spring.io/spring-security/reference/servlet/oauth2/client/core.html (Spring Security 7.2.0), seção `OAuth2AuthorizedClientRepository / OAuth2AuthorizedClientService` |

## Decisão

1. **Spring Session JDBC no mesmo PostgreSQL do CRM** (`spring-boot-starter-session-jdbc`).
   As tabelas `SPRING_SESSION` e `SPRING_SESSION_ATTRIBUTES` nascem por migração Flyway
   (o script PostgreSQL do próprio `spring-session-jdbc`), não pelo `initialize-schema`.
2. **Os tokens moram na sessão:** um bean `HttpSessionOAuth2AuthorizedClientRepository`
   substitui o repositório padrão. Assim tokens, `SecurityContext` e pedido de
   autorização ficam num só lugar, que some no logout e na expiração.
3. **Tempos:** `spring.session.timeout=8h` (inatividade). A idade absoluta (30 dias)
   é conferida pela aplicação contra o `CREATION_TIME` da sessão, que está no banco e
   vale em qualquer instância. Os dois configuráveis (§5.1, "ajustável").
4. **Cookie:** o do Spring Session, com `HttpOnly`, `Secure` e `SameSite=Lax`
   (`server.servlet.session.cookie.*`). A troca do id da sessão no login (fixação de
   sessão) é a do Spring Security.
5. **Limpeza de expiradas:** a do próprio Spring Session (`cleanup-cron`, um `DELETE`
   por minuto em cada `api`, idempotente). É infraestrutura, não regra de negócio, então
   não fere a §4.2.
6. **Proteção dos tokens em repouso: sem cifra de aplicação na v1.** O que protege:
   - **o refresh token não vale sozinho:** o CRM é cliente confidencial, e no token
     endpoint cliente confidencial tem de se autenticar (RFC 6749 §6). O segredo do
     cliente está no arquivo de segredos do Docker (RF-SEC-03), **não no banco**;
   - access token de vida curta (o do realm);
   - quem lê `SPRING_SESSION` já tem o `SESSION_ID` em claro, que é a própria
     credencial do cookie: cifrar os tokens não fecha esse acesso. A defesa real é o
     acesso ao banco (só o papel da aplicação) e o backup cifrado (pgBackRest
     `aes-256-cbc`, ADR 0001 decisão 6);
   - sessão apagada no logout e na expiração.

> **Decidido pelo Pedro** (2026-11-24, `planning/decisoes/2026-11-24.md` §11): os
> tokens do Keycloak ficam na sessão **sem cifra de aplicação**.
>
> **Motivo:** a RF-SEC-04 só exige cifra no banco para tokens **de terceiros**
> (WhatsApp, Google), não para os do Keycloak; e quem lê a tabela `SPRING_SESSION` já
> tem o `SESSION_ID` em claro, que é a própria credencial do cookie, então cifrar os
> tokens não fecha esse acesso.
>
> **Gatilhos que obrigam a cifrar** (alternativa "Cifrar os atributos da sessão",
> abaixo): a sessão passar a guardar token que vale sem o segredo do cliente (ex.:
> **token do Google**, que cai na RF-SEC-04); pedir `offline_access`; alguém além da
> aplicação ganhar leitura do banco (ex.: **réplica de BI**); ou **achado de
> pentest/ASVS** (RF-SEC-07, RNF-09). Qualquer um deles reabre esta decisão.

## Alternativas consideradas

| Alternativa | Por que não agora | Gatilho que a faria valer |
|---|---|---|
| **Sessão em memória** (a mais barata) | Fere a RNF-13: todo deploy desloga todos, e login com callback em outra instância falha | — (a spec fecha) |
| **Redis** (`spring-boot-starter-session-data-redis`) | Infraestrutura nova (contêiner, backup, monitoramento) para ~50 usuários; o PostgreSQL já está lá e já tem backup | Medição mostrar a sessão pesando no PostgreSQL (latência da RNF-02) |
| **Cifrar os atributos da sessão** (AES-256-GCM num `ConversionService` do `JdbcIndexedSessionRepository`, chave em segredo do Docker com id de versão para rotação) | Custo de uma classe, uma chave e o roteiro de rotação, para proteger um refresh token que sem o segredo do cliente não serve; não protege o `SESSION_ID` | A sessão passar a guardar token que vale sem o segredo do cliente (ex.: token do Google, que cai na RF-SEC-04), `offline_access`, alguém além da aplicação ganhar leitura do banco (réplica de BI), ou achado de pentest/ASVS (RF-SEC-07, RNF-09) |
| **`JdbcOAuth2AuthorizedClientService`** (tokens na tabela `oauth2_authorized_client`, sessão à parte) | Duas tabelas para o mesmo ciclo de vida; o token sobreviveria ao logout se ninguém o apagasse | Precisarmos dos tokens fora de uma sessão de navegador (job agindo em nome do usuário) |
| **Sessão sem estado em cookie cifrado** | O cookie passaria do limite de ~4 KB com id, access e refresh token; revogar sessão vira lista negra; fora do que o Spring Session oferece | — |
| Limpeza de sessões por tarefa do db-scheduler no `worker` | Mais código que a limpeza embutida, para o mesmo `DELETE` | O `DELETE` por minuto aparecer na carga do banco |

## Guardado por

Todos no teste de integração da 0-09 (QA), em `comandos.suite`, com Keycloak e
PostgreSQL de Testcontainers e **dois contextos `api`** contra o mesmo banco:

| Regra | Teste que fica vermelho |
|---|---|
| Sessão no banco, não em memória | Sessão criada na instância A é reconhecida pela B (`GET /api/session` → 200) |
| Pedido de autorização no banco | Login iniciado em A, callback recebido em B → sessão autenticada |
| **Tokens na sessão, não no `InMemoryOAuth2AuthorizedClientService`** | Em B, o `OAuth2AuthorizedClientRepository` carrega o cliente autorizado da sessão criada em A (não nulo, com access token). Sabotagem registrada: voltar ao repositório padrão deixa este teste vermelho |
| Logout vale para todas as instâncias | Logout em B; o mesmo cookie em A → 401 |
| Idade absoluta | Sessão com `CREATION_TIME` além do limite configurado, usada em B → 401 |

Não há regra de dependência a declarar no `ArchitectureTest`: o repositório padrão nasce
da autoconfiguração, sem import no nosso código, então só o teste de comportamento o pega.

## Consequências para o time

- Nenhuma mudança em `time.yml`.
- **0-09 muda** (critério 8 e sabotagens): ver o retorno ao Orquestrador.
- Dev: `spring-boot-starter-session-jdbc`, migração Flyway com o esquema do Spring
  Session, bean `HttpSessionOAuth2AuthorizedClientRepository`, filtro da idade absoluta.
- DevOps: nada novo. A sessão entra no backup do PostgreSQL; restaurar um backup traz
  sessões que ainda estejam no prazo (aceitável; quem quiser derrubar todas apaga as
  linhas de `SPRING_SESSION`).
- Os atributos são serializados em Java. Uma atualização do Spring Security pode
  tornar sessões antigas ilegíveis; não conferi como o Spring Session reage (relogar
  é aceitável, erro 500 não). Verificar na primeira atualização de versão menor.
