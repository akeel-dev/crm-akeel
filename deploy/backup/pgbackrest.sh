#!/bin/sh
set -eu

. /opt/crm/backup/destino.sh

rc=0
destino_carregar || rc=$?
if [ "$rc" -eq 3 ]; then
  if [ "${1-}" = "archive-push" ]; then
    echo "crm-pgbackrest: sem destino de backup (SEM_DESTINO); WAL ${2-} não arquivado" >&2
    exit 0
  fi
  echo "crm-pgbackrest: sem destino de backup (SEM_DESTINO); nada a fazer" >&2
  exit 1
fi
[ "$rc" -eq 0 ] || exit 1

for n in 1 2; do
  export "PGBACKREST_REPO${n}_S3_ENDPOINT=$BACKUP_S3_HOST"
  export "PGBACKREST_REPO${n}_STORAGE_PORT=$BACKUP_S3_PORT"
  export "PGBACKREST_REPO${n}_S3_REGION=$BACKUP_S3_REGION"
  export "PGBACKREST_REPO${n}_S3_BUCKET=$BACKUP_S3_BUCKET"
  export "PGBACKREST_REPO${n}_S3_URI_STYLE=$BACKUP_S3_URI_STYLE"
  export "PGBACKREST_REPO${n}_S3_KEY=$BACKUP_S3_ACCESS_KEY"
  export "PGBACKREST_REPO${n}_S3_KEY_SECRET=$BACKUP_S3_SECRET_KEY"
  export "PGBACKREST_REPO${n}_CIPHER_PASS=$BACKUP_CIPHER_PASS"
  if [ -n "$BACKUP_S3_CA_CERT" ]; then
    export "PGBACKREST_REPO${n}_STORAGE_CA_FILE=$BACKUP_S3_CA_CERT"
  fi
done

export PGBACKREST_STANZA=crm
exec pgbackrest "$@"
