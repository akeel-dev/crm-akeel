# Atalhos e limites declarados

Dono: Arquiteto. Atualizado: 2026-11-25, portão da Onda 0 (backend `46e767a`, frontend `63752e9`).

Pela regra `decisoes §17`, nenhum atalho vai em comentário `shortcut:` no código. Este arquivo
reúne os que estão em `reviews/`, `planning/decisoes/`, `planning/arquivo/`, `planning/FILA.md`
e nos ADRs. Cada linha cita a fonte; nada aqui é decisão nova. Quando um gatilho acontecer, a
decisão volta para quem a tomou. Todo atalho tem gatilho; os que faltavam foram definidos pelo
Orquestrador em §30 e §31.

## Backend: e-mail, jobs e sessão (0-08 a 0-11)

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| ~~`mail_delivery.id` com UUID v4~~. **Corrigido:** em `46e767a`, `platform.mail` usa `platform.ids.IdGenerator` (UUIDv7) e não há `randomUUID` em `platform.mail` (grep) | Fechado | `reviews/0-11.md` N2; `planning/decisoes/2026-11-24.md` §27 |
| `MAIL_EHLO_NAME` sem validação na subida em `prod`: sem a variável, a aplicação sobe e o EHLO sai com o texto literal `${MAIL_EHLO_NAME}`; a falha só aparece no envio, ~25 min depois | Fica com o DevOps (validação e documentação da variável), antes do primeiro deploy com relay real | `reviews/0-11.md` N3, P1; `planning/FILA.md` passo 6 |
| Intervalo padrão de e-mail de 5 min (`crm.mail.retry-interval: PT5M`): com 5 novas tentativas, a janela é ~25 min; queda do relay maior que isso leva a mensagem a FAILED, sem reprocessamento | Quando existir reprocessamento, ou queda do relay maior que a janela | `reviews/0-11.md` "Os atalhos declarados" |
| E-mail "ao menos uma vez": duplica se o banco falhar entre o `send` e o `update`, e (por leitura, não medido) se o JVM do worker morrer nesse intervalo | Quando o CRM mandar e-mail a cliente externo (não só e-mail do sistema), ou no primeiro relato de duplicado | `reviews/0-11.md`; gatilho em `planning/decisoes/2026-11-24.md` §30.1 |
| Dois contadores de tentativa que precisam concordar (`mail_delivery.attempts` e `scheduled_tasks.consecutive_failures`), sem teste que os compare; se o `update` do `catch` falhar, a mensagem pode ficar PENDING com o job já desistido | Na primeira story que mostrar o estado de entrega a um usuário, ou quando a observabilidade (RNF-12) alertar mensagem PENDING com o job já desistido | `reviews/0-11.md` decisão 1, N1, N7a; gatilho em §30.2 |
| Comando de verificação do relay é um segundo worker completo (Tomcat, agendador, espera sem prazo): porta da saúde ocupada no contêiner do worker e espera de ~25 min no pior caso | Antes de o DevOps rodá-lo no contêiner do worker na VPS (na homologação local ele já roda, checagem `[11]`) | `reviews/0-11.md` N4 e decisão 4; `reviews/0-04.md` |
| `starttls.required: true` fixo em `prod` | **Gatilho aconteceu na 0-04:** a homologação local desliga o STARTTLS só em `deploy/homologacao/**`; `MailConfigurationTest` 3/3 guarda que `prod` continua com STARTTLS | `reviews/0-11.md` N9; `reviews/0-04.md` critério 11 |
| Saúde de e-mail do Actuator desligada (`management.health.mail.enabled: false`) | Quando a observabilidade (RNF-12) entrar, com um alerta de fila de e-mail parada no lugar da saúde | `reviews/0-11.md` N5 e decisão 2; gatilho em §30.3 |
| Indicador do db-scheduler do starter desligado (`management.health.db-scheduler.enabled: false`); no `worker`, a saúde usa o indicador próprio `workerScheduler` e no `api` fica 200 | Observabilidade (RNF-12) ou `HEALTHCHECK` do DevOps | `reviews/0-10.md` N1 e reconferência |
| Tarefa do db-scheduler esgotada fica na tabela com `execution_time` 9999-12-31, sem purga: as linhas acumulam e o par (`task_name`, `task_instance`) continua ocupado | Reenvio manual com o mesmo id (medir o que `SchedulerClient.schedule` faz) ou volume da tabela | `reviews/0-10.md` N3 |
| `/v3/api-docs` anônimo em qualquer perfil | A primeira story do módulo API (RF-API), ou qualquer rota que não deva ser divulgada | `planning/decisoes/2026-11-24.md` §26; `reviews/0-08.md` N4; `reviews/0-09.md` N3 |
| CSRF no modo simples (`CsrfTokenRequestAttributeHandler`), sem a máscara XOR contra BREACH; o sair manda o `_csrf` cru | O token passar a ir em HTML ou em corpo de resposta; achado de pentest/ASVS (RF-SEC-07) | §22; ADR 0003; `reviews/0-19.md` N2 |
| Falha da renovação do token, por qualquer motivo (inclusive Keycloak fora do ar), derruba a sessão do CRM | A TI relatar quedas do Keycloak | §22 |
| Tokens do Keycloak na sessão sem cifra de aplicação | Token que vale sem o segredo do cliente (ex.: Google); `offline_access`; leitura do banco por outro além da aplicação; achado de pentest/ASVS | ADR 0003 decisão 6; §11 |
| A `api` responde o 401 de `/api/session` com `Content-Type: application/json;charset=ISO-8859-1`: corpo de erro com acento sairia em Latin-1 | Na story da tela de erro geral (§30, item 4) | `reviews/0-04.md`, nota fora do escopo; gatilho em §31.5 |

