#!/bin/sh
set -eu

raiz=$(cd "$(dirname "$0")/../.." && pwd)
alvo=${1:-$raiz}
[ -d "$alvo" ] || { echo "verificar-portabilidade: não é diretório: $alvo" >&2; exit 2; }
alvo=$(cd "$alvo" && pwd)

escopo=""
for p in deploy/backup deploy/postgres compose.yaml; do
  [ -e "$alvo/$p" ] && escopo="$escopo $alvo/$p"
done
[ -n "$escopo" ] || escopo="$alvo"

arquivos=$(find $escopo -type d -name secrets -prune -o -type f -print | LC_ALL=C sort)
n_arq=$(printf '%s\n' "$arquivos" | grep -c . || true)

echo "verificar-portabilidade: $(date -u +%Y-%m-%dT%H:%M:%SZ) em $(hostname -s); alvo: $alvo"
echo "verificar-portabilidade: $n_arq arquivo(s) em:$(printf '%s' "$escopo" | sed "s#$alvo/##g; s#$alvo#.#g")"

achados=$(mktemp)
trap 'rm -f "$achados"' EXIT

HOSTS='amazonaws[.]com|cloudflarestorage[.]com|r2[.]dev|back''blaze(b2)?([.]com)?|digitaloceanspaces[.]com|wasabisys[.]com|storage[.]googleapis[.]com|blob[.]core[.]windows[.]net|linodeobjects[.]com|oraclecloud[.]com|aliyuncs[.]com|scw[.]cloud|cloud[.]ovh[.]net|idrive''e2|contabostorage[.]com|your-objectstorage[.]com|storjshare[.]io|filebase[.]com|magaluobjects[.]com'
FERRAMENTAS='(^|[^[:alnum:]_.-])(wr''angler|gs''util|s5''cmd|aws[[:space:]]+(s3|s3api|configure)|b''2[[:space:]]+[a-z-]+|gcloud[[:space:]]+storage|az[[:space:]]+storage|ali''yun[[:space:]]+oss)([^[:alnum:]_]|$)'

regra() {
  printf '%s\n' "$arquivos" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -n -o -i -E -e "$2" "$f" 2>/dev/null | while IFS= read -r m; do
      printf '%s:%s:%s:%s\n' "${f#"$alvo"/}" "${m%%:*}" "$1" "${m#*:}" >> "$achados"
    done
  done
}

regra host "$HOSTS"
regra ferramenta "$FERRAMENTAS"

