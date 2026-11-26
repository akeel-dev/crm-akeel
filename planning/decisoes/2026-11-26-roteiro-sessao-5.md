# Roteiro da sessão de estudo 5 do Pipedrive: usuários e permissões

Preparado pelo Orquestrador em 2026-11-26, para o Pedro (spec §14.2). Alimenta o módulo **USR** e a
**P-19**. Revisado no mesmo dia com a pesquisa pública do Pedro ("Pipedrive: visibilidade, permissões e
ciclo de usuários", 26/11): o que ela já responde com documentação oficial **não** é retestado. A sessão
fica com três partes: o inventário da conta real (A), só as lacunas na conta de teste (B) e as decisões (C).

O Pedro decidiu em 26/11 desconsiderar os termos de uso do Pipedrive para estes estudos.

## O que a pesquisa já responde (não retestar)

- Os 4 níveis de "Visível para", seguidores, grupos pai e filho, e o funil bloqueado por grupo (vale mais
  que "Todos").
- Permissões nunca ampliam a visibilidade. Há três camadas: direitos de acesso, conjunto de permissões e
  grupo de visibilidade.
- A lista de permissões do app de negócios e as globais.
- O ciclo do usuário: convite, desativação com transferência, reativação e exclusão (só de desativado).
- Os planos: grupos e conjuntos personalizados só no **Premium** ou superior.
- O que o U2 vê e faz em 17 cenários (cenários 1 a 17 da pesquisa).

## Antes de começar (Pedro)

1. Anotar o plano da conta da Akeel (Cobrança → Gerenciar assinatura).
2. Conta de teste **Premium ou superior** (o teste grátis costuma liberar), com **U1** admin e **U2**
   comum, cada um numa janela. Registros de teste começam com `[S5]`. Nenhum dado real.

Tempo estimado: **1h a 1h30** (A: 20 min; B: 40 a 60 min; C: 20 min).

## A. Inventário da conta real (só leitura)

Nada é alterado. Nenhum nome de pessoa: grupos G1, G2…; conjuntos P1, P2…; funis F1, F2….

**A1. Conta**

| Item | Valor |
|---|---|
| Plano (nome novo ou antigo) | |
| Usuários ativos | |
| Com acesso às configurações da conta | |
| Admins de negócios / admins globais | |
| Convites pendentes / desativados | |

**A2. Grupos** (padrão por tipo: dono, grupo, grupo+sub ou empresa)

| Grupo | Pai | Nº de usuários | Negócio | Lead | Pessoa | Organização | Produto | Funis liberados |
|---|---|---|---|---|---|---|---|---|
| Padrão | | | | | | | | |

**A3. Conjuntos** (abrir em Editar só para ver, sair sem salvar; sim ou não)

| Permissão | Comum | P1 | P2 |
|---|---|---|---|
| Editar negócios de outros | | | |
| Excluir negócios | | | |
| Mudar o dono de negócios | | | |
| Ver quantidade e soma no funil | | | |
| Ver dados de outros usuários | | | |
| Seguir outros usuários | | | |
| Ver nomes de itens que não pode acessar | | | |
| Mudar a visibilidade de itens | | | |
| Estatísticas de outros e da empresa | | | |
| Exportar listas / edição em massa | | | |
| Excluir atividades | | | |

**A4. Distribuição:** quantos usuários em cada par grupo × conjunto.

## B. Lacunas, na conta de teste

Só o que a pesquisa não respondeu ou deixou contraditório.

| # | Caso | O que observar | Resultado |
|---|---|---|---|
| B1 | U2 é dono de um negócio num funil que U1 bloqueia para o grupo de U2 | U2 ainda vê o próprio negócio? (a pesquisa se contradiz) | |
| B2 | Nota ligada a um negócio que U2 vê e a uma pessoa que U2 não vê | A nota aparece inteira, oculta ou some? | |
| B3 | U2 sem permissão tenta excluir negócio, exportar, editar em massa, mudar dono | O controle **some**, fica **desabilitado** ou dá **erro**? | |
| B4 | U1 tira uma permissão de U2 com U2 logado | Vale na hora ou só ao recarregar ou entrar de novo? | |
| B5 | U1 desativa U2 com negócios, contatos e atividades | Dá para escolher um destino diferente por tipo de item? | |
| B6 | U1 reativa U2 | O que volta sozinho (grupo, conjunto, itens não transferidos, automações) | |
| B7 | U1 menciona U2 numa nota de um negócio que U2 não vê | U2 recebe notificação? Com que conteúdo? | |
| B8 | Grupo de U2 com acesso ao funil, mas sem nenhum negócio visível nele | O funil aparece vazio ou some? | |
| B9 | Com as duas janelas abertas, U1 move um negócio (Q-009) | U2 vê sem recarregar? Em quanto tempo? | |

## C. Decisões do Pedro

Cada linha tem a recomendação do Orquestrador. Basta "aceito" ou a sua escolha.

| # | Ponto | Pipedrive | Nossa spec hoje | Recomendação | Sua decisão |
|---|---|---|---|---|---|
| C1 | Seguir um **usuário** (ver todos os itens dele) | existe, com permissão própria | não existe | Fora da v1: abre visibilidade por uma porta lateral | |
| C2 | Padrão de "Visível para" | por grupo e por tipo de item | um padrão da empresa | Manter o da empresa na v1 | |
| C3 | Nota ou atividade ligada a vários itens | exige ver **todos** os ligados | herda do item | Adotar a regra do Pipedrive (mais segura) | |
| C4 | Dono num funil bloqueado para o grupo dele | contraditório (B1) | ambíguo | Dono sempre vê o que já é dele; o sistema não deixa atribuir dono sem acesso ao funil | |
| C5 | Permissões ausentes da §5.5 | mudar a visibilidade, ver nomes de ocultos, ver totais do funil, editar data de ganho/perda | ausentes | Incluir as quatro | |
| C6 | Dois admins (de negócios e global) | existem | um admin | Um admin só | |
| C7 | Conjunto padrão do usuário comum | sem padrão público | Vendedor (§5.5) | Restritivo: edita só os próprios, não exclui nem exporta | |
| C8 | Item ligado oculto | nome ou "oculto", por permissão | — | Mostrar "Item restrito" com "Pedir acesso"; texto nosso | |
| C9 | Notificação de item invisível | não documentado | — | Nunca notificar nem mostrar prévia | |
| C10 | Funil sem acesso / sem negócio visível | oculto / vazio | — | Sem acesso: some; com acesso e nada visível: vazio | |

**P-19: os 4 perfis do Keycloak.** A §5.5 não tem conjunto para Visualizador.

| Perfil | Conjunto no CRM | Recomendação | Sua decisão |
|---|---|---|---|
| `/Perfis/Administradores` | Administrador | Tudo | |
| `/Perfis/Gestores` | Gestor | Vendas com escopo de grupo, relatórios de outros, metas, desconto | |
| `/Perfis/Vendedores` | Vendedor | Criar e editar os próprios (= C7) | |
| `/Perfis/Visualizadores` | **Visualizador (novo)** | Só ver o que a visibilidade deixa; nada de criar, editar, excluir ou exportar | |

E mais duas:
- Um conjunto personalizado fica no perfil do conjunto de origem, porque o perfil só autentica (D-09).
- O admin escolhe o grupo de visibilidade no convite, sem padrão por perfil.

## Entrega

- B: regras a partir de **R-049** em `pipedrive/rules/permissions.md` (Dado/Quando/Então, sem texto
  literal da tela); evidências a partir de **EV-064**, listadas no `index.csv`; registro no
  `pipedrive/sandbox/ledger.csv`; Q-006 e Q-009 fechadas em `pipedrive/questions.md`.
- A pesquisa pública do Pedro vai para `pipedrive/` como fonte da sessão (a pasta é do Pedro).
- A e C: as respostas vão para `planning/decisoes/` com a data; o Orquestrador leva para a spec (§5.4,
  §5.5, §9.1 e P-19), e só então o Planejador fatia o USR.
