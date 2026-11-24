# ADR 0002 — O `api` grava o evento na `outbox_event`; só o `worker` o repassa ao Spring Modulith, que rastreia a entrega por consumidor

Dono: Arquiteto. Data: 2026-11-24. Estado: aceito pelo humano em 2026-11-24 (planning/decisoes/2026-11-24.md §11)

Responde a **Q-ARQ-1** da Onda 0 (trava a story 0-12).

## Contexto

A spec: toda mudança relevante grava um evento **na mesma transação**, "na tabela
`outbox_event` (ou no registro de publicação do Spring Modulith)", e **o `worker`
distribui** (§4.4, §0.4 princípio 3); `api` e `worker` são processos separados do
mesmo artefato (§4.1, D-03). Envelope: `id` UUIDv7, `type` `entidade.ação`,
`occurred_at`, `actor`, `entity_type`, `entity_id`, `payload`, `correlation_id`
(§4.4, §10.1). ADR 0001: jobs no db-scheduler, que só executa no `worker`.

**O que o Spring Modulith 2.2.0 de fato faz** (lido em 2026-11-24):

| Fato | Evidência |
|---|---|
| O registro grava uma publicação por listener transacional **que o processo que publica encontra** | docs.spring.io/spring-modulith/reference/events.html, "The Event Publication Registry" ("finds out about the transactional event listeners that will get the event delivered and writes entries for each of them"); código: `PersistentApplicationEventMulticaster.java` na tag `2.2.0`, linhas 98–111 |
| Uma `condition` falsa no listener **não** suprime só a execução: suprime também a gravação (a condição é avaliada antes de gravar) | mesmo arquivo, linhas 98 e 174 (`matches` → `shouldHandle`) |
| A reentrega (`FailedEventPublications.resubmit`, `IncompleteEventPublications`) procura o listener **no processo que reentrega**; se não acha, registra "Listener … not found! Skipping invocation" | `DefaultFailedEventPublications.java`, tag `2.2.0`, linhas 155–161 |
| Toda publicação gravada fica num mapa em memória (`PublicationsInProgress`) até o listener concluir ou falhar **naquele processo** | `DefaultEventPublicationRegistry.java`, tag `2.2.0`, linhas 105 e 170 |
| A reentrega reivindica cada publicação com uma troca de estado condicional (`markResubmitted` devolve `false` se outro já pegou) | idem, linha 369 |
| Estados desde 2.0: `PUBLISHED`, `PROCESSING`, `COMPLETED`, `FAILED`, `RESUBMITTED`, `ABANDONED` (2.2); o monitor de *staleness* passa `PUBLISHED`/`PROCESSING`/`RESUBMITTED` antigos para `FAILED`, e só liga se `spring.modulith.events.staleness.*` > 0 | events.html, "Event Publication Lifecycle", "Event Publication Staleness"; docs.spring.io/spring-modulith/reference/appendix.html, Apêndice B |
| `republish-outstanding-events-on-restart`: "Usually not recommended in multi-instance deployments" | appendix.html, Apêndice B |
| A externalização fala com Kafka, AMQP, JMS ou um `MessageChannel` do próprio processo; o modo `outbox` (2.1+) delega ao Namastack Outbox ou ao JobRunr | events.html, "Externalizing Events", "Supported Infrastructure", "Namastack Outbox Support", "JobRunr Outbox Support" |

Fontes do código: `https://github.com/spring-projects/spring-modulith/tree/2.2.0/spring-modulith-events/spring-modulith-events-core/src/main/java/org/springframework/modulith/events/`
(`support/PersistentApplicationEventMulticaster.java`, `core/DefaultEventPublicationRegistry.java`,
`core/DefaultFailedEventPublications.java`).

**Leitura:** o registro sozinho não atravessa processos. Se o `api` publica um evento
Spring, ou ele conhece os listeners e os executa, ou não conhece e não grava nada.

## Decisão

1. **Quem muda estado chama `DomainEvents.publish(envelope)`** (em
   `br.com.akeel.crm.platform.events`), que faz um `INSERT` em `outbox_event` (jOOQ) na
   transação corrente, com propagação `MANDATORY` (sem transação, falha). As colunas são
   os campos da §4.4 mais `relayed_at` (nulo até o repasse). Vale para `api` e `worker`:
   **ninguém** publica evento de domínio direto no `ApplicationEventPublisher`.
2. **O repasse é uma tarefa recorrente do db-scheduler** (portanto só no `worker`, ADR
   0001 decisão 4), registrada em `platform.jobs` e delegando a `platform.events`: lê
   lotes de `outbox_event` com `relayed_at IS NULL ORDER BY id FOR UPDATE SKIP LOCKED`,
   e, **numa transação por lote**, publica cada envelope no `ApplicationEventPublisher`
   do `worker` e marca `relayed_at`. O registro do Modulith grava, nessa mesma transação,
   uma publicação por consumidor. Intervalo inicial: 1 s.
3. **Consumidores são `@ApplicationModuleListener`** (assíncronos, transação própria,
   registrados). Depois do commit do repasse, o `worker` os executa; cada um tem a sua
   publicação, então a falha de um não reexecuta os outros.
