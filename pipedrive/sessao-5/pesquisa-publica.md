# Pipedrive: visibilidade, permissões e ciclo de usuários

Nov 26, 2026 · @Pedro

## Resumo para o time

Quase tudo o que o pedido queria descobrir com dois usuários numa conta de teste está documentado publicamente pelo Pipedrive. Este documento responde a partir de fontes públicas, sem estudar nenhuma conta: central de ajuda, documentação da API, fórum da comunidade e análises de terceiros.

| Pergunta do pedido | Resposta curta | Seção |
| --- | --- | --- |
| A conta de teste precisa de qual plano? | Premium ou superior. Lite e Growth não têm grupos de visibilidade nem conjuntos de permissões personalizados; o Premium tem 15 de cada desde a mudança de planos de 2025 | Planos e limites |
| Como funcionam U1 (admin) e U2 (comum)? | Três camadas: direitos de acesso (quais apps abre), conjunto de permissões (o que faz) e grupo de visibilidade (o que vê). Admins ignoram a visibilidade | Modelo de visibilidade, Permissões, O que o U2 vê e faz |
| A. Grupos, conjuntos, quem vê qual funil, visibilidade padrão | Cada grupo tem uma lista de funis permitidos e um padrão de visibilidade por tipo de item (negócio, lead, pessoa, organização, produto) | Modelo de visibilidade; roteiro na Parte A |
| B. Convite | Pelo "+ Usuário": e-mails separados por vírgula, prévia, e as permissões ajustadas por usuário antes de enviar. Convites pendentes podem ser cancelados ou reenviados | Ciclo de usuários |
| B. Desativação: oferece transferir os itens? | Sim. A tela lista os itens do usuário para reatribuir. O que não for transferido continua no nome dele. Automações podem ser transferidas (até 100) | Ciclo de usuários |
| B. Reativação | Pela aba "Desativados". Ocupa uma vaga livre, ou cobra uma vaga nova na hora | Ciclo de usuários |

O que ficou sem resposta pública está em "Lacunas e decisões". São pontos pequenos, e a recomendação é o próprio time decidir como o nosso CRM se comporta neles.

## Modelo de visibilidade

A visibilidade é decidida pelo item, não pelo usuário. Cada negócio, lead, pessoa, organização e produto tem um campo "Visível para" com um de quatro níveis. O grupo do dono define o valor padrão desse campo quando o item é criado. O diagrama no fim desta seção mostra a ordem em que as regras se aplicam.

**Níveis de visibilidade** (valores do campo `visible_to` na API pública):

| Valor na API | Planos Premium e Ultimate | Planos Lite e Growth |
| --- | --- | --- |
| 1 | Só o dono (mais seguidores, admins e grupo pai) | Dono e seguidores |
| 3 | Grupo de visibilidade do dono | Empresa inteira |
| 5 | Grupo do dono e seus subgrupos | não existe |
| 7 | Empresa inteira | não existe |

O mesmo número significa coisas diferentes conforme o plano: o 3 é "empresa inteira" nos planos de entrada e "grupo do dono" nos superiores.

**Grupos de visibilidade:**

- Cada usuário pertence a exatamente um grupo. Quem é removido de um grupo volta para o grupo padrão.
- Grupos podem ter grupo pai e subgrupos. Os membros do grupo pai enxergam itens dos grupos abaixo.
- Cada grupo define a visibilidade padrão por tipo de item. Na API isso aparece como `deal_default_visibility`, `lead_default_visibility`, `person_default_visibility`, `org_default_visibility` e `product_default_visibility`.
- "Empresa inteira" num grupo significa que todos veem os itens **dos donos daquele grupo**, e não que os membros do grupo veem tudo.

**Funis por grupo:**

- Por padrão, todos os grupos veem todos os funis.
- Um admin pode desmarcar funis por grupo. O grupo sem acesso não vê nenhum vestígio do funil nem dos negócios dentro dele.
- Isso é mais forte que o "Visível para": mesmo um negócio marcado como "empresa inteira" fica oculto se estiver num funil bloqueado para o grupo.

**Exceções que ampliam o acesso:**

- **Dono:** sempre vê e edita os próprios itens.
- **Seguidor do item:** vê o item mesmo quando a visibilidade restringiria.
- **Seguir um usuário:** quem segue outro usuário vê e é notificado de todos os itens que ele possui, independentemente dos grupos e do "Visível para". Isso depende da permissão "Seguir outros usuários".
- **Admin de negócios:** vê todos os negócios, leads e funis.
- **Admin global:** vê todas as pessoas, organizações e produtos.

