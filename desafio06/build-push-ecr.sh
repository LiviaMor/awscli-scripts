#!/bin/bash
# Build e push da imagem do processador SQS para ECR
set -e

REGION="us-east-1"
ACCOUNT_ID="794038217446"
REPO_NAME="formacao-mensageria/processar"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"
export AWS_PROFILE=awscli
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "=========================================="
echo "   Build & Push Processador SQS → ECR"
echo "=========================================="

# Criar repositório (ignora se já existe)
echo "--- Verificando repositório ECR ---"
aws ecr create-repository --repository-name $REPO_NAME --region $REGION 2>/dev/null && echo "Repositório criado!" || echo "Repositório já existe."

# Login no ECR
echo ""
echo "--- Login no ECR ---"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build
echo ""
echo "--- Build da imagem ---"
docker build -t $REPO_NAME:latest .

# Tag e Push
echo ""
echo "--- Push para ECR ---"
docker tag $REPO_NAME:latest $ECR_URI:latest
docker push $ECR_URI:latest

echo ""
echo "=========================================="
echo "✅ Imagem enviada: $ECR_URI:latest"
echo "=========================================="
