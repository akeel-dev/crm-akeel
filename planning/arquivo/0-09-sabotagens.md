# Story 0-09 — sabotagens contra o código real (evidência, rigor completo)

Transcrito pelo Orquestrador do relatório do QA (2026-11-24, macOS, JDK 25), clone do backend
em `ad9b009`. Procedência: ✅ execução em todas. Comando por linha:
`./mvnw -B test -Dtest=<Classe>`; restauração com `git checkout -- . && git clean -fdq src`.

| # | Sabotagem | Vermelho | Teste e mensagem | Verde |
|---|---|---|---|---|
| 1 | `http-only: false` | exit 1, 12 testes, 1 falha | `BffLoginTest.aVerifiedAkeelUserLandsOnTheSpaWithOnlyAHardenedSessionCookie`: `[SESSION is HttpOnly]` | exit 0, 12/0 |
| 2 | PKCE desligado (resolver que tira `code_challenge`/`code_verifier`) | exit 1, 12 testes, 5 falhas | `theAuthorizationRequestUsesPkceS256…`: falta `code_challenge_method=S256` | exit 0, 12/0 |
| 3 | `csrf.disable()` | exit 1, 6/6 | `CsrfTest`: sem cookie `XSRF-TOKEN`; `POST /logout` sem CSRF → 302 (esperado 403) | exit 0, 6/0 |
| 4 | Checagem de domínio e e-mail verificado removida | exit 1, 2 falhas | `someoneOutsideTheDomainOrUnverified…` (Bruno e Carla) | exit 0, 12/0 |
| 5 | Repositório de tokens padrão | exit 1, 1 falha | 8(c) `bLoadsTheAuthorizedClientOfASessionCreatedOnA…`: `Expecting actual not to be null` | exit 0, 4/0 |
| 6 | `.refreshToken(...)` trocado por `.authorizationCode()` | exit 1, 3/3 | `assertRenewed`: token igual em A e B; gêmeo `expected: 401 but was: 200` | exit 0, 3/0 |
| 7 | Logout só local (`logoutSuccessUrl("/")`) | exit 1, 2 falhas | `logoutEndsTheServerSession…` (sem `end_session`); `followingTheEndSessionRedirect…` | exit 0, 3/0 |
| 8 | Sem `server.request.header.forwarded.strategy` | exit 1, 1 falha | `behindATrustedProxyTheRedirectUriUsesThePublicHostAndScheme` | exit 0, 3/0 |
| 9 | `${KEYCLOAK_CLIENT_SECRET:x}` | exit 1, 1 falha | `theClientSecretIsOnlyTheEnvironmentPlaceholderWithoutDefault` | exit 0, 5/0 |
| 10 | `/realms/crm` plantado em `deals/` | exit 1, 1 falha | `productionCodeHasNoRealmServerOrClientLiteral` | exit 0, 3/0 |
| 11 | `getClaim("roles")` plantado em `deals/` | exit 1, 1 falha | `productionCodeDoesNotReadRoleOrGroupClaims` | exit 0, 3/0 |
| 12 | `client-secret: abc` em `application-planted.yml` | exit 1, 1 falha | `theClientSecretIsOnlyTheEnvironmentPlaceholderWithoutDefault` | exit 0, 5/0 |

Observação do QA: a 1ª versão da #6 caiu por erro de contexto (builder sem provedor), não por
asserção, e foi refeita como acima.

## Critério 18 (Arquiteto), classes reais do Spring Security 7.2.0 — ✅ execução

- `no_oidc_back_channel_logout`: `OidcBackChannelLogoutHandler`, `OidcSessionRegistry` e
  `OidcLogoutConfigurer.backChannel(...)` plantados em `deals` → exit 1, 3 violações; verde depois.
- `only_identity_reads_token_claims`: `Jwt.getClaimAsStringList("roles")` e `OidcUser.getClaims()`
  em `deals` → exit 1, 2 violações; gêmeo em `identity` → exit 0; verde depois.

CI do GitHub em `ad9b009`: run 45482326316, verde.