**Itens ligados:**

- Notas e atividades só aparecem por inteiro se o usuário tiver acesso a **todos** os itens ligados a elas (negócio, pessoa e organização).
- Arquivos não têm visibilidade própria e seguem o item ao qual estão anexados.
- Um negócio visível pode mostrar a pessoa ou a organização como ocultas. A visibilidade dos contatos ligados também pode impedir buscar o negócio ou mencionar alguém nele.

**Relatórios (Insights):** não têm visibilidade própria e seguem a dos itens. Gráficos e totais continuam aparecendo, mas os registros inacessíveis ficam de fora. Ver dados de outros usuários ou da empresa exige duas permissões específicas (seção seguinte).

&#91;embedded content: ordem de verificação da visibilidade · 4 perguntas\]

O bloqueio de funil vem antes do dono e do "Visível para". Por isso um negócio marcado "empresa inteira" ainda fica oculto num funil bloqueado para o grupo.

## Permissões

Permissões dizem o que o usuário pode fazer nos itens que ele já consegue ver. Elas nunca ampliam a visibilidade: ver um item não dá direito de editá-lo, e o direito de editar itens de outros não mostra itens ocultos.

**Camada 1, direitos de acesso** (quais áreas o usuário abre):

| Direito | O que libera | Requisito |
| --- | --- | --- |
| Configurações da conta | Empresa, cobrança, segurança e gestão de usuários | Nenhum. Sozinho não ocupa vaga paga, mas não dá acesso a negócios nem ao app de celular |
| App de negócios | Funis, leads, negócios, contatos e organizações | Vaga paga |
| Campanhas | E-mail marketing | App de negócios + add-on pago |
| Projetos | Gestão de projetos | App de negócios. Incluído no Premium e acima |

**Camada 2, conjuntos de permissões.** Cada app tem um conjunto admin (tudo liberado, não editável) e um comum (editável). Os personalizados ficam no nível comum. Permissões só mudam pelo conjunto, nunca por usuário individual.

Permissões do app de negócios:

| Grupo | Permissões |
| --- | --- |
| Negócios | Mudar o dono, excluir, converter em lead, mesclar duplicados, editar a data de ganho ou perda |
| Leads | Mudar o dono, mesclar duplicados |
| Visibilidade | Ver a quantidade e a soma de valores no funil e na lista de negócios |
| Criar e editar | Adicionar negócios, editar negócios de outros, adicionar leads, editar leads de outros |

Permissões globais (valem para contatos, Insights, atividades, automações e importações):

| Grupo | Permissões |
| --- | --- |
| Gestão de dados | Criar, editar e excluir campos personalizados; importar planilhas; criar etiquetas; edição em massa; exportar listas |
| Compartilhamento | Compartilhar filtros; editar filtros compartilhados de outros; compartilhar painéis do Insights por link público |
| E-mails | Usar rastreamento de e-mail |
| Visibilidade | Ver estatísticas de outros usuários no Insights; ver estatísticas da empresa; ver dados de outros usuários; seguir outros usuários; ver os nomes de itens e usuários que não pode acessar; mudar a visibilidade de itens |
| Atividades | Excluir atividades |
| Pessoas e organizações | Adicionar; editar as de outros; mudar o dono; excluir; mesclar duplicados |
| Produtos | Mudar o dono; adicionar; editar; excluir; excluir variações de preço |
| Ferramentas | Criar automações; acessar o próprio token de API; criar e importar modelos do Smart Docs |

Três detalhes que afetam o comportamento:

- **Insights:** com as duas permissões de estatísticas ligadas, o usuário vê os dados que a visibilidade permite. Com uma delas desligada, vê só os próprios dados.
- **"Ver os nomes de itens e usuários que não pode acessar":** controla se um item ligado oculto aparece com o nome ou como "oculto". Quando está desligada, aparece uma nota explicando por que o item não é visível.
- **Leads:** quem não tem a permissão de adicionar leads ainda consegue criá-los pelas ferramentas do LeadBooster.

Um post da comunidade anunciou uma permissão nova para restringir quem pode transferir a posse de itens. Ela ainda não aparece na lista oficial acima.

## O que o U2 vê e faz

O U2 é um usuário comum, com acesso ao app de negócios, o conjunto de permissões comum e um grupo de visibilidade (G2). O U1 é admin. A coluna "Base" diz se o comportamento está descrito na documentação oficial ou se é uma dedução a partir dela.

