#!/bin/sh
set -eu

. "$(dirname "$0")/../comum.sh"
crm_carregar "${1:-homologacao-local}"

curl_img=curlimages/curl:8.23.0
base=$CRM_ORIGEM_PUBLICA
t=$(mktemp -d)
sonda=""
limpar() {
  [ -z "$sonda" ] || docker rm -f "$sonda" >/dev/null 2>&1 || true
  rm -rf "$t"
}
trap limpar EXIT

ok() { echo "ok     [$1] $2"; }
falha() { echo "FALHOU [$1] $2" >&2; exit 1; }

publico() {
  nome=$1
  shift
  curl -sS -o "$t/$nome.corpo" -D "$t/$nome.cab" -w '%{http_code}' "$@"
}
cabecalho() { tr -d '\r' < "$t/$1.cab" | sed -n "s/^$2: //Ip" | head -n 1; }
direto() { docker run --rm --network "$crm_rede" "$curl_img" -sS "$@"; }
e_spa() { cmp -s "$t/$1.corpo" "$t/index.html"; }
redirect_uri() {
  sed -n 's/.*[?&]redirect_uri=\([^&]*\).*/\1/p' | sed 's/%3A/:/g; s/%2F/\//g'
}

direto "http://frontend:8080/" > "$t/index.html"
grep -q '<div id="root">' "$t/index.html" || falha 8 "o frontend nao devolveu o index.html da SPA"

s=$(publico sessao "$base/api/session")
d=$(direto -o /dev/null -w '%{http_code} %{content_type}' "http://api:8080/api/session")
tipo=$(cabecalho sessao content-type)
[ "$s" = 401 ] && case "$tipo" in *json*) true ;; *) false ;; esac && [ "$d" = "401 $tipo" ] \
  || falha 8 "GET /api/session: proxy $s ($tipo), api direta $d"
ok 8 "GET /api/session sem cookie -> 401 $tipo, igual a api direta"

s=$(publico login "$base/oauth2/authorization/keycloak")
d=$(direto -o /dev/null -w '%{http_code}' "http://api:8080/oauth2/authorization/keycloak")
local_kc=$(cabecalho login location)
case "$local_kc" in "$KEYCLOAK_BASE_URL/realms/$KEYCLOAK_REALM/protocol/openid-connect/auth?"*) true ;; *) false ;; esac \
  && [ "$s" = 302 ] && [ "$d" = 302 ] || falha 8 "GET /oauth2/authorization/keycloak: $s, Location fora do Keycloak local, api direta $d"
ok 8 "GET /oauth2/authorization/keycloak -> 302 para $KEYCLOAK_BASE_URL/realms/$KEYCLOAK_REALM (api direta: $d)"

tr -d '\r' < "$t/login.cab" | grep -i '^set-cookie: SESSION=' >/dev/null || falha 8 "o login nao abriu o cookie SESSION"
if tr -d '\r' < "$t/login.cab" | grep -i '^set-cookie:' | grep -qi 'domain='; then
  falha 8 "cookie com Domain"
fi
ok 8 "cookie SESSION host-only (nenhum Set-Cookie com Domain)"

s=$(publico callback "$base/login/oauth2/code/keycloak")
d=$(direto -o /dev/null -w '%{http_code}' "http://api:8080/login/oauth2/code/keycloak")
[ "$s" = "$d" ] && ! e_spa callback || falha 8 "GET /login/oauth2/code/keycloak: proxy $s, api direta $d"
ok 8 "GET /login/oauth2/code/keycloak -> $s, igual a api direta, nao e o index.html"

s=$(publico sair -X POST "$base/logout")
d=$(direto -o /dev/null -w '%{http_code}' -X POST "http://api:8080/logout")
[ "$s" = "$d" ] && ! e_spa sair || falha 8 "POST /logout: proxy $s, api direta $d"
ok 8 "POST /logout -> $s, igual a api direta, nao e o index.html"

for caminho in / /qualquer/rota /apix /api /oauth2/authorization /login/oauth2/code /logout/x /logoutx /oauth2/x /login/x /actuator/health; do
  s=$(publico spa "$base$caminho")
  [ "$s" = 200 ] && e_spa spa || falha 8 "GET $caminho: $s, esperado o index.html da SPA"
done
ok 8 "/, /qualquer/rota e os vizinhos dos quatro prefixos (/apix, /api, /oauth2/authorization, /login/oauth2/code, /logout/x, /logoutx, /oauth2/x, /login/x, /actuator/health) -> 200 com o index.html da SPA"

publico cors -H "Origin: http://outra-origem.invalid" "$base/api/session" >/dev/null
publico preflight -X OPTIONS -H "Origin: http://outra-origem.invalid" -H "Access-Control-Request-Method: POST" "$base/api/session" >/dev/null
for nome in cors preflight; do
  if tr -d '\r' < "$t/$nome.cab" | grep -qi '^access-control-'; then
    falha 8 "resposta com cabecalho CORS ($nome)"
  fi
