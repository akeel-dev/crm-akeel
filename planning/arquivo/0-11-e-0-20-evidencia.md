# Evidência de 25/11 — 0-11 (e-mail), 0-20 (e2e) e desempenho da suíte

Transcrito pelo Orquestrador dos relatórios dos papéis (2026-11-25, macOS, JDK 25.0.5.1, Node 24.22.3).

## 0-11 — e-mail do sistema por fila

- QA `9e4aa2f`: vermelho por asserção e classe ausente (SystemMail, OutgoingMail, MailDelivery, MailDeliveryState).
- Dev `5c8d747`: verify 131/131. `platform.mail` (fila em `mail_delivery`, V4), FAILED na 6ª tentativa,
  `@NamedInterface("jobs")` em `platform.jobs`, `application-prod.yml` com o relay (§10.4).
- Arquiteto `65c7928`: regra `smtp_only_in_platform_mail` no ArchitectureTest. ✅ Sabotagem num clone:
  `deals.SabMail` com `JavaMailSender` e `jakarta.mail.Session` → exit 1, 2 violações; gêmeo em
  `platform.mail` → exit 0. Verify 132/132.
- Revisor (`reviews/0-11.md`, sobre `5c8d747`): **PASSA COM RESSALVAS**, 11 sabotagens. A regra `65c7928`
  ainda não foi revista pelo Revisor.

## 0-20 — e2e do login (Playwright)

- QA `2a296c7` + `4999d2d` + `63752e9`; Dev `43ce802` (playwright.config.ts, script `e2e` fora do `npm test`).
- ✅ 8/8 contra o compose + backend `872f94f`; Revisor: 120/120 (`--repeat-each=15`), 7 sabotagens
  vermelhas (cookie sem Secure/HttpOnly, SameSite=Strict, logout só local, recusa sem domínio/verificado,
  end_session sem id_token_hint).
- Correções N1 (intermitência do `goto('/')`) e N3 (end_session conferido pelo endpoint da descoberta,
  com id_token_hint e post_logout_redirect_uri): `63752e9`, ✅ 160/160 (`--repeat-each=20`); sabotagem sem
  id_token_hint agora cai por asserção em 8 s (antes, timeout).
- Bloqueio achado e resolvido: sobrenomes com parênteses no realm local travavam o login em
  VERIFY_PROFILE (validador do Keycloak 26). DevOps `11e7a9b` (raiz): nomes sem parênteses; `verificar.sh`
  passou a recusar usuário com `requiredActions`.

## Desempenho da suíte do backend — Dev `c07d095`

`db-scheduler.scheduler-name: ${HOSTNAME:crm}` (sem lookup de hostname do macOS, 5 s por contexto).
Antes: 31 lookups, 19:02 min (com 1 erro ambiental do Keycloak). Depois: 0 lookups, 5:59 min; na
remedição do Orquestrador, 03:31 min. Em produção o Docker define HOSTNAME por contêiner.
