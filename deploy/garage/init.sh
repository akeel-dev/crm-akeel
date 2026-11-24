#!/bin/sh
# Dono: DevOps (time.yml, escrita.devops). Story 0-02, critério 4.
# Inicializa o Garage local pela Admin API v2 (http://garage:3903):
#   1. atribui o layout ao nó único e o aplica;
#   2. cria o bucket $S3_BUCKET;
#   3. importa a chave S3 do segredo local (deploy/local/secrets/garage_s3_*);
#   4. dá à chave leitura, escrita e dono no bucket.
# Idempotente: se já existe, segue. Ao terminar, cria /tmp/pronto (o healthcheck) e
# fica parado, para o serviço aparecer "healthy" no docker compose ps.
# Nunca imprime token nem chave.
set -eu

api=http://garage:3903
token=$(cat /run/secrets/garage_admin_token)
ak=$(cat /run/secrets/garage_s3_access_key_id)
sk=$(cat /run/secrets/garage_s3_secret_access_key)
bucket=${S3_BUCKET:?S3_BUCKET ausente}

chamar() { # metodo caminho [corpo]
  if [ $# -ge 3 ]; then
    curl -fsS -X "$1" -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
      --data "$3" "$api$2"
  else
    curl -fsS -X "$1" -H "Authorization: Bearer $token" "$api$2"
  fi
}
hex64() { tr -d ' \n' | sed -n "s/.*\"$1\":\"\([0-9a-f]\{64\}\)\".*/\1/p"; }

# 1. Layout
status=$(chamar GET /v2/GetClusterStatus | tr -d ' \n')
node=$(printf '%s' "$status" | sed -n 's/.*"nodes":\[{"id":"\([0-9a-f]\{64\}\)".*/\1/p')
[ -n "$node" ] || { echo "garage-init: sem id de nó" >&2; exit 1; }
layout=$(chamar GET /v2/GetClusterLayout | tr -d ' \n')
if printf '%s' "$layout" | grep -q "\"roles\":\[{\"id\":\"$node\""; then
  echo "garage-init: layout já aplicado"
else
  chamar POST /v2/UpdateClusterLayout \
    "{\"roles\":[{\"id\":\"$node\",\"zone\":\"local\",\"capacity\":1000000000,\"tags\":[]}]}" >/dev/null
  versao=$(printf '%s' "$layout" | sed -n 's/^{"version":\([0-9]*\).*/\1/p')
  chamar POST /v2/ApplyClusterLayout "{\"version\":$(( ${versao:-0} + 1 ))}" >/dev/null
  echo "garage-init: layout aplicado"
fi

# 2. Bucket
if info=$(chamar GET "/v2/GetBucketInfo?globalAlias=$bucket" 2>/dev/null); then
  echo "garage-init: bucket já existe"
else
  info=$(chamar POST /v2/CreateBucket "{\"globalAlias\":\"$bucket\"}")
  echo "garage-init: bucket criado"
fi
bucket_id=$(printf '%s' "$info" | hex64 id)
[ -n "$bucket_id" ] || { echo "garage-init: sem id de bucket" >&2; exit 1; }

# 3. Chave
if chamar GET "/v2/GetKeyInfo?id=$ak" >/dev/null 2>&1; then
  echo "garage-init: chave já existe"
else
  chamar POST /v2/ImportKey \
    "{\"accessKeyId\":\"$ak\",\"secretAccessKey\":\"$sk\",\"name\":\"crm-local\"}" >/dev/null
  echo "garage-init: chave importada"
fi

# 4. Permissão
chamar POST /v2/AllowBucketKey \
  "{\"bucketId\":\"$bucket_id\",\"accessKeyId\":\"$ak\",\"permissions\":{\"read\":true,\"write\":true,\"owner\":true}}" >/dev/null
echo "garage-init: chave com leitura, escrita e dono no bucket"

touch /tmp/pronto
trap 'exit 0' TERM INT
while :; do sleep 3600 & wait $!; done
