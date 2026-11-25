# Atalhos e limites declarados

Dono: Arquiteto. Atualizado: 2026-11-25 (backend `c07d095`, frontend `63752e9`).

Pela regra `decisoes §17`, nenhum atalho vai em comentário `shortcut:` no código. Este arquivo
reúne os que hoje estão só em `reviews/`, `planning/decisoes/` e nos ADRs. Cada linha cita a
fonte; nada aqui é decisão nova. Quando um gatilho acontecer, a decisão volta para quem a tomou.

## Backend

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| `mail_delivery.id` gerado com `UUID.randomUUID()` (v4); a spec §6.1 pede UUIDv7 gerado na aplicação. **Em correção dentro da 0-11** | Não é atalho a manter: corrigir para v7 antes da 0-12 (ADR 0002 também pede v7) | `reviews/0-11.md` N2 e "Os atalhos declarados"; `planning/decisoes/2026-11-24.md` §27 |
| `MAIL_EHLO_NAME` sem validação na subida em `prod`: sem a variável, a aplicação sobe e o EHLO sai com o texto literal `${MAIL_EHLO_NAME}`; a falha só aparece no envio, ~25 min depois | Fica com o DevOps (validação e documentação da variável), antes do primeiro deploy com relay real | `reviews/0-11.md` N3, P1 e "Os atalhos declarados" |
| Intervalo padrão de e-mail de 5 min (`crm.mail.retry-interval: PT5M`): com 5 novas tentativas, a janela é ~25 min; queda do relay maior que isso leva a mensagem a FAILED, sem reprocessamento | A spec não fixa intervalo; configurável por `crm.mail.retry-interval`. Rever quando existir reprocessamento (fora da 0-11) ou queda do relay maior que a janela | `reviews/0-11.md` "Os atalhos declarados" |
| E-mail "ao menos uma vez": duplica se o banco falhar entre o `send` e o `update`, e (por leitura, não medido) se o JVM do worker morrer nesse intervalo | Nenhum dos dois caminhos é exercido por teste; o revisor o julgou aceitável para e-mail do sistema. Nenhum gatilho escrito | `reviews/0-11.md` "Os atalhos declarados" |
| Dois contadores de tentativa que precisam concordar (`mail_delivery.attempts` e `scheduled_tasks.consecutive_failures`), sem teste que os compare; se o `update` do `catch` falhar, a mensagem pode ficar PENDING com o job já desistido | "Aceitável na fundação"; nenhum gatilho escrito | `reviews/0-11.md`, decisão 1, N1 e N7a |
| Comando de verificação do relay é um segundo worker completo (Tomcat, agendador, espera sem prazo): porta da saúde ocupada no contêiner do worker e espera de ~25 min no pior caso | Antes de o DevOps rodá-lo no contêiner do worker na VPS | `reviews/0-11.md` N4 e decisão 4 |
| `starttls.required: true` fixo em `prod`: a homologação com capturador precisa de um capturador com STARTTLS | Montagem da homologação (0-04) | `reviews/0-11.md` N9 |
| Saúde de e-mail do Actuator desligada (`management.health.mail.enabled: false`): só o `worker` tem saída para a 587, e a fila já trata a queda do relay. Nada a guarda nesta máquina | Nenhum gatilho escrito; o revisor registra a falta de guarda | `reviews/0-11.md` N5 e decisão 2 |
| Indicador do db-scheduler do starter desligado (`management.health.db-scheduler.enabled: false`); no `worker`, a saúde usa o indicador próprio `workerScheduler` (corrigido) e no `api` fica 200 | Observabilidade (RNF-12) ou `HEALTHCHECK` do DevOps (0-04) | `reviews/0-10.md` N1 e reconferência |
| Tarefa do db-scheduler esgotada fica na tabela com `execution_time` 9999-12-31, sem purga: as linhas acumulam e o par (`task_name`, `task_instance`) continua ocupado | Reenvio manual com o mesmo id (medir o que `SchedulerClient.schedule` faz) ou volume da tabela | `reviews/0-10.md` N3 e ponto 3 do Dev |
| `/v3/api-docs` anônimo em qualquer perfil | A primeira story do módulo API (RF-API), ou qualquer rota que não deva ser divulgada | `planning/decisoes/2026-11-24.md` §26; `reviews/0-08.md` N4; `reviews/0-09.md` N3 |
| CSRF no modo simples (`CsrfTokenRequestAttributeHandler`), sem a máscara XOR contra BREACH; o sair manda o `_csrf` cru. Trocar para `csrf.spa()` quebra o sair sem teste do front acusar | O token passar a ir em HTML ou em corpo de resposta; achado de pentest/ASVS (RF-SEC-07) | `planning/decisoes/2026-11-24.md` §22; ADR 0003; `reviews/0-19.md` N2 |
| Falha da renovação do token, por qualquer motivo (inclusive Keycloak fora do ar), derruba a sessão do CRM | A TI relatar quedas do Keycloak | `planning/decisoes/2026-11-24.md` §22 |
| Tokens do Keycloak na sessão sem cifra de aplicação | Token que vale sem o segredo do cliente (ex.: Google); `offline_access`; leitura do banco por outro além da aplicação (ex.: réplica de BI); achado de pentest/ASVS | ADR 0003 decisão 6; `planning/decisoes/2026-11-24.md` §11 |

## Frontend

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| `overrides` do openapi-typescript força o TypeScript 6 (o 7.13.0 declara `typescript ^5.x` no peer) | Uma versão do openapi-typescript aceitar o TS 6 no peer, ou o gerador produzir tipos errados | `planning/decisoes/2026-11-24.md` §23; `reviews/0-18.md` N1 |
| A sessão nunca é relida (`staleTime: Infinity`) e só o 401 de `GET /api/session` leva ao login | A primeira story da Onda 1 que escrever dados | `reviews/0-19.md` N7 |
| Resposta de sessão que não seja 200 nem 401 deixa a casca em branco, sem mensagem nem nova tentativa | O revisor sugere registrar como story ou decisão; nenhum gatilho escrito | `reviews/0-19.md` N6 |