## Backend: eventos (0-12)

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| `db-scheduler.polling-interval: 1s` vale para todo o agendador do `worker` (e-mail incluído): uma consulta por segundo por `worker`. Pior caso entre o commit e o início do consumidor perto de 2 s, na borda da RNF-05 (< 2 s); o teste aceita 5 s. Latência real não medida | A medição da RNF-05 passar da meta: despertar o repasse por `LISTEN/NOTIFY` | `reviews/0-12.md` N3; ADR 0002, alternativas; `planning/stories/0-12.md`, fora da story |
| Valores de *staleness* (`PT10M` para `published`/`processing`/`resubmitted`, só no `worker`) e de reentrega (`crm.events.resubmission-interval: PT1M`, `resubmission-min-age: PT5M`) plausíveis, não medidos. Consumidor que passa de 10 min em `PROCESSING` vira `FAILED` e é reexecutado em paralelo (coberto pela idempotência, ADR 0002 decisão 6). A configuração fica partida: staleness em `Map.of` no Java, reentrega no YAML | Quando a observabilidade (RNF-12) entrar, ou no primeiro consumidor de negócio que leve mais de 5 min | `reviews/0-12.md` N4; gatilho em §31.1 |
| Sem `AbandonPolicy` (padrão 2.2: nunca abandona): consumidor que falha sempre é reentregue a cada minuto, sem fim, a partir dos 5 min | Aparecer publicação que falha para sempre | `planning/stories/0-12.md`, fora da story; ADR 0002 decisão 4; `reviews/0-12.md` N4 (b) |
| Sem purga de `outbox_event` e de `event_publication` concluídas | As tabelas crescerem a ponto de pesar | `planning/stories/0-12.md`, fora da story; ADR 0002 decisão 5 |
| Ordem do repasse por `occurred_at, id` (não `id`), com índice parcial; só varredura estável, não ordem global; nenhum teste fixa a ordem | A purga de `outbox_event` entrar e manter a tabela pequena | ADR 0002, emenda de 2026-11-25, item 4; `reviews/0-12.md` N1 |
| A guarda do `ContextReadyStart` é probabilística: só fica vermelha se o repasse rodar antes de os listeners existirem (3 de 3 rodadas hoje) | A sabotagem S10 (`ImmediateStart`) passar verde em alguma rodada: trocar por uma guarda sem tempo | ADR 0002, emenda item 2; `reviews/0-12.md` N2 |
| `correlation_id` gerado com `UUID.randomUUID()` em vez do `IdGenerator`; `WorkerEventStaleness` relê `crm.mode` em vez de usar `RunModes.mode` (dois leitores do mesmo fato; primeiro `spring.factories` do `src/main`) | A primeira story que tocar `platform.events` | `reviews/0-12.md` N5, N6; `planning/FILA.md`, notas da 0-12 |
| O `payload` volta do `jsonb` como `Map<String,Object>`; numa sonda com Jackson fora do Spring, `BigDecimal("1234.50")` voltou `Double` (a §6.1 proíbe `double` em dinheiro). Não medido com o `JsonMapper` do Boot | A primeira story que publicar valor monetário em evento (DEA), com teste disso | `reviews/0-12.md` N8; `planning/FILA.md`, notas da 0-12 |
| **Pré-requisito, não atalho:** `platform.events` e `platform.mail` sem `@NamedInterface`; módulo de domínio que use `DomainEvents` ou `SystemMail` deixa o `ModularityTest` vermelho (medido, `docs/arquitetura/modulos.md`) | A primeira story de negócio que publicar evento ou mandar e-mail expõe o pacote por `@NamedInterface`, como `jobs`, `ids` e `storage` (sem isso, essa story fica vermelha) | `reviews/0-12.md` N9 (reconferência de B1); `docs/arquitetura/modulos.md` (medição do portão); §31.6 |