| # | Cenário | O que o U2 vê | O que o U2 pode fazer | Base |
| --- | --- | --- | --- | --- |
| 1 | Item do próprio U2 | Vê sempre | Edita sempre | Documentado |
| 2 | Negócio de outro, "empresa inteira", funil liberado | Vê | Edita só com "Editar negócios de outros" | Documentado |
| 3 | Negócio de outro, "só o dono", U2 não segue | Não vê | — | Documentado (exemplo oficial) |
| 4 | Mesmo negócio, U2 é seguidor dele | Vê | Conforme as permissões | Documentado |
| 5 | U2 segue o usuário dono | Vê todos os itens desse dono, independentemente da visibilidade | Conforme as permissões | Documentado; exige a permissão "Seguir outros usuários" |
| 6 | Negócio "grupo do dono", dono no G2 | Vê | Conforme as permissões | Documentado |
| 7 | Negócio "grupo do dono", dono em outro grupo (G3) | Não vê | — | Documentado |
| 8 | Negócio "grupo e subgrupos", G2 é pai do grupo do dono | Vê | Conforme as permissões | Documentado |
| 9 | Funil bloqueado para o G2 | Não vê o funil nem os negócios dele, mesmo os marcados "empresa inteira" | — | Documentado |
| 10 | Negócio visível, pessoa ou organização ligada invisível | Abre o negócio; o contato aparece com o nome ou como "oculto", conforme a permissão de ver nomes | Buscar o negócio ou ser mencionado nele pode falhar | Documentado (artigos de suporte) |
| 11 | Atividade ou nota ligada a um item invisível | Aparece oculta | — | Documentado |
| 12 | Arquivo anexado a um negócio visível | Vê | — | Documentado (arquivos seguem o item) |
| 13 | Abre o link direto de um negócio oculto | Mensagem de erro de acesso restrito | Pedir para virar seguidor ou falar com um admin | Documentado |
| 14 | Insights | Gráficos e totais aparecem; registros só dos itens acessíveis; sem as duas permissões de estatísticas, só os próprios dados | — | Documentado |
| 15 | Quer mudar o "Visível para" de um item | — | Só com "Mudar a visibilidade de itens" | Documentado |
| 16 | Totais no topo das etapas do funil | Vê a contagem e a soma só com a permissão específica | — | Documentado |
| 17 | Item de um usuário desativado | Segue as mesmas regras; o nome do desativado continua aparecendo | Não consegue atribuir itens novos a ele | Documentado |

Um pedido antigo no fórum da comunidade reclamava que funis sem negócios visíveis apareciam vazios em vez de sumirem. O bloqueio de funil por grupo (cenário 9) resolve isso. No nosso desenho, vale decidir qual dos dois comportamentos queremos como padrão.

## Ciclo de usuários

O usuário passa por quatro estados: convidado, ativo, desativado e excluído. A desativação é reversível e mantém a identidade. A exclusão é permanente e só pode ser feita em quem já está desativado. Todas essas ações exigem o direito "Configurações da conta".

**Convite**

1. Em Gerenciar usuários, clicar em "+ Usuário" e informar um ou mais e-mails separados por vírgula.
2. Clicar em "Prévia". Ao selecionar cada convidado, abre um painel para ajustar direitos de acesso e permissões antes do envio.
3. Quem nunca usou o Pipedrive recebe um e-mail com link para criar a senha. Quem já participa de outra conta recebe um convite para entrar nesta.
4. Os pendentes ficam na aba "Convidados", onde podem ser cancelados, reenviados ou ter as permissões alteradas.
5. O primeiro usuário de uma conta nova já nasce admin, com acesso às configurações da conta.

**Desativação** (Gerenciar usuários → Usuários e acesso → "…" → Desativar)

