# Story 0-04 — homologação local (evidência)

Transcrito pelo Orquestrador do relatório do DevOps (2026-11-25, MacBook-Air-de-Maria).

DevOps `ddabcb5` + `a54224a` (workflow só manual, §28). Projeto compose `crm-akeel-homologacao`
(proxy `127.0.0.1:18080`, Keycloak `keycloak.localhost:18180`, Mailpit `18025`).

- ✅ `sh deploy/deploy.sh homologacao-local` do zero: exit 0. Ordem: infraestrutura → migração ok →
  CORS do bucket ok → api e worker → frontend e proxy. Critérios 8 (4 prefixos, cookie host-only, sem CORS),
  9 (Host e X-Forwarded-Proto/Port), 10 (segredo em /run/secrets), 11 (e-mail prod no Mailpit) ok.
- ✅ e2e contra a homologação (`deploy/homologacao/e2e.sh`): 8 passed.
- ✅ actionlint: exit 0. Remedição do Orquestrador: `deploy/homologacao/verificar.sh` exit 0 (12 ok).

| Crit. | Sabotagem (em cópia) | Resultado |
|---|---|---|
| 2 | migração inválida numa imagem de teste | exit 1, nenhuma instância trocada; as que estavam de pé seguem respondendo |
| 9a | proxy sem `Host` | exit 1, `redirect_uri` com host interno |
| 9b | proxy sem `X-Forwarded-Proto` | exit 1, `redirect_uri` com `http://` |
| 11 | worker sem desligar STARTTLS | exit 1 em 618 s, FAILED com 6 tentativas, 0 mensagens |
| 6 | contrato com 1 byte diferente | exit 1 |

Pendências do deploy real: `docs/operacao/deploy.md`. Achado aberto: a URL pré-assinada aponta para o
endpoint interno do Garage (`decisoes §28`).
