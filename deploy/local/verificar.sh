#!/bin/sh
# Dono: DevOps (time.yml, escrita.devops). Story 0-02, "Como verificar".
#
#   docker compose down -v && docker compose up -d --wait && sh deploy/local/verificar.sh
#
# Confere, nesta ordem, e para no primeiro erro (exit 1):
#   crit. 1  todos os serviços do compose "healthy"
#   crit. 2  PostgreSQL >= 17 e os dois bancos (CRM e Keycloak, este com tabelas)
#   crit. 3  well-known do realm $KEYCLOAK_REALM; a conta de serviço crm-api lê usuários
#            pela Admin API (200) e não altera o realm (403); pela Admin API local, os três
#            clientes, os segredos vindos do segredo local, os grupos, os usuários, os
#            claims de um token de exemplo e nenhum provedor de identidade
#   crit. 4  a chave S3 do segredo local lista o bucket (e uma chave errada não lista)
#   crit. 5  um e-mail SMTP enviado ao Mailpit aparece na API dele
#
# O nome do realm vem de KEYCLOAK_REALM (ambiente, senão .env). Prova por presença
# do crit. 9: KEYCLOAK_REALM=nao-existe sh deploy/local/verificar.sh falha no crit. 3.
# Precisa de: docker, curl (com --aws-sigv4) e jq. Nunca imprime segredo nem token.
set -eu

raiz=$(cd "$(dirname "$0")/../.." && pwd)
cd "$raiz"
seg="$raiz/deploy/local/secrets"

ok() { echo "ok     [$1] $2"; }
falha() { echo "FALHOU [$1] $2" >&2; exit 1; }

for f in docker curl jq; do
  command -v "$f" >/dev/null 2>&1 || falha pre "falta o comando $f"
done
[ -f .env ] || falha pre "falta .env (rode sh deploy/local/gerar-segredos.sh)"