| O que acontece | Detalhe |
| --- | --- |
| Acesso e vaga | O acesso é removido e a vaga fica livre. Nome, e-mail e foto continuam na conta |
| Transferência de itens | A tela de desativação lista os itens do usuário para reatribuir. A documentação não diz se dá para escolher um novo dono diferente por tipo de item |
| Itens não transferidos | Leads, negócios, contatos, produtos, atividades e projetos continuam no nome dele. Notas e arquivos também |
| Itens novos | Não podem ser atribuídos a um usuário desativado |
| Limpeza posterior | Em Configurações → Uso → Limpeza de dados há um grupo pronto com os itens de usuários desativados: transferir, marcar como ganho ou perdido, ou excluir |
| Automações | Podem ser transferidas a outro admin global (até 100 pela tela de desativação). Uma automação transferida fica pausada até o novo dono reativá-la. Sem transferência, as de "todos os usuários" são pausadas para todos |
| E-mails | Os compartilhados e os modelos ficam. Os privados ligados a itens são apagados depois de 30 dias |
| Filtros | Os públicos ficam. Filtros existentes que citam o usuário continuam funcionando, mas ele não pode ser escolhido em filtros novos do CRM |
| Insights | Painéis compartilhados passam ao primeiro admin da conta; links públicos são desativados; o usuário continua nos relatórios e metas antigos |
| Sincronizações | Agenda, e-mail, contatos e Google Drive param. O link do agendador de reuniões para de funcionar |
| Campanhas | As agendadas são enviadas normalmente |
| Atribuições | Chat ao vivo fica sem responsável; chatbot e formulários passam a outro usuário; regras de distribuição automática falham ao chegar nele |
| Apps e webhooks | Os apps que ele instalou são removidos; os webhooks que ele criou são desativados |
| Cobrança | A cobrança é por vaga ativa. Desativar só reduz o custo se a vaga for removida, a partir da próxima fatura |

**Reativação**

- Aba "Desativados" → "Reativar".
- Se houver vaga livre, ela é ocupada sem mudar a cobrança. Se não houver, uma vaga nova é cobrada na hora.
- A documentação não detalha o que volta automaticamente (automações pausadas, sincronizações, apps removidos). O mais provável é que precisem ser reconfigurados, mas isso não está confirmado.

**Exclusão**

- Só é possível para quem já está desativado: aba "Desativados" → "Excluir usuário".
- Remove nome, e-mail e foto. O usuário passa a aparecer como "(usuário excluído, IDxxxxxxxx)".
- Os itens continuam atribuídos a ele, a menos que sejam transferidos na exclusão. Depois disso ele não pode mais ser escolhido em filtros, então o suporte recomenda transferir antes.
- É irreversível: um usuário excluído não pode ser reativado.

## Planos e limites

Para testar grupos e conjuntos personalizados, o plano mínimo hoje é o Premium. Em 2025 o Pipedrive trocou os planos: Essential virou Lite, Advanced virou Growth, Professional e Power viraram Premium, e Enterprise virou Ultimate. Contas antigas podem continuar no plano anterior, então confira o plano da conta da Akeel em Cobrança → Gerenciar assinatura antes de comparar.

| Plano atual | Grupos de visibilidade personalizados | Conjuntos de permissões personalizados | Opções de "Visível para" |
| --- | --- | --- | --- |
| Lite | Nenhum (só o grupo padrão) | Nenhum (só admin e comum) | 2: dono e seguidores, ou empresa inteira |
| Growth | Nenhum (só o grupo padrão) | Nenhum (só admin e comum) | 2 |
| Premium | 15 | 15 | 4 |
| Ultimate | 25 | 25 | 4 |

Os limites podem ser ampliados com um add-on de gestão de equipe, que soma 10 times, grupos e conjuntos.

Nos planos antigos os limites eram outros: o Professional tinha 3 grupos e 2 conjuntos, o Power tinha 15 grupos e 10 conjuntos, e o Enterprise era ilimitado.

**Contradições encontradas:**

- O artigo "Visão geral de visibilidade e permissões" diz que o Premium tem 2 conjuntos e o Ultimate ilimitados. Esses são os números dos antigos Professional e Enterprise, então o artigo provavelmente está desatualizado. Os artigos sobre a mudança de planos e o de conjuntos de permissões dizem 15 no Premium.
- Os artigos de grupos e de conjuntos citam um plano "Enterprise" com 150 de cada, que não aparece nos preços públicos. Pode ser um plano negociado com vendas. Não confirmado.
- Alguns sites de terceiros dizem que o Lite tem "2 conjuntos de permissões". Isso deve se referir aos dois conjuntos fixos (admin e comum), e não a conjuntos personalizados.

## Parte A: roteiro para o inventário da conta real

A Parte A não precisa de ferramenta nenhuma. É a leitura das configurações da própria conta por alguém com acesso às configurações, em uns 20 minutos. Regras: só leitura, nenhuma alteração e nenhum nome de pessoa ou cliente. Use códigos (G1, G2… para grupos; P1, P2… para conjuntos; F1, F2… para funis).

