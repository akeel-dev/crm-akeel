# Roteiro da sessão de estudo 5 do Pipedrive: usuários e permissões

Preparado pelo Orquestrador em 2026-11-26, para o Pedro (spec §14.2). Alimenta o módulo **USR** e a
**P-19** (mapear os conjuntos de permissões nos 4 perfis). Quem conduz preenche as colunas "Resultado";
o Planejador só fatia o USR depois que as partes A e F estiverem respondidas.

## Por que esta sessão

O estudo de outubro foi feito com **um usuário só** (um administrador). Tudo o que depende de um segundo
usuário ficou "não testado" (`pipedrive/data-model/permissions.md`, Q-006). O que hoje vem só da
documentação: quem edita funis, quem exclui negócios, o que "Dono" esconde, e a visibilidade de funil.

## Antes de começar (Pedro)

1. **Plano da conta.** Na conta real, abra a página de cobrança e anote o plano. Pela documentação
   (`SRC-041`), grupos de visibilidade e conjuntos de permissões **não existem nos planos de entrada**.
   Se o plano da Akeel não os tiver, a parte A fica mais curta, e a conta de teste precisa de um plano
   que os tenha (o teste grátis costuma liberar).
2. **Conta de teste** separada (§14.2: nunca escrever na conta real), com **dois usuários**:
   - **U1**, administrador (quem conduz);
   - **U2**, usuário comum, **sem** permissão de administrador, com outro e-mail (um apelido do mesmo
     e-mail serve, se o Pipedrive aceitar).
3. Dois navegadores ou duas janelas anônimas: U1 numa, U2 na outra. Vários casos são "U1 faz, U2 olha".
4. Nenhum dado real de cliente. Os registros de teste começam com `[S5]`, para achar e apagar no fim.
5. **Quem conduz:** você à mão ou um agente com o Claude in Chrome, com você na tela. Recomendo o agente
   na parte B em diante; a parte A é leitura da conta real e fica melhor com você.

Tempo estimado: **2 a 3 horas** (A: 20 min; B a E: 1h30 a 2h; F: 20 min).

## A. Inventário da conta real (só leitura, P-06)

Não altere nada. Não anote nomes de pessoas: use o papel ("vendedor 1") e as contagens.

| # | O que anotar | Resultado |
|---|---|---|
| A1 | Plano e número de usuários ativos | |
| A2 | Os grupos de visibilidade e a árvore (quem é pai de quem) | |
| A3 | Os conjuntos de permissões existentes e quantos usuários em cada um | |
| A4 | Que funil cada grupo enxerga | |
| A5 | A visibilidade padrão de um negócio novo, de uma pessoa nova e de uma organização nova | |
| A6 | Quem é administrador hoje, e em que se distingue dos demais | |

## B. Usuários (RF-USR-01, RF-USR-08, RF-IAM-04)

| # | Caso | O que observar | Resultado |
|---|---|---|---|
| B1 | U1 convida um usuário | Campos pedidos no convite (grupo? conjunto? papel?) e o estado até o aceite | |
| B2 | U1 desativa U2 com negócios, atividades e contatos de U2 | Oferece transferir? Por tipo ou tudo junto? O que acontece com os itens fechados? | |
| B3 | U1 reativa U2 | U2 recupera os itens, o grupo e o conjunto? | |
| B4 | Um usuário inativo | Aparece nos seletores de dono e de responsável? E nos filtros e relatórios? | |

## C. Conjuntos de permissões (RF-USR-03, §5.5)

| # | Caso | O que observar | Resultado |
|---|---|---|---|
| C1 | Abrir a tela de conjuntos | A lista **completa** de permissões e os conjuntos padrão (anotar em tabela) | |
| C2 | Escopos | A permissão vale só para os itens próprios, para o grupo ou para todos? Onde se escolhe? | |
| C3 | U2 com o conjunto padrão de usuário comum tenta: excluir negócio próprio, excluir negócio de U1, exportar, editar em massa, mesclar contatos, trocar o dono, editar funil, criar campo | Para cada ação: o botão **some**, fica **desabilitado** ou dá **erro** ao clicar? | |
| C4 | U1 tira de U2 uma permissão (ex.: excluir negócio) | Vale na hora para U2, ou só depois de recarregar ou entrar de novo? | |
| C5 | Duplicar e excluir um conjunto em uso | O que acontece com os usuários do conjunto excluído | |

Saída da C1: a tabela "permissão do Pipedrive → chave da §5.5", com "sem correspondente" onde não houver.

## D. Grupos e visibilidade de registros (Q-006, R-048, RF-USR-02, RF-USR-05, RF-USR-06)

