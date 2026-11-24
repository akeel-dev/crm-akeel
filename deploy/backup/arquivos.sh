#!/bin/sh
set -eu

. /opt/crm/backup/destino.sh

rc=0
destino_carregar || rc=$?
if [ "$rc" -eq 3 ]; then
  echo "arquivos: sem destino de backup (SEM_DESTINO)" >&2
  exit 1
fi
[ "$rc" -eq 0 ] || exit 1

: "${ORIGEM_S3_ENDPOINT:?}" "${ORIGEM_S3_REGION:?}" "${ORIGEM_S3_BUCKET:?}"

export RCLONE_CONFIG_ORIGEM_TYPE=s3
export RCLONE_CONFIG_ORIGEM_PROVIDER=Other
export RCLONE_CONFIG_ORIGEM_ENDPOINT="$ORIGEM_S3_ENDPOINT"
export RCLONE_CONFIG_ORIGEM_REGION="$ORIGEM_S3_REGION"
export RCLONE_CONFIG_ORIGEM_FORCE_PATH_STYLE=true
RCLONE_CONFIG_ORIGEM_ACCESS_KEY_ID=$(cat /run/secrets/garage_s3_access_key_id)
RCLONE_CONFIG_ORIGEM_SECRET_ACCESS_KEY=$(cat /run/secrets/garage_s3_secret_access_key)
export RCLONE_CONFIG_ORIGEM_ACCESS_KEY_ID RCLONE_CONFIG_ORIGEM_SECRET_ACCESS_KEY

export RCLONE_CONFIG_DESTINO_TYPE=s3
export RCLONE_CONFIG_DESTINO_PROVIDER=Other
export RCLONE_CONFIG_DESTINO_ENDPOINT="$BACKUP_S3_ENDPOINT"
export RCLONE_CONFIG_DESTINO_REGION="$BACKUP_S3_REGION"
export RCLONE_CONFIG_DESTINO_ACCESS_KEY_ID="$BACKUP_S3_ACCESS_KEY"
export RCLONE_CONFIG_DESTINO_SECRET_ACCESS_KEY="$BACKUP_S3_SECRET_KEY"
if [ "$BACKUP_S3_URI_STYLE" = path ]; then
  export RCLONE_CONFIG_DESTINO_FORCE_PATH_STYLE=true
else
  export RCLONE_CONFIG_DESTINO_FORCE_PATH_STYLE=false
fi
if [ -n "$BACKUP_S3_CA_CERT" ]; then
  export RCLONE_CA_CERT="$BACKUP_S3_CA_CERT"
fi

export RCLONE_CONFIG_CIFRADO_TYPE=crypt
export RCLONE_CONFIG_CIFRADO_REMOTE="destino:$BACKUP_S3_BUCKET/arquivos"
export RCLONE_CONFIG_CIFRADO_FILENAME_ENCRYPTION=standard
export RCLONE_CONFIG_CIFRADO_DIRECTORY_NAME_ENCRYPTION=true
RCLONE_CONFIG_CIFRADO_PASSWORD=$(printf '%s' "$BACKUP_CIPHER_PASS" | rclone obscure -)
RCLONE_CONFIG_CIFRADO_PASSWORD2=$(printf '%s:crm-akeel-sal' "$BACKUP_CIPHER_PASS" | sha256sum | cut -c1-64 | rclone obscure -)
export RCLONE_CONFIG_CIFRADO_PASSWORD RCLONE_CONFIG_CIFRADO_PASSWORD2

export RCLONE_STATS_LOG_LEVEL=NOTICE
export RCLONE_CONFIG=/tmp/rclone-vazio.conf
: > "$RCLONE_CONFIG"

dia() { date -u +%Y-%m-%d; }

copiar() {
  agora=$(date -u +%H%M%SZ)
  pasta="versoes/$(dia)/$agora"
  echo "arquivos: origem:$ORIGEM_S3_BUCKET -> cifrado:atual (substituídos e apagados em cifrado:$pasta)"
  rclone sync "origem:$ORIGEM_S3_BUCKET" cifrado:atual --backup-dir "cifrado:$pasta" \
    --stats-one-line -v
  echo "arquivos: cópia concluída"
}

a_apagar() {
  hoje_s=$(date -u -D %Y-%m-%d -d "$1" +%s)
  limite_s=$((hoje_s - 35 * 86400))
  mes_hoje=$(date -u -D %Y-%m-%d -d "$1" +%Y%m)
  ano=${mes_hoje%??}; mes=${mes_hoje#????}; mes=${mes#0}
  idx_hoje=$((ano * 12 + mes))
  sort -u | awk -v lim="$limite_s" -v idxh="$idx_hoje" '
    { cmd = "date -u -D %Y-%m-%d -d " $1 " +%s"; cmd | getline s; close(cmd)
      split($1, p, "-"); idx = p[1] * 12 + p[2]; m = p[1] p[2]
      if (s >= lim) next
      if (idx >= idxh - 12 && idx < idxh && !(m in visto)) { visto[m] = 1; next }
      print $1 }'
}

reter() {
  simular=${1-}
  datas=$(rclone lsf --dirs-only cifrado:versoes/ 2>/dev/null | tr -d / | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || true)
  apagar=$(printf '%s\n' "$datas" | grep . | a_apagar "$(dia)" || true)
  echo "arquivos: retenção em $(dia): $(printf '%s\n' "$datas" | grep -c . || true) dia(s) em versoes/, $(printf '%s\n' "$apagar" | grep -c . || true) a apagar"
  for d in $apagar; do
    if [ "$simular" = "--simular" ]; then
      echo "arquivos: (simulação) apagaria cifrado:versoes/$d"
    else
      rclone purge "cifrado:versoes/$d"
      echo "arquivos: apagado cifrado:versoes/$d"
    fi
  done
}

restaurar() {
  if [ "${1-}" = "--de" ] && [ -n "${2-}" ]; then
    de="versoes/$2"
  else
    de="atual"
  fi
  echo "arquivos: cifrado:$de -> origem:$ORIGEM_S3_BUCKET"
  rclone copy "cifrado:$de" "origem:$ORIGEM_S3_BUCKET" --stats-one-line -v
  echo "arquivos: restauração concluída"
}

case "${1-}" in
  copiar) copiar ;;
  reter) reter "${2-}" ;;
  restaurar) shift; restaurar "$@" ;;
  listar) rclone lsf -R --files-only cifrado: ;;
  a-apagar) a_apagar "$2" ;;
  exec) shift; exec "$@" ;;
  *) echo "uso: arquivos.sh copiar | reter [--simular] | restaurar [--de AAAA-MM-DD/HHMMSSZ] | listar" >&2; exit 2 ;;
esac
