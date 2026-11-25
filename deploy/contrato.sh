#!/bin/sh
set -eu

raiz=${1:-$(cd "$(dirname "$0")/.." && pwd)}
cmp "$raiz/backend/openapi/openapi.json" "$raiz/frontend/openapi/openapi.json"
echo "contrato: backend/openapi/openapi.json e frontend/openapi/openapi.json iguais"