done
if grep -qi 'access-control' "$crm_raiz/deploy/aplicacao/proxy.conf.template"; then
  falha 8 "o proxy configura CORS"
fi
ok 8 "nenhum CORS: GET e pre-voo com Origin de fora sem Access-Control-*, proxy sem Access-Control"

publico host -H "Host: $CRM_HOST_SONDA" "$base/oauth2/authorization/keycloak" >/dev/null
r=$(cabecalho host location | redirect_uri)
[ "$r" = "$CRM_ESQUEMA_PUBLICO://$CRM_HOST_SONDA/login/oauth2/code/keycloak" ] \
  || falha 9 "Host $CRM_HOST_SONDA, esquema $CRM_ESQUEMA_PUBLICO: redirect_uri=$r"
ok 9 "proxy de pe ($CRM_ESQUEMA_PUBLICO): Host $CRM_HOST_SONDA -> redirect_uri=$r"

sonda=$CRM_PROJETO-sonda-https
docker rm -f "$sonda" >/dev/null 2>&1 || true
crm_dc run -d --no-deps --name "$sonda" -e CRM_ESQUEMA_PUBLICO=https proxy >/dev/null
r=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
  r=$(direto -o /dev/null -w '%{redirect_url}' -H "Host: $CRM_HOST_SONDA" "http://$sonda:8080/oauth2/authorization/keycloak" 2>/dev/null | redirect_uri) && [ -n "$r" ] && break
  sleep 1
done
[ "$r" = "https://$CRM_HOST_SONDA/login/oauth2/code/keycloak" ] \
  || falha 9 "proxy com esquema https: redirect_uri=$r"
ok 9 "proxy com esquema https: Host $CRM_HOST_SONDA -> redirect_uri=$r"

crm_dc exec -T api sh -c 'test -s /run/secrets/KEYCLOAK_CLIENT_SECRET && ! printenv KEYCLOAK_CLIENT_SECRET >/dev/null' \
  || falha 10 "KEYCLOAK_CLIENT_SECRET nao chegou como arquivo de segredo, ou esta no ambiente"
ok 10 "KEYCLOAK_CLIENT_SECRET em /run/secrets na api e fora do ambiente"

perfil=$(crm_dc exec -T worker printenv SPRING_PROFILES_ACTIVE)
ehlo=$(crm_dc exec -T worker printenv MAIL_EHLO_NAME)
[ "$perfil" = prod ] && [ -n "$ehlo" ] || falha 11 "worker com perfil '$perfil' e MAIL_EHLO_NAME '$ehlo'"
destino="verificacao-$(date +%s)@homologacao.invalid"
if ! crm_dc exec -T worker java -XX:MaxRAMPercentage=40 org.springframework.boot.loader.launch.JarLauncher \
  --crm.mail.check-to="$destino" --server.port=0 > "$t/mail.log" 2>&1; then
  tail -n 20 "$t/mail.log" >&2
  falha 11 "o comando de verificacao de envio saiu diferente de 0"
fi
achados=$(direto -G --data-urlencode "query=to:$destino" "http://mailpit:8025/api/v1/search" | sed -n 's/.*"messages_count":\([0-9]*\).*/\1/p')
[ "${achados:-0}" -ge 1 ] || falha 11 "a mensagem para $destino nao esta no Mailpit"
ok 11 "worker (perfil $perfil, EHLO $ehlo): verificacao de envio saiu 0 e $destino esta no Mailpit"

previo() {
  direto -o /dev/null -D - -X OPTIONS -H "Origin: $1" -H "Access-Control-Request-Method: PUT" \
    "$CRM_STORAGE_ENDPOINT/$CRM_STORAGE_BUCKET/sonda" | tr -d '\r'
}
previo "$CRM_ORIGEM_PUBLICA" > "$t/bucket-publico"
previo "http://outra-origem.invalid" > "$t/bucket-outra"
head -n 1 "$t/bucket-publico" | grep -q ' 200' \
  && grep -qi "^access-control-allow-origin: $CRM_ORIGEM_PUBLICA$" "$t/bucket-publico" \
  && grep -qi '^access-control-allow-methods:.*PUT' "$t/bucket-publico" \
  || falha arquivos "o pre-voo do bucket para $CRM_ORIGEM_PUBLICA nao libera PUT"
head -n 1 "$t/bucket-outra" | grep -q ' 200' && falha arquivos "o pre-voo do bucket libera uma origem de fora"
ok arquivos "CORS do bucket aplicado: pre-voo PUT de $CRM_ORIGEM_PUBLICA -> 200, de outra origem -> $(head -n 1 "$t/bucket-outra" | cut -d ' ' -f 2)"
