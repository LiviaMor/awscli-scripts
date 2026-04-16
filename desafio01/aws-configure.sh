#!/bin/bash
set -euo pipefail

# Verifica se aws cli está instalada
if ! command -v aws &>/dev/null; then
  echo "AWS CLI não encontrada"
  exit 1
fi

# Verifica credenciais válidas
if ! aws sts get-caller-identity --output text >/dev/null 2>&1; then
  echo "Credenciais inválidas ou expiradas."
  echo "1) Verifique ~/.aws/credentials ou vars: AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
  echo "2) Refaça o set-aws-temp-creds / assume-role / aws sso login"
  echo "3) Teste com: aws sts get-caller-identity"
  exit 1
fi

echo "Credenciais válidas."
echo "Buckets disponíveis:"
aws s3 ls

read -p "Enter the bucket name: " BUCKET_NAME
if [ -z "$BUCKET_NAME" ]; then
  echo "Bucket não informado, saindo."
  exit 1
fi

aws s3 ls "s3://$BUCKET_NAME"