#!/bin/bash
# Build e push da imagem do processador SQS para ECR
set -e

REGION="us-east-1"
ACCOUNT_ID="794038217446"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/formacao-mensageria/processar"
export AWS_PROFILE=awscli
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "=========================================="
echo "   Build & Push Processador SQS → ECR"
echo "=========================================="

# Login no ECR
echo "--- Login no ECR ---"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build
echo "--- Build da imagem ---"
docker build -t processar-sqs:latest .

# Tag e Push
echo "--- Push para ECR ---"
docker tag processar-sqs:latest $ECR_URI:latest
docker push $ECR_URI:latest

echo ""
echo "=========================================="
echo "✅ Imagem enviada: $ECR_URI:latest"
echo "=========================================="
