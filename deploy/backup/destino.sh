BACKUP_SEGREDOS_DIR=${BACKUP_SEGREDOS_DIR:-/run/secrets/backup}

destino_carregar() {
  if [ -e "$BACKUP_SEGREDOS_DIR/SEM_DESTINO" ]; then
    return 3
  fi
  for _nome in BACKUP_S3_ENDPOINT BACKUP_S3_REGION BACKUP_S3_BUCKET BACKUP_S3_URI_STYLE \
               BACKUP_S3_ACCESS_KEY BACKUP_S3_SECRET_KEY BACKUP_CIPHER_PASS; do
    _arq="$BACKUP_SEGREDOS_DIR/$(printf '%s' "$_nome" | tr 'A-Z' 'a-z')"
    if [ ! -r "$_arq" ] || [ ! -s "$_arq" ]; then
      echo "destino: falta $_nome (arquivo $_arq ausente ou vazio)" >&2
      return 1
    fi
    _valor=$(cat "$_arq")
    export "$_nome=$_valor"
  done
  unset _nome _arq _valor

  BACKUP_S3_CA_CERT=
  if [ -s "$BACKUP_SEGREDOS_DIR/backup_s3_ca_cert" ]; then
    BACKUP_S3_CA_CERT="$BACKUP_SEGREDOS_DIR/backup_s3_ca_cert"
  fi
  export BACKUP_S3_CA_CERT

  case "$BACKUP_S3_ENDPOINT" in
    https://*) ;;
    *) echo "destino: BACKUP_S3_ENDPOINT precisa ser https:// (o pgBackRest só fala S3 com TLS)" >&2
       return 1 ;;
  esac
  case "$BACKUP_S3_URI_STYLE" in
    path|host) ;;
    *) echo "destino: BACKUP_S3_URI_STYLE precisa ser path ou host" >&2; return 1 ;;
  esac

  BACKUP_S3_HOST=${BACKUP_S3_ENDPOINT#https://}
  BACKUP_S3_HOST=${BACKUP_S3_HOST%%/*}
  case "$BACKUP_S3_HOST" in
    *:*) BACKUP_S3_PORT=${BACKUP_S3_HOST##*:}; BACKUP_S3_HOST=${BACKUP_S3_HOST%:*} ;;
    *)   BACKUP_S3_PORT=443 ;;
  esac
  export BACKUP_S3_HOST BACKUP_S3_PORT
  return 0
}
