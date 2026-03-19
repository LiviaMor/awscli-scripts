#!/bin/bash

PROFILE=${1:?"Uso: eval \$(./sts-session.sh <profile>)"}

# Valida se o profile existe
if ! aws configure list --profile "$PROFILE" &>/dev/null; then
  echo "echo \"Erro: profile '$PROFILE' não encontrado.\"" >&2
  aws configure list-profiles >&2
  exit 1
fi

# Obtém token STS
CREDS=$(aws sts get-session-token --profile "$PROFILE" --output json 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "echo \"Erro ao obter token STS.\"" >&2
  exit 1
fi

# Extrai credenciais e gera comandos export
KEY_ID=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')
SECRET=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')
TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')
EXPIRA=$(echo "$CREDS" | jq -r '.Credentials.Expiration')

echo "export AWS_ACCESS_KEY_ID=$KEY_ID"
echo "export AWS_SECRET_ACCESS_KEY=$SECRET"
echo "export AWS_SESSION_TOKEN=$TOKEN"

echo "echo \"Sessão ativa até: $EXPIRA\"" >&2