Montagem: grupos `[S5] Diretoria` (pai) → `[S5] Comercial` (filho) → `[S5] Time A` (neto), e um irmão
`[S5] Outro`. U1 cria quatro negócios, um em cada nível de "Visível para", cada um com uma pessoa, uma
organização, uma atividade, uma nota e um arquivo. Depois **mova U2 de grupo** e repita o olhar.

| Grupo de U2 em relação ao dono | Dono | Grupo do dono | Grupo e subgrupos | Todos |
|---|---|---|---|---|
| Mesmo grupo | | | | |
| Grupo acima (pai) | | | | |
| Grupo abaixo (filho) | | | | |
| Grupo irmão | | | | |
| U2 seguidor do negócio | | | | |

Em cada célula, anotar onde U2 vê o negócio: quadro, lista, busca, relatório, exportação e as
atividades e notas dele. Depois:

| # | Caso | O que observar | Resultado |
|---|---|---|---|
| D1 | U2 vê o negócio mas não a organização dele (organização com visibilidade "Dono") | O que aparece no lugar da organização | |
| D2 | Atividade de U2 num negócio que U2 não vê | U2 vê a atividade? E o título do negócio? | |
| D3 | Criar, mover e excluir grupos | Profundidade máxima; excluir grupo com usuários é recusado? Um usuário pode estar em dois grupos? | |
| D4 | Quem vira seguidor automaticamente ao criar um negócio | O criador? O dono? | |

## E. Funis, dono e tempo real (RF-USR-04, RF-USR-07, Q-009)

| # | Caso | O que observar | Resultado |
|---|---|---|---|
| E1 | U1 cria um funil novo | Por padrão, U2 vê o funil? | |
| E2 | U1 restringe o funil a um grupo sem U2 | Some do seletor de U2? Os negócios dele somem da busca, da lista e das atividades de U2, mesmo com "Todos"? | |
| E3 | U1 passa um negócio para U2 | U2 recebe notificação? U1 continua vendo? A visibilidade muda? | |
| E4 | U2 sem permissão de trocar o dono | O que a tela mostra | |
| E5 | Com as duas janelas abertas, U1 move um negócio e U2 olha o quadro | Aparece sem recarregar? Em quanto tempo? | |

## F. Decisão da P-19: os 4 perfis

O Keycloak tem quatro perfis (§5.2): Administradores, Gestores, Vendedores e Visualizadores. A §5.5 tem
três conjuntos padrão, e **falta o do Visualizador**. Com A e C respondidas, confirme ou corrija:

| Perfil no Keycloak | Conjunto no CRM | Recomendação do Orquestrador | Sua decisão |
|---|---|---|---|
| `/Perfis/Administradores` | Administrador | Tudo (§5.5) | |
| `/Perfis/Gestores` | Gestor | Vendas com escopo de grupo, relatórios de outros, metas, aprovação de desconto (§5.5) | |
| `/Perfis/Vendedores` | Vendedor | Criar e editar os próprios; sem exclusão em massa nem exportação (§5.5) | |
| `/Perfis/Visualizadores` | **Visualizador (novo)** | Só ver o que a visibilidade deixa; nenhuma criação, edição, exclusão ou exportação | |

Mais duas perguntas:
1. **Um conjunto personalizado** (ex.: um vendedor que exporta) fica em qual perfil do Keycloak?
   Recomendo: no perfil do conjunto de origem, porque o perfil só autentica (D-09) e não autoriza nada.
2. **O grupo de visibilidade padrão** de um convidado novo: vem do perfil ou o admin escolhe no convite?
   Recomendo: o admin escolhe no convite (RF-USR-01), sem padrão por perfil.

## Entrega (mesmo formato do estudo de outubro)

- **Regras** a partir de **R-049**, em `pipedrive/rules/permissions.md`, no formato Dado/Quando/Então,
  descrevendo o comportamento, sem copiar textos da tela.
- **Evidências** a partir de **EV-064**, em `pipedrive/evidence/`, listadas no `index.csv`.
- **Testes de paridade** novos em `pipedrive/clone/parity.md`.
- Atualizar `pipedrive/data-model/permissions.md` e `pipedrive/topics/visibility-and-permissions.md`;
  fechar Q-006 e Q-009 em `pipedrive/questions.md`.
- Registrar no `pipedrive/sandbox/ledger.csv` o que foi criado na conta de teste.
- A decisão da parte F vai para `planning/decisoes/` com a data; o Orquestrador leva para a spec (P-19).

`pipedrive/**` e a spec são do Pedro (`time.yml`). Se um agente conduzir, ele só escreve aí com a sua
autorização para esta sessão.