**1. Conta** (Cobrança → Gerenciar assinatura; Gerenciar usuários → Usuários e acesso)

| Item | Valor |
| --- | --- |
| Plano atual (novo ou antigo) |  |
| Usuários ativos |  |
| Usuários com acesso às configurações da conta |  |
| Admins de negócios |  |
| Admins globais |  |
| Convites pendentes e usuários desativados |  |

**2. Grupos de visibilidade** (Gerenciar usuários → Grupos de visibilidade). Preencha uma linha por grupo; nas colunas de padrão, use: dono, grupo, grupo+sub ou empresa.

| Grupo | Grupo pai | Nº de usuários | Padrão: negócio | Padrão: lead | Padrão: pessoa | Padrão: organização | Padrão: produto | Funis liberados |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Padrão |  |  |  |  |  |  |  |  |
| G1 |  |  |  |  |  |  |  |  |
| G2 |  |  |  |  |  |  |  |  |

**3. Conjuntos de permissões** (Gerenciar usuários → Conjuntos de permissões → "…" → Editar, só para ver; saia sem salvar). Marque sim ou não em cada conjunto.

| Permissão | Comum (negócios) | Comum (global) | P1 | P2 |
| --- | --- | --- | --- | --- |
| Editar negócios de outros |  |  |  |  |
| Excluir negócios |  |  |  |  |
| Mudar o dono de negócios |  |  |  |  |
| Ver a quantidade e a soma no funil |  |  |  |  |
| Ver dados de outros usuários |  |  |  |  |
| Seguir outros usuários |  |  |  |  |
| Ver nomes de itens que não pode acessar |  |  |  |  |
| Mudar a visibilidade de itens |  |  |  |  |
| Ver estatísticas de outros e da empresa no Insights |  |  |  |  |
| Exportar listas |  |  |  |  |
| Edição em massa |  |  |  |  |
| Excluir atividades |  |  |  |  |

**4. Distribuição** (Usuários e acesso). Quantos usuários há em cada combinação de grupo e conjunto, sem nomes.

| Grupo | Conjunto | Nº de usuários |
| --- | --- | --- |
|  |  |  |

Com isso preenchido, o time sabe como a conta real usa o modelo descrito nas seções anteriores, sem precisar de uma conta de teste.

## Lacunas e decisões para o nosso CRM

As lacunas que restam são detalhes de comportamento, e cada uma é uma decisão de produto nossa. A recomendação é decidir e registrar no `01-regras-servidor.md` em vez de buscar a resposta no Pipedrive.

| # | Lacuna | O que se sabe | Sugestão para o nosso CRM |
| --- | --- | --- | --- |
| 1 | Permissões ligadas por padrão no conjunto comum | Não há padrão público; o usuário recebe o que foi definido no convite | Padrão restritivo: editar só os próprios itens, sem excluir nem exportar, sem ver dados de outros. O admin libera o resto |
| 2 | Escolher um novo dono diferente por tipo de item ao desativar | Não documentado | Permitir escolher por tipo (negócios para A, contatos para B), com um destino único como padrão |
| 3 | O que volta ao reativar | Não documentado | Automações e integrações voltam pausadas, com um aviso listando o que precisa ser religado |
| 4 | Notificações sobre itens que o usuário não vê | Não documentado | Nunca notificar nem mostrar prévia de um item invisível para quem recebe |
| 5 | O que aparece no lugar de um item ligado oculto | Nome ou "oculto", conforme uma permissão | Mostrar "Item restrito" com um botão "Pedir acesso". Texto e fluxo nossos |
| 6 | Funil sem negócios visíveis: vazio ou oculto | O bloqueio por grupo oculta o funil inteiro | Ocultar por padrão quando o grupo não tem acesso; mostrar vazio quando tem acesso mas nenhum negócio visível |
| 7 | Plano "Enterprise" com 150 grupos | Não confirmado | Irrelevante para o nosso desenho |

**Modelo de dados sugerido**, a partir dos conceitos públicos (e não de código do Pipedrive):

- `user`: `group_id` (um só), `permission_set_id`, `is_global_admin`, `is_deals_admin`, `status` (convidado, ativo, desativado, excluído).
- `visibility_group`: `parent_id`, padrão de visibilidade por tipo de item, lista de funis permitidos.
- Cada item (negócio, lead, pessoa, organização, produto): `owner_id`, `visible_to` (dono, grupo, grupo e subgrupos, empresa), seguidores.
- `user_follows_user`, para quem segue outro usuário.
- `permission_set`: uma flag por permissão das tabelas da seção Permissões.

