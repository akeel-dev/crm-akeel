#!/bin/sh
set -eu

raiz=$(cd "$(dirname "$0")/../.." && pwd)
cd "$raiz"

ok() { echo "ok     [$1] $2"; }
falha() { echo "FALHOU [$1] $2" >&2; exit 1; }

for f in docker openssl; do
  command -v "$f" >/dev/null 2>&1 || falha pre "falta o comando $f"
done
[ -f .env ] || falha pre "falta .env (rode sh deploy/local/gerar-segredos.sh)"
S3_BUCKET=$(sed -n 's/^S3_BUCKET=//p' .env)
[ -n "$S3_BUCKET" ] || falha pre "S3_BUCKET ausente no .env"

echo "testar-local.sh: $(date -u +%Y-%m-%dT%H:%M:%SZ) em $(hostname -s) ($(uname -sm))"

for s in garage-destino backup-destino; do
  h=$(docker compose ps --format '{{.Health}}' "$s" 2>/dev/null || true)
  [ "$h" = healthy ] || falha pre "$s não está healthy (rode: docker compose --profile backup-teste up -d --wait)"
done

run=$(date -u +%Y%m%d%H%M%S)
segredos="$raiz/deploy/backup/secrets"
G() { docker compose exec -T garage-destino /garage "$@" 2>/dev/null; }
psql_q() { docker compose exec -T postgres psql -U postgres -v ON_ERROR_STOP=1 -d "$1" -tAc "$2"; }
arq() { docker compose --progress quiet run --rm -T backup-arquivos "$@"; }
existe() { [ -n "$(arq exec rclone lsf "$1" 2>/dev/null)" ]; }
origem() { echo "origem:$S3_BUCKET/teste-backup/$run/$1"; }

limpar() {
  rc=$?
  trap - EXIT INT TERM
  set +e
  bancos=$(psql_q postgres "SELECT count(*) FROM pg_database WHERE datname IN ('crm','keycloak')" 2>/dev/null)
  if [ "$bancos" != 2 ]; then
    echo "testar-local.sh: os bancos não estão de pé; o destino de teste foi MANTIDO. Para voltar:" >&2
    echo "  BACKUP_SEGREDOS=$segredos/teste-${d:-a} sh deploy/backup/restaurar.sh --ponto corte-$run-${d:-a}" >&2
    exit "$rc"
  fi
  for b in crm keycloak; do psql_q "$b" "DROP SCHEMA IF EXISTS backup_teste CASCADE" >/dev/null 2>&1; done
  for d in a b; do
    [ -d "$segredos/teste-$d" ] || continue
    BACKUP_SEGREDOS="$segredos/teste-$d" arq exec rclone purge "origem:$S3_BUCKET/teste-backup/$run" >/dev/null 2>&1
    BACKUP_SEGREDOS="$segredos/teste-$d" arq exec rclone purge "destino:crm-backup-$d-$run" >/dev/null 2>&1
    G bucket delete --yes "crm-backup-$d-$run" >/dev/null
    G key delete --yes "teste-backup-$d-$run" >/dev/null
    rm -rf "$segredos/teste-$d"
  done
  unset BACKUP_SEGREDOS
  docker compose stop keycloak >/dev/null 2>&1
  docker compose up -d --wait --force-recreate --no-deps postgres >/dev/null 2>&1
  docker compose up -d --wait keycloak >/dev/null 2>&1
  echo "testar-local.sh: limpo (schema backup_teste, teste-backup/$run, buckets e chaves de teste, segredos de teste); postgres de volta ao segredo padrão (sem destino); exit $rc"
  exit "$rc"
}
trap limpar EXIT
trap 'exit 130' INT TERM

if ! G layout show | grep -q 'local'; then
  no=$(G status | awk '/^[0-9a-f]{16} /{print $1; exit}')
  [ -n "$no" ] || falha pre "garage-destino sem id de nó"
  G layout assign -z local -c 1G "$no" >/dev/null
  G layout apply --version 1 >/dev/null
fi
ok pre "garage-destino com layout"

