#!/bin/sh
set -eu

raiz=$(cd "$(dirname "$0")/../.." && pwd)
cd "$raiz"

repo=1; banco=1; arquivos=1
for a in "$@"; do
  case "$a" in
    --mensal) repo=2; arquivos=0 ;;
    --so-banco) arquivos=0 ;;
    --so-arquivos) banco=0 ;;
    *) echo "uso: backup.sh [--mensal] [--so-banco|--so-arquivos]" >&2; exit 2 ;;
  esac
done

echo "backup.sh: início $(date -u +%Y-%m-%dT%H:%M:%SZ) em $(hostname -s)"
pg() { docker compose exec -T -u postgres postgres crm-pgbackrest "$@"; }

if [ "$banco" = 1 ]; then
  pg stanza-create
  pg check
  pg --repo="$repo" --type=full backup
  pg --repo="$repo" info
fi

if [ "$arquivos" = 1 ]; then
  docker compose --progress quiet run --rm -T backup-arquivos copiar
  docker compose --progress quiet run --rm -T backup-arquivos reter
fi

echo "backup.sh: fim $(date -u +%Y-%m-%dT%H:%M:%SZ)"