**Ordem de verificação no backend:** (1) admin do tipo de item → vê; (2) funil bloqueado para o grupo → não vê; (3) dono, seguidor do item ou seguidor do dono → vê; (4) aplica o `visible_to`; (5) para notas e atividades, exige acesso a todos os itens ligados. Depois de decidir que o usuário vê, as permissões decidem o que ele pode fazer.

**Testes:** cada linha da matriz "O que o U2 vê e faz" vira um teste automatizado do backend, ajustado às decisões acima. Os textos da interface são nossos, sem copiar os do Pipedrive.

## Escopo e fontes

A pesquisa usou só fontes públicas, consultadas em 26/11/2026. Nenhuma conta do Pipedrive foi usada, e nenhuma ferramenta de engenharia reversa (REA, RES, Craft Anything) foi aplicada ao Pipedrive.

- **Por que não testamos numa conta:** os termos de uso do Pipedrive (seção 4.1) proíbem engenharia reversa e usar o serviço para análise competitiva ou para desenvolver um produto concorrente. Isso vale também para contas de teste. Antes de qualquer teste numa conta com esse objetivo, recomendamos uma avaliação jurídica. A própria blueprint do RES marca esse ponto como bloqueio até decisão de um advogado.
- **YouTube:** os vídeos encontrados são os tutoriais oficiais, que já aparecem embutidos nos artigos da central de ajuda. Nenhum trazia informação além deles.
- **Reddit:** não achamos discussões recentes com detalhes sobre esses pontos. As respostas úteis de usuários estão no fórum oficial da comunidade.
- **Atualidade:** a maioria dos artigos oficiais usados foi atualizada entre março e setembro de 2026. Onde um artigo parece desatualizado, isso está apontado na seção Planos e limites.

**Fontes oficiais (central de ajuda do Pipedrive):**

- [Visão geral de visibilidade e permissões](https://support.pipedrive.com/en/article/visibility-and-permissions-overview)
- [Grupos de visibilidade](https://support.pipedrive.com/en/article/visibility-groups)
- [Conjuntos de permissões](https://support.pipedrive.com/article/permission-sets)
- [Gestão global de usuários](https://support.pipedrive.com/en/article/global-user-management)
- [Por que não consigo ver um negócio](https://support.pipedrive.com/en/article/why-can-t-i-see-my-colleagues-deals-in-the-pipeline-view)
- [Por que itens aparecem como ocultos](https://support.pipedrive.com/en/article/why-are-items-shown-as-hidden)
- [Seguidores](https://support.pipedrive.com/article/followers)
- [Insights: visibilidade e permissões](https://support.pipedrive.com/article/insights-visibility-permissions)
- [Como adicionar um usuário](https://support.pipedrive.com/en/article/how-can-i-add-a-user)
- [Usuários: ativos, convidados e desativados](https://support.pipedrive.com/en/article/users)
- [Desativar, reativar ou excluir um usuário](https://support.pipedrive.com/en/article/how-can-i-deactivate-or-reactivate-a-user)
- [O que acontece com os dados de um usuário desativado ou excluído](https://support.pipedrive.com/article/data-deleted-deactivated-user)
- [Itens de usuários desativados (limpeza de dados)](https://support.pipedrive.com/en/article/deactivated-users-data)
- [Novos planos do Pipedrive](https://support.pipedrive.com/en/article/new-pipedrive-plans)
- [Termos de uso](https://www.pipedrive.com/en/terms-of-service)

**API e comunidade:**

- [API: Roles e visibilidade padrão](https://developers.pipedrive.com/docs/api/v1/Roles)
- [Notas de versão da API, fevereiro de 2022 (valores de visible\_to)](https://developers.pipedrive.com/changelog/post/february-2022-release-notes)
- [FAQ de permissões e visibilidade (central Intercom)](https://intercom.help/pipedrive/en/articles/10633271-faq-permissions-and-visibility)
- [Mudanças de planos de 2025 (central Intercom)](https://intercom.help/pipedrive/en/articles/11769539-understanding-pipedrive-s-2025-plan-changes)
- [Fórum: permissões por funil](https://community.pipedrive.com/discussion/10952/permissions-for-pipelines)
- [Fórum: acesso de vendedores externos](https://community.pipedrive.com/discussion/569/access-for-external-sales-people-restricted-or-custom-permissions)