umask 077
mkdir -p "$segredos"
chmod 700 "$segredos"
preparar_destino() {
  d=$1
  dir="$segredos/teste-$d"
  bucket="crm-backup-$d-$run"
  ak="GK$(openssl rand -hex 12)"
  sk=$(openssl rand -hex 32)
  rm -rf "$dir"; mkdir -p "$dir"; chmod 755 "$dir"
  G bucket create "$bucket" >/dev/null
  G key import --yes -n "teste-backup-$d-$run" "$ak" "$sk" >/dev/null
  G bucket allow --read --write --owner "$bucket" --key "$ak" >/dev/null
  printf '%s' "https://backup-destino" > "$dir/backup_s3_endpoint"
  printf '%s' "garage" > "$dir/backup_s3_region"
  printf '%s' "$bucket" > "$dir/backup_s3_bucket"
  printf '%s' "path" > "$dir/backup_s3_uri_style"
  printf '%s' "$ak" > "$dir/backup_s3_access_key"
  printf '%s' "$sk" > "$dir/backup_s3_secret_key"
  openssl rand -hex 32 | tr -d '\n' > "$dir/backup_cipher_pass"
  docker compose cp backup-destino:/data/caddy/pki/authorities/local/root.crt "$dir/backup_s3_ca_cert" >/dev/null 2>&1
  chmod 644 "$dir"/*
  ok pre "destino $d: bucket $bucket, chave e senha de cifra próprias (deploy/backup/secrets/teste-$d)"
}
preparar_destino a
preparar_destino b

apontar() {
  BACKUP_SEGREDOS="$segredos/teste-$1"
  export BACKUP_SEGREDOS
  docker compose stop keycloak >/dev/null 2>&1
  docker compose up -d --wait --build --force-recreate --no-deps postgres >/dev/null 2>&1 ||
    falha pre "o postgres não voltou healthy"
  docker compose up -d --wait keycloak >/dev/null 2>&1 ||
    falha pre "o keycloak não voltou healthy"
}

linhas() {
  psql_q "$1" "SELECT coalesce(string_agg(fase, ',' ORDER BY fase), '') FROM backup_teste.controle WHERE id = '$2'" 2>/dev/null || echo "sem-banco"
}

ciclo() {
  d=$1
  m="CTL-$run-$d"
  apontar "$d"
  ok "$d" "postgres recriado com BACKUP_SEGREDOS=deploy/backup/secrets/teste-$d (nenhum arquivo versionado mudou)"

  for b in crm keycloak; do
    psql_q "$b" "CREATE SCHEMA IF NOT EXISTS backup_teste; CREATE TABLE IF NOT EXISTS backup_teste.controle (id text, fase text, em timestamptz DEFAULT now()); INSERT INTO backup_teste.controle (id, fase) VALUES ('$m', '1-antes-do-completo')" >/dev/null
  done
  printf 'conteudo-%s-v1' "$m" | arq exec rclone rcat "$(origem "$d/objeto.txt")"
  printf 'conteudo-%s-apagado' "$m" | arq exec rclone rcat "$(origem "$d/apagado.txt")"
  ok "$d" "gravado: linha '1-antes-do-completo' em crm e keycloak; objeto.txt e apagado.txt no bucket $S3_BUCKET"

  echo "--- backup.sh (destino $d)"
  sh deploy/backup/backup.sh
  if [ "$d" = a ]; then
    echo "--- backup.sh --mensal (destino $d)"
    sh deploy/backup/backup.sh --mensal
  fi

  for b in crm keycloak; do
    psql_q "$b" "INSERT INTO backup_teste.controle (id, fase) VALUES ('$m', '2-depois-do-completo')" >/dev/null
  done
  ponto="corte-$run-$d"
  psql_q postgres "SELECT pg_create_restore_point('$ponto')" >/dev/null
  docker compose exec -T -u postgres postgres crm-pgbackrest check >/dev/null
  ok "$d" "linha '2-depois-do-completo' gravada depois do completo; ponto '$ponto' criado e WAL arquivado (pgbackrest check)"

  arq exec sh /opt/crm/backup/teste/inspecionar.sh "$m" "conteudo-$m" "objeto.txt" "apagado.txt" ||
    falha cifra "destino $d: inspeção do destino"
  ok cifra "destino $d: pgbackrest/ e arquivos/ no destino, todos os objetos cifrados no cliente"

  docker compose stop keycloak >/dev/null 2>&1
  psql_q postgres "DROP DATABASE crm WITH (FORCE)" >/dev/null
  psql_q postgres "DROP DATABASE keycloak WITH (FORCE)" >/dev/null
  arq exec rclone deletefile "$(origem "$d/objeto.txt")"
  restam=$(psql_q postgres "SELECT count(*) FROM pg_database WHERE datname IN ('crm','keycloak')")
  [ "$restam" = 0 ] || falha restauracao "os bancos não foram apagados"
  if existe "$(origem "$d/objeto.txt")"; then falha restauracao "o objeto não foi apagado"; fi
  ok restauracao "destino $d: apagados os bancos crm e keycloak e o objeto objeto.txt"

  echo "--- restaurar.sh --ponto $ponto (destino $d)"
  sh deploy/backup/restaurar.sh --ponto "$ponto"

  for b in crm keycloak; do
    l=$(linhas "$b" "$m")
    [ "$l" = "1-antes-do-completo,2-depois-do-completo" ] || falha restauracao "destino $d: banco $b devolveu '$l'"
    ok restauracao "destino $d: banco $b voltou com as linhas: $l (a 2ª só existe pelo WAL)"
  done
  c=$(arq exec rclone cat "$(origem "$d/objeto.txt")")
  [ "$c" = "conteudo-$m-v1" ] || falha restauracao "destino $d: objeto.txt voltou com outro conteúdo"
  ok restauracao "destino $d: objeto.txt voltou com o conteúdo gravado antes do backup"
  kc=$(psql_q keycloak "SELECT count(*) FROM realm")
  [ "$kc" -gt 0 ] || falha restauracao "destino $d: o banco keycloak voltou sem realms"
}

ciclo a

m="CTL-$run-a"
printf 'conteudo-%s-v2' "$m" | arq exec rclone rcat "$(origem "a/objeto.txt")"
arq exec rclone deletefile "$(origem "a/apagado.txt")"
arq copiar
dia=$(date -u +%Y-%m-%d)
versoes=$(arq exec rclone lsf -R --files-only "cifrado:versoes/$dia/")
v_obj=$(printf '%s\n' "$versoes" | grep "teste-backup/$run/a/objeto.txt$" | tail -1)
v_apg=$(printf '%s\n' "$versoes" | grep "teste-backup/$run/a/apagado.txt$" | tail -1)
[ -n "$v_obj" ] || falha versoes "objeto.txt sobrescrito não está em versoes/$dia/"
[ -n "$v_apg" ] || falha versoes "apagado.txt não está em versoes/$dia/"
c=$(arq exec rclone cat "cifrado:versoes/$dia/$v_obj")
[ "$c" = "conteudo-$m-v1" ] || falha versoes "a versão em versoes/$dia/ não é a anterior"
c=$(arq exec rclone cat "cifrado:versoes/$dia/$v_apg")
[ "$c" = "conteudo-$m-apagado" ] || falha versoes "apagado.txt em versoes/$dia/ com outro conteúdo"
ok versoes "sobrescrito: a versão anterior está em versoes/$dia/$v_obj"
ok versoes "apagado: está em versoes/$dia/$v_apg"
c=$(arq exec rclone cat "cifrado:atual/teste-backup/$run/a/objeto.txt")
[ "$c" = "conteudo-$m-v2" ] || falha versoes "atual/ não tem a versão nova"
ok versoes "atual/ tem a versão nova (v2)"

ciclo b
ok troca "os mesmos scripts fizeram backup e restauração no destino B (outro bucket, outra chave), só trocando BACKUP_SEGREDOS"

ok fim "cifra, restauração, versões e troca de destino passaram"
echo "testar-local.sh: tudo passou em $(date -u +%Y-%m-%dT%H:%M:%SZ)"