## Backend: arquivos (0-13)

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| Checksum em `WHEN_REQUIRED` (`requestChecksumCalculation` e `responseChecksumValidation`) em `S3ObjectStorage`: precaução **não medida**. Contra o Garage v2.5.0, `WHEN_SUPPORTED` e o padrão do SDK também passam 5/0; nenhum teste fica vermelho se as linhas saírem; `responseChecksumValidation` não tem efeito (o cliente não faz `GetObject`) | Ao escolher o provedor real de arquivos e backup (P-17), ou na primeira atualização maior do AWS SDK | `reviews/0-13.md` N4; `planning/FILA.md` passo 8; gatilho em §31.2 |
| `url-connection-client` acrescentado com `.httpClientBuilder(UrlConnectionHttpClient.builder())`, sem necessidade medida: sem ele, 5/0 verde. Os dois clientes síncronos vão no jar (`apache5-client` + `httpclient5` viajam mortos) | Ao escolher o provedor real de arquivos e backup (P-17), ou na primeira atualização maior do AWS SDK | `reviews/0-13.md` N5; `planning/FILA.md` passo 8; gatilho em §31.2 |
| `exposeHeaders("ETag")` no CORS do bucket é necessário ao multipart do navegador, mas nenhum teste o guarda (o teste faz só o pré-voo) | Na primeira story com upload pelo navegador, que passa a testá-lo | `reviews/0-13.md` N6; gatilho em §31.3 |
| `ObjectStorage` é interface com uma implementação só (o S3 troca por configuração, não por implementação); fica por dar nome estável ao `@NamedInterface("storage")` | Quando houver uma segunda implementação, ou no portão da Onda 1: se nada novo a usar como interface, vira classe | `reviews/0-13.md` N7 (observação do Ponytail); gatilho em §31.4 |

## Deploy e homologação (0-04)

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| Workflow de deploy só por `workflow_dispatch` | Liberação do deploy real pelo Pedro: religar o `push` é passo da liberação | `planning/decisoes/2026-11-24.md` §28; `docs/operacao/deploy.md`, pendências |
| **Troca com parada:** ≈ 11 s de 502 enquanto `api` e `worker` são trocados (medido: 36 respostas 502 seguidas); sem volta à tag anterior se a `api` nova não subir. RNF-13 pede "sem parada perceptível" | Antes da liberação do deploy real: troca sem parada e volta automática | `reviews/0-04.md` N1; §29.1 |
| **Backup sem caminho em produção:** `backup.sh` e `restaurar.sh` chamam `docker compose` sem `-p/-f`; o projeto `crm-akeel-producao` não tem o serviço `backup-arquivos` | Antes da liberação do deploy real | `reviews/0-04.md` N2; §29.2 |
| **URL pré-assinada interna:** aponta para `CRM_STORAGE_ENDPOINT` (`http://garage:3900`), que o navegador não alcança; o host entra na assinatura SigV4, então o proxy não pode reescrevê-lo. A checagem `[arquivos]` mede o pré-voo de dentro da rede e não prova upload do navegador. Um quinto prefixo no proxy sai da spec §5.1 (pode pedir `conflitos/`) | Antes da primeira story com upload pelo navegador, e antes da liberação do deploy real. Decisão do Arquiteto | `reviews/0-04.md` N3; §28; §29.3; `docs/operacao/deploy.md`, pendências |
| **Produção não recebe a imagem homologada:** reconstrói as imagens na VPS (`git archive \| docker build`), ao lado da produção de pé; as bases do `frontend/Dockerfile` sem digest | Antes da liberação do deploy real: registro de imagens e bases por digest | `reviews/0-04.md` N4; §29.4; `docs/operacao/deploy.md` ("Registro de imagens") |
| e2e no runner Linux depende de `*.localhost` resolver para o loopback; conferido só no macOS | Antes da liberação do deploy real (o workflow nunca rodou) | `reviews/0-04.md` N7; §29.5 |
| Ambiente `producao` no GitHub sem revisores: o critério de aprovação manual vale só no papel | Antes do primeiro job de produção (pendência de `deploy.md`) | `reviews/0-04.md` N8; `docs/operacao/deploy.md`, pendências |
| `shellcheck` dá 17 avisos, todos falso positivo ou intencionais; nenhum `.shellcheckrc` | Quando um CI passar a rodar o `shellcheck` | `reviews/0-04.md` N5 |

## Frontend

| Atalho ou limite | Gatilho para rever | Onde está registrado |
|---|---|---|
| `overrides` do openapi-typescript força o TypeScript 6 (o 7.13.0 declara `typescript ^5.x` no peer) | Uma versão do openapi-typescript aceitar o TS 6 no peer, ou o gerador produzir tipos errados | §23; `reviews/0-18.md` N1 |
| A sessão nunca é relida (`staleTime: Infinity`) e só o 401 de `GET /api/session` leva ao login | A primeira story da Onda 1 que escrever dados | `reviews/0-19.md` N7 |
| Resposta de sessão que não seja 200 nem 401 deixa a casca em branco, sem mensagem nem nova tentativa | A primeira story da Onda 1 com tela (uma tela de erro geral com nova tentativa), junto com a sessão nunca relida | `reviews/0-19.md` N6; gatilho em §30.4 |

As referências `§nn` sem arquivo são de `planning/decisoes/2026-11-24.md`.