4. **Novas tentativas, só no `worker`:**
   - outra tarefa recorrente do db-scheduler chama
     `FailedEventPublications.resubmit(ResubmissionOptions.defaults().withMinAge(…))`;
   - `spring.modulith.events.staleness.published`/`.processing`/`.resubmitted` > 0
     **só no perfil `worker`** (no `api` ficam zero e o monitor não sobe), para que uma
     publicação órfã de um `worker` que morreu vire `FAILED` e seja reentregue;
   - `republish-outstanding-events-on-restart` fica `false`;
   - sem `AbandonPolicy` por ora (padrão 2.2: nunca abandona).
5. **Tabelas pelo Flyway:** `outbox_event` e `event_publication` (o esquema PostgreSQL do
   apêndice D da doc), com `spring.modulith.events.jdbc.schema-initialization.enabled=false`.
   `completion-mode` fica no padrão `update`. Purga das duas: fora da 0-12.
6. **Entrega pelo menos uma vez, sem ordem garantida.** Consumidor com efeito fora do
   banco (webhook, e-mail) tem de ser idempotente pelo `id` do envelope.

O `api` nunca grava em `event_publication` e nunca executa consumidor: os listeners
existem no contexto dele (mesmo artefato), mas nada ali os aciona.

## Alternativas consideradas

| Alternativa | Por que não agora | Gatilho que a faria valer |
|---|---|---|
| **O `api` executa os consumidores** (o padrão do Modulith, a mais barata) | Contraria a §4.4 ("o `worker` distribui") e a §4.1 (job pesado não afeta a interface). É decisão da spec | O Pedro mudar a §4.4 |
| **Os mesmos listeners nos dois processos, o `api` suprimindo a execução** (executor `@Async` que descarta no `api`, ou um aspecto antes do `CompletionRegisteringAdvisor`) | (a) `condition` não serve: suprime a gravação junto; (b) cada publicação gravada no `api` fica para sempre no `PublicationsInProgress` do `api` (vazamento de memória, linhas 105/170); (c) depende da ordem entre o interceptor de `@Async` e o de conclusão (`HIGHEST_PRECEDENCE + 10`), que não é contrato público | O Modulith oferecer um modo "gravar sem executar" documentado |
| **Externalização do Modulith para Kafka/AMQP/JMS** | Exige um broker: infraestrutura nova na VPS para ~50 usuários | Volume ou número de consumidores externos que o PostgreSQL não aguente |
| **Modo `outbox` com Namastack Outbox** (2.1+) | Biblioteca nova, pensada para externalizar a sistemas de fora, não para entregar a listeners de módulo do mesmo artefato; não conferi o modelo de entrega por consumidor dela | Precisarmos de ordem por chave ou de partição entre vários `worker` |
| **Modo `outbox` com JobRunr** | ADR 0001 escolheu db-scheduler | ADR 0001 trocar para JobRunr |
| **`outbox_event` com rastreio de entrega por consumidor próprio** (sem o registro do Modulith) | Reescreve o que o registro já dá: estado por consumidor, falha, reentrega, abandono | O registro do Modulith atrapalhar (ex.: mudança de esquema que não queiramos seguir) |
| Despertar o repasse por `LISTEN/NOTIFY` em vez de varrer a cada 1 s | Varredura de 1 s cabe na RNF-05 (< 2 s) no papel; não medido | Medição da RNF-05 acima da meta |

## Guardado por

| Regra | Teste que fica vermelho | Comando |
|---|---|---|
| Só `platform.events` publica no `ApplicationEventPublisher` (ninguém pula a `outbox_event`) | `ArchitectureTest`: nenhuma classe fora de `..platform.events..` chama `ApplicationEventPublisher.publishEvent` nem depende de `ApplicationEventPublisher` | `comandos.arquitetura` |
| Consumidor de evento de domínio é assíncrono e registrado | `ArchitectureTest`: todo método cujo parâmetro é o envelope de domínio e que tem `@EventListener`/`@TransactionalEventListener` (meta-anotado) é `@ApplicationModuleListener` | `comandos.arquitetura` |
| db-scheduler continua só em `platform.jobs` (ADR 0001) | regra já existente do `ArchitectureTest`: as tarefas de repasse e de reentrega são registradas em `platform.jobs` | `comandos.arquitetura` |
| **O `worker` entrega; o `api` não** | Teste de integração da 0-12 (QA): dois contextos, perfil `api` e perfil `worker`, no mesmo PostgreSQL de Testcontainers; o `api` publica; o consumidor de teste conta **0** no `api` e **1** no `worker`; `event_publication` só ganha linhas depois do repasse | `comandos.suite` |
| Mesma transação | Teste da 0-12: rollback não deixa linha em `outbox_event`; `DomainEvents.publish` fora de transação lança exceção | `comandos.suite` |

As duas regras de `ArchitectureTest` são escritas pelo Arquiteto na 0-12, com
sabotagem registrada (publicar direto do `ApplicationEventPublisher` num pacote de módulo
de teste; consumidor com `@EventListener` simples).

## Consequências para o time

- Nenhuma mudança em `time.yml`.
- **0-12 muda** (o Planejador reescreve antes do despacho do QA): ver o retorno ao
  Orquestrador.
- Dev: `spring-modulith-starter-jdbc` (ou `-events-jdbc` + `-events-jackson`),
  `spring-modulith-events-api`; migração com `outbox_event` e `event_publication`;
  perfis `api` e `worker` diferem nas propriedades de *staleness*.
- Tempo real (§4.4, RF-UI-05), quando vier: o consumidor no `worker` faz `NOTIFY`, e os
  `api` (que seguram as conexões SSE) fazem `LISTEN`. Não muda esta decisão.