# Carrega o .env sem sobrescrever o que já veio do ambiente.
while IFS= read -r linha; do
  case "$linha" in ''|\#*) continue ;; esac
  nome=${linha%%=*}
  valor=${linha#*=}
  eval "atual=\${$nome-}"
  [ -n "$atual" ] || export "$nome=$valor"
done < .env

: "${KEYCLOAK_REALM:?KEYCLOAK_REALM ausente}"
kc="http://127.0.0.1:${KEYCLOAK_PORT:-8180}"
s3="http://127.0.0.1:${GARAGE_S3_PORT:-3900}"
mp_http="http://127.0.0.1:${MAILPIT_HTTP_PORT:-8025}"
mp_smtp="smtp://127.0.0.1:${MAILPIT_SMTP_PORT:-1025}"
realm="$KEYCLOAK_REALM"

echo "verificar.sh: $(date -u +%Y-%m-%dT%H:%M:%SZ) em $(hostname -s) ($(uname -sm)); realm=$realm"

# ---------------------------------------------------------------- crit. 1
esperados=$(docker compose config --services | sort)
saudaveis=$(docker compose ps --format json | jq -r 'select(.Health == "healthy") | .Service' | sort)
[ "$esperados" = "$saudaveis" ] ||
  falha 1 "serviços esperados: $(echo $esperados); healthy: $(echo $saudaveis)"
ok 1 "todos healthy: $(echo $saudaveis)"

# ---------------------------------------------------------------- crit. 2
psql_q() { docker compose exec -T postgres psql -U postgres -d "$1" -tAc "$2"; }
ver=$(psql_q postgres 'SHOW server_version_num')
[ "$ver" -ge 170000 ] || falha 2 "server_version_num=$ver (< 170000)"
ok 2 "server_version_num=$ver (>= 170000)"
bancos=$(psql_q postgres "SELECT string_agg(datname || ':' || pg_get_userbyid(datdba), ' ' ORDER BY datname) FROM pg_database WHERE datname IN ('crm','keycloak')")
[ "$bancos" = "crm:crm keycloak:keycloak" ] || falha 2 "bancos encontrados: '$bancos'"
ok 2 "bancos separados: $bancos"
kc_tabelas=$(psql_q keycloak "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")
[ "$kc_tabelas" -gt 0 ] || falha 2 "o banco keycloak está vazio (o Keycloak não usou o PostgreSQL)"
ok 2 "o Keycloak grava no PostgreSQL: $kc_tabelas tabelas no banco keycloak"

# ---------------------------------------------------------------- crit. 3
wk=$(curl -s -o /dev/null -w '%{http_code}' "$kc/realms/$realm/.well-known/openid-configuration")
[ "$wk" = 200 ] || falha 3 "GET /realms/$realm/.well-known/openid-configuration -> $wk"
ok 3 "GET /realms/$realm/.well-known/openid-configuration -> 200"
kc_realm_db=$(psql_q keycloak "SELECT count(*) FROM realm WHERE name = '$realm'")
[ "$kc_realm_db" = 1 ] || falha 3 "o realm $realm não está no banco keycloak"
ok 3 "o realm $realm está no banco keycloak do PostgreSQL (não em H2)"

token=$(curl -fsS "$kc/realms/master/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=admin-cli \
  --data-urlencode "username=${KEYCLOAK_ADMIN_USER:?}" \
  --data-urlencode "password@$seg/keycloak_admin_password" | jq -r .access_token)
[ -n "$token" ] && [ "$token" != null ] || falha 3 "sem token de admin do master"
adm() { curl -fsS -H "Authorization: Bearer $token" "$kc/admin/realms/$realm$1"; }

realm_json=$(adm "")
[ "$(echo "$realm_json" | jq -r .registrationEmailAsUsername)" = true ] ||
  falha 3 "registrationEmailAsUsername não está ligado"
ok 3 "realm com e-mail como nome de usuário"

cliente() { adm "/clients?clientId=$1" | jq -e '.[0]' || falha 3 "cliente $1 ausente"; }

bff=$(cliente crm-bff)
echo "$bff" | jq -e '
  .publicClient == false and .clientAuthenticatorType == "client-secret"
  and .standardFlowEnabled == true and .implicitFlowEnabled == false
  and .directAccessGrantsEnabled == false and .serviceAccountsEnabled == false
  and .attributes["pkce.code.challenge.method"] == "S256"
  and .redirectUris == ["http://localhost:*"]
  and .attributes["post.logout.redirect.uris"] == "http://localhost:*"
  and ((.attributes["backchannel.logout.url"] // "") == "")
  and ((.attributes["frontchannel.logout.url"] // "") == "")' >/dev/null ||
  falha 3 "crm-bff fora do esperado: $(echo "$bff" | jq -c '{publicClient,standardFlowEnabled,implicitFlowEnabled,directAccessGrantsEnabled,serviceAccountsEnabled,redirectUris,attributes}')"
ok 3 "crm-bff: confidencial, code + PKCE S256, redirect e post-logout só http://localhost:*, back/front-channel logout vazios"

api=$(cliente crm-api)
echo "$api" | jq -e '
  .publicClient == false and .serviceAccountsEnabled == true
  and .standardFlowEnabled == false and .implicitFlowEnabled == false
  and .directAccessGrantsEnabled == false' >/dev/null ||
  falha 3 "crm-api fora do esperado"
ok 3 "crm-api: confidencial, só client_credentials"
cc=$(curl -s -o /dev/null -w '%{http_code}' "$kc/realms/$realm/protocol/openid-connect/token" \
  -d grant_type=client_credentials -d client_id=crm-api \
  --data-urlencode "client_secret@$seg/crm_api_client_secret")
[ "$cc" = 200 ] || falha 3 "client_credentials do crm-api -> $cc"
adm "/users?username=service-account-crm-api&exact=true" | jq -e 'length == 1' >/dev/null ||
  falha 3 "conta de serviço service-account-crm-api ausente"
ok 3 "crm-api: client_credentials com o segredo local -> 200; conta de serviço presente"

# A conta de serviço usa a Admin API (RF-IAM-02): lê usuários, não altera o realm.
# No Keycloak 26 isso exige a audiência do client scope kc-admin-api no token
# (defaultClientScopes do crm-api). Sem ele, a Admin API devolve 401 (review 0-02, N1).
api_token=$(curl -fsS "$kc/realms/$realm/protocol/openid-connect/token" \
  -d grant_type=client_credentials -d client_id=crm-api \
  --data-urlencode "client_secret@$seg/crm_api_client_secret" | jq -r .access_token)
[ -n "$api_token" ] && [ "$api_token" != null ] || falha 3 "sem token do crm-api"
api_adm() { # método caminho [corpo]
  curl -s -o /dev/null -w '%{http_code}' -X "$1" -H "Authorization: Bearer $api_token" \
    -H 'Content-Type: application/json' ${3:+--data "$3"} "$kc/admin/realms/$realm$2"
}
cod=$(api_adm GET "/users?max=1")
[ "$cod" = 200 ] || falha 3 "crm-api: GET /admin/realms/$realm/users -> $cod (esperado 200; 401 = falta o escopo kc-admin-api)"
ok 3 "crm-api: GET /admin/realms/$realm/users -> 200"
cod=$(api_adm PUT "" '{"displayName":"verificar-nao-pode"}')
[ "$cod" = 403 ] || falha 3 "crm-api: PUT /admin/realms/$realm -> $cod (esperado 403: não pode alterar o realm)"
ok 3 "crm-api: PUT /admin/realms/$realm -> 403 (não altera o realm)"

web=$(cliente crm-web)
echo "$web" | jq -e '.publicClient == true and .standardFlowEnabled == true
  and .attributes["pkce.code.challenge.method"] == "S256"' >/dev/null ||
  falha 3 "crm-web fora do esperado"
ok 3 "crm-web: público, PKCE S256"

# O segredo de cada confidencial é o do arquivo local (substituição na importação).
for par in "crm-bff:crm_bff_client_secret:$bff" "crm-api:crm_api_client_secret:$api"; do
  cid=${par%%:*}; resto=${par#*:}; arq=${resto%%:*}; id=$(echo "${resto#*:}" | jq -r .id)
  [ "$(adm "/clients/$id/client-secret" | jq -r .value)" = "$(cat "$seg/$arq")" ] ||
    falha 3 "o segredo de $cid não é o de deploy/local/secrets/$arq"
  ok 3 "segredo de $cid = deploy/local/secrets/$arq (valor não impresso)"
done

for g in /Perfis/Administradores /Perfis/Gestores /Perfis/Vendedores /Perfis/Visualizadores /Equipes/Comercial; do
  adm "/group-by-path$g" | jq -e --arg p "$g" '.path == $p' >/dev/null || falha 3 "grupo $g ausente"
done
ok 3 "grupos /Perfis/{Administradores,Gestores,Vendedores,Visualizadores} e /Equipes/Comercial"

usuario() { # email verificado_esperado
  u=$(adm "/users?email=$1&exact=true" | jq -e '.[0]') || falha 3 "usuário $1 ausente"
  echo "$u" | jq -e --arg e "$1" --argjson v "$2" '.username == $e and .emailVerified == $v and .enabled' >/dev/null ||
    falha 3 "usuário $1: esperado username=e-mail e emailVerified=$2"
  echo "$u" | jq -r .id
}
ana=$(usuario ana.vendedora@akeel.com.br true)
usuario bruno.naoverificado@akeel.com.br false >/dev/null
usuario carla.externa@example.com true >/dev/null
ok 3 "usuários: @akeel verificado, @akeel não verificado, outro domínio"
adm "/users/$ana/groups" | jq -e '[.[].path] | index("/Perfis/Vendedores") and index("/Equipes/Comercial")' >/dev/null ||
  falha 3 "o verificado não está em /Perfis/Vendedores e /Equipes/Comercial"
ok 3 "o verificado está em /Perfis/Vendedores e /Equipes/Comercial"

bff_id=$(echo "$bff" | jq -r .id)
exemplo=$(adm "/clients/$bff_id/evaluate-scopes/generate-example-access-token?scope=openid&userId=$ana")
echo "$exemplo" | jq -e '
  (.sub | type) == "string" and .email_verified == true
  and .preferred_username == "ana.vendedora@akeel.com.br"
  and (.roles | index("vendedor") and index("visualizador"))
  and (.groups | index("/Equipes/Comercial") and index("/Perfis/Vendedores"))
  and ((.aud | if type == "array" then . else [.] end) | index("crm-api"))' >/dev/null ||
  falha 3 "token de exemplo do crm-bff fora da forma da §5.1: $(echo "$exemplo" | jq -c '{sub: (.sub | type),email_verified,preferred_username,roles,groups,aud}')"
ok 3 "token de exemplo (crm-bff): $(echo "$exemplo" | jq -c '{preferred_username,roles,groups,aud}')"

idps=$(adm "/identity-provider/instances" | jq length)
[ "$idps" = 0 ] || falha 3 "há $idps provedor(es) de identidade (esperado: nenhum)"
ok 3 "nenhum provedor de identidade (sem Google)"

# ---------------------------------------------------------------- crit. 4
s3_list() { # usuario:senha
  curl -s -o /dev/null -w '%{http_code}' --aws-sigv4 "aws:amz:garage:s3" --user "$1" \
    "$s3/${S3_BUCKET:?}?list-type=2"
}
ak=$(cat "$seg/garage_s3_access_key_id")
cod=$(s3_list "$ak:$(cat "$seg/garage_s3_secret_access_key")")
[ "$cod" = 200 ] || falha 4 "ListObjectsV2 em $S3_BUCKET com a chave local -> $cod"
ok 4 "ListObjectsV2 em $S3_BUCKET com a chave de deploy/local/secrets/ -> 200"
cod=$(s3_list "$ak:chave-errada-de-proposito")
[ "$cod" = 403 ] || falha 4 "com segredo errado esperava 403, veio $cod"
ok 4 "gêmeo: o mesmo pedido com segredo errado -> 403"

# ---------------------------------------------------------------- crit. 5
assunto="verificar-0-02-$(date +%s)-$$"
printf 'From: verificar@example.com\r\nTo: destino@example.com\r\nSubject: %s\r\n\r\nteste do ambiente local\r\n' "$assunto" |
  curl -fsS "$mp_smtp" --mail-from verificar@example.com --mail-rcpt destino@example.com -T - ||
  falha 5 "envio SMTP ao Mailpit falhou"
achou=$(curl -fsS "$mp_http/api/v1/messages?limit=50" | jq --arg s "$assunto" '[.messages[] | select(.Subject == $s)] | length')
[ "$achou" = 1 ] || falha 5 "o e-mail '$assunto' não apareceu na API do Mailpit"
ok 5 "e-mail '$assunto' enviado por SMTP e lido na API do Mailpit"

echo "verificar.sh: tudo ok"
