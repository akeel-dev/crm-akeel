# FILA — crm-akeel

Dono: Orquestrador. Diz **qual é a próxima ação e de quem ela é**. Limite:
`limites.fila_linhas` do `time.yml`; no portão, as seções velhas vão para
`planning/arquivo/`.

Como saber que esta FILA está velha: a data da ⛳ mais nova é anterior ao último
commit de outro papel. Nesse caso, o artefato datado vence.

---

## 2026-11-25 (17:40) — ⛳ LEIA ESTA SEÇÃO PRIMEIRO

**Onde paramos:** **a Onda 0 (fundação) fechou** no portão de 25/11 (ver "Fechamento" em
`planning/ondas/onda-0.md`). As seções antigas desta fila estão em `planning/arquivo/FILA-onda-0.md`.
Nenhum agente rodando. Tudo commitado e publicado nos três repositórios.

**Última medição (portão, 25/11 17:30, macOS):** `comandos.suite` exit 0 (backend 177/177 em `46e767a`,
frontend 239/239 em `63752e9`), arquitetura 16/0, e2e 8/8 na homologação local.

### Para mostrar ao humano

**Decisão pendente com o Pedro (com recomendação):**
- **Começar a Onda 1?** Recomendo: sim, pelo núcleo de vendas na ordem do roteiro (IAM → USR, PIP → DEA →
  ACT, BRD, TRS). O primeiro passo é o Planejador fatiar a Onda 1 a partir da spec (os módulos ✅ primeiro).
  **USR (permissões) depende da sessão de estudo 5 do Pipedrive e do mapeamento da P-19** — ver abaixo.

**Só o Pedro pode fazer (não bloqueia o fatiamento):**
- sessões de estudo do Pipedrive (spec §14.2) — a **5 (permissões)** e a **1 (contatos e campos)** primeiro;
- P-19: mapear os conjuntos de permissões nos 4 perfis do Keycloak;
- com a Akeel: P-07 (prazo), P-01–P-06, provedor do backup no Brasil (P-17);
- liberar o deploy real quando quiser (§24; condições em §29);
- antes da produção: trocar os secrets do Keycloak e revogar o token antigo do GitHub.

### Próxima ação de cada papel

| Papel | Próxima ação | Bloqueada por |
|---|---|---|
| planejador | fatiar a **Onda 1** (núcleo de vendas) | o "sim" do Pedro |
| orquestrador | `/colher` (consolidar lições novas na `COLHEITA.md`) | o "sim" do Pedro |
| demais | — | Onda 1 fatiada |

### Notas que a Onda 1 precisa herdar

- Expor `platform.events` e `platform.mail` com `@NamedInterface` na primeira story que os usar (`decisoes §31`).
- Dinheiro em payload de evento: teste de `BigDecimal` (`reviews/0-12.md` N8).
- Tela de erro geral e sessão relida (`decisoes §30`, item 4).
- Rodar a suíte do backend com `caffeinate -i`; nunca duas suítes do backend juntas (`COLHEITA.md`).

### Em voo

Nada.