dest() {
  printf '%s\n' "$arquivos" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -n -E -e "$2" "$f" 2>/dev/null | while IFS= read -r l; do
      n=${l%%:*}; txt=${l#*:}
      if [ -n "$3" ] && printf '%s' "$txt" | grep -q -E -e "$3"; then continue; fi
      t=$(printf '%s' "$txt" | grep -o -E -e "$2" | head -1)
      [ "${4-}" != nome ] || t=$(printf '%s' "$t" | sed 's/[[:space:]]*[=:].*//')
      printf '%s:%s:%s:%s\n' "${f#"$alvo"/}" "$n" "$1" "$t" >> "$achados"
    done
  done
}
B='\$\{?BACKUP_S3_'

dest destino 'PGBACKREST_REPO[^_=:[:space:]]*_(S3_(ENDPOINT|BUCKET|REGION|URI_STYLE|KEY|KEY_SECRET|TOKEN|ROLE)|STORAGE_HOST|STORAGE_PORT|HOST|GCS_[A-Z_]+|AZURE_[A-Z_]+|SFTP_[A-Z_]+)' "$B"
dest destino '--repo[0-9]+-(s3-(endpoint|bucket|region|uri-style|key|key-secret)|storage-host|host|gcs-[a-z-]+|azure-[a-z-]+|sftp-[a-z-]+)' "$B"
for f in $(printf '%s\n' "$arquivos" | grep -E '[.](conf|ini)$' || true); do
  grep -n -E '^[[:space:]]*repo[0-9]+-(s3-(endpoint|bucket|region|uri-style|key|key-secret|token|role)|storage-host|storage-port|host|gcs-|azure-|sftp-)' "$f" |
    while IFS= read -r l; do
      printf '%s:%s:destino:%s\n' "${f#"$alvo"/}" "${l%%:*}" "$(printf '%s' "${l#*:}" | cut -d= -f1 | tr -d ' ')" >> "$achados"
    done
done
dest destino '(^|[^[:alnum:]_-])-?-?repo[0-9]+-type[[:space:]]*[=:][[:space:]]*[a-z]+' '-type[[:space:]]*[=:][[:space:]]*s3([^[:alnum:]]|$)'
dest destino 'PGBACKREST_REPO[^_=:[:space:]]*_TYPE[[:space:]]*[=:][[:space:]]*"?[a-z]+' '_TYPE[[:space:]]*[=:][[:space:]]*"?s3([^[:alnum:]]|$)'

dest destino 'RCLONE_CONFIG_ORIGEM_(ENDPOINT|REGION)[[:space:]]*[=:]' '\$\{?ORIGEM_S3_'
dest destino 'RCLONE_CONFIG_ORIGEM_(ACCESS_KEY_ID|SECRET_ACCESS_KEY)[[:space:]]*[=:]' '(\$\(cat /run/secrets/garage_s3_|^[[:space:]]*export[[:space:]]+RCLONE_CONFIG_ORIGEM_ACCESS_KEY_ID[[:space:]]+RCLONE_CONFIG_ORIGEM_SECRET_ACCESS_KEY[[:space:]]*$)'
dest destino 'RCLONE_CONFIG_[A-Z0-9]+_(ENDPOINT|REGION|ACCESS_KEY_ID|SECRET_ACCESS_KEY|SESSION_TOKEN)[[:space:]]*[=:]' "($B|RCLONE_CONFIG_ORIGEM_)"
dest destino 'RCLONE_CONFIG_[A-Z0-9]+_PROVIDER[[:space:]]*[=:][[:space:]]*"?[A-Za-z]+' '_PROVIDER[[:space:]]*[=:][[:space:]]*"?Other"?[[:space:]]*$'
dest destino 'RCLONE_CONFIG_[A-Z0-9]+_TYPE[[:space:]]*[=:][[:space:]]*"?[a-z0-9]+' '_TYPE[[:space:]]*[=:][[:space:]]*"?(s3|crypt)"?[[:space:]]*$'
dest destino 'RCLONE_CONFIG_[A-Z0-9]+_REMOTE[[:space:]]*[=:].*' '_REMOTE[[:space:]]*[=:][[:space:]]*"destino:\$BACKUP_S3_BUCKET/'
dest destino '(^|[[:space:]])--s3-[a-z-]+' ''
dest destino '(^|[^[:alnum:]_]):(s3|b2|gcs|azureblob|swift|drive)[,:]' ''
dest destino 'RCLONE_(S3|B2|GCS|AZUREBLOB|SWIFT)_[A-Z0-9_]+[[:space:]]*[=:]' ''
dest destino 'RCLONE_[A-Z0-9_]*PROVIDER[[:space:]]*[=:][[:space:]]*"?[A-Za-z]+' '_PROVIDER[[:space:]]*[=:][[:space:]]*"?Other"?[[:space:]]*$'

dest destino '\$\{BACKUP_(S3|CIPHER)_[A-Z0-9_]*:?[-=+]' ''
dest destino '\$\{[A-Za-z_][A-Za-z0-9_]*:?[-=+][[:space:]"'"'"']*[A-Za-z0-9-]+([.][A-Za-z0-9-]+)+(:[0-9]+)?([/}"'"'"'[:space:]]|$)' ''
dest destino '(^|[^[:alnum:]_{])BACKUP_(S3|CIPHER)_[A-Z0-9_]+[[:space:]]*[=:][[:space:]]*"?[^$"[:space:];]' '(^|[^[:alnum:]_])BACKUP_S3_PORT[=]443([;[:space:]]|$)' nome
dest destino '[A-Z0-9_]*(ENDPOINT|HOST)[A-Z0-9_]*[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9-]+([.][A-Za-z0-9-]+)+' ''
for f in $arquivos; do
  grep -n -i -E '^[[:space:]]*(endpoint|provider|region|access_key_id|secret_access_key|session_token|server_side_encryption|account|key|sas_url|service_account_file)[[:space:]]*=' "$f" |
    while IFS= read -r l; do
      printf '%s:%s:destino:%s\n' "${f#"$alvo"/}" "${l%%:*}" "$(printf '%s' "${l#*:}" | cut -d= -f1 | tr -d ' ')" >> "$achados"
    done
done

dest destino '(^|[^[:alnum:]])(s3|b2|gs|r2|az|wasabi)://' ''

dest destino '[a-z][a-z0-9+.-]*://[A-Za-z0-9-]+[.][A-Za-z0-9.-]+' '://127[.]0[.]0[.]1([:/]|$)'

if [ -s "$achados" ]; then
  LC_ALL=C sort -u "$achados" | sed 's/^/RECUSADO /' >&2
  echo "verificar-portabilidade: FALHOU, $(LC_ALL=C sort -u "$achados" | wc -l | tr -d ' ') achado(s)" >&2
  exit 1
fi
echo "verificar-portabilidade: ok [host] nenhum endereço de provedor"
echo "verificar-portabilidade: ok [ferramenta] nenhuma ferramenta de provedor"
echo "verificar-portabilidade: ok [destino] pgBackRest e rclone só com destino de BACKUP_S3_*; repositório só s3; provider Other; crypt em destino:; sem URL de domínio literal; sem host literal em BACKUP_S3_*, ENDPOINT ou HOST; sem padrão em \${BACKUP_S3_*}; sem chave de remote rclone em arquivo; sem RCLONE_S3_*"
exit 0
