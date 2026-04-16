#!/bin/bash
set -euo pipefail

# Perfil AWS a usar, default awscli
read -p "Perfil AWS (ou ENTER para awscli): " AWS_PROFILE
AWS_PROFILE="${AWS_PROFILE:-awscli}"

echo "Validando credenciais do profile '$AWS_PROFILE'..."
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --output text >/dev/null 2>&1; then
  echo "profile '$AWS_PROFILE' inválido/expirado ou não configurado."
  echo "Use aws configure --profile $AWS_PROFILE ou aws sso login --profile $AWS_PROFILE"
  exit 1
fi

read -p "Nome do bucket (único global): " BUCKET_NAME
read -p "Região (ex: us-east-1): " AWS_REGION

if [ -z "$BUCKET_NAME" ] || [ -z "$AWS_REGION" ]; then
  echo "Nome e região são obrigatórios."
  exit 1
fi

echo "Criando bucket $BUCKET_NAME em $AWS_REGION..."
if [ "$AWS_REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" \
    --profile "$AWS_PROFILE"
fi

echo "Tentando definir ACL private..."
if aws s3api put-bucket-acl \
  --bucket "$BUCKET_NAME" \
  --acl private \
  --profile "$AWS_PROFILE" 2>/tmp/s3acl.$$; then
  echo "ACL private aplicada."
else
  ERR=$(cat /tmp/s3acl.$$)
  echo "Não foi possível aplicar ACL: $ERR"
  if echo "$ERR" | grep -q "AccessControlListNotSupported"; then
    echo "Bucket está com Object Ownership BucketOwnerEnforced (ACL desativada)."
    echo "Configurando ownership controls (BucketOwnerEnforced)..."
    aws s3api put-bucket-ownership-controls \
      --bucket "$BUCKET_NAME" \
      --ownership-controls Rules=[{ObjectOwnership=BucketOwnerEnforced}] \
      --profile "$AWS_PROFILE"
    echo "Ownership controls configurado."
  else
    echo "Verifique se você tem permissão s3:PutBucketAcl ou se o bucket não é de outro dono."
  fi
fi
rm -f /tmp/s3acl.$$

echo "Bucket $BUCKET_NAME criado em $AWS_REGION usando profile $AWS_PROFILE."
echo "Verifique com: aws s3 ls --profile $AWS_PROFILE"