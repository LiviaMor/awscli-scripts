#!/bin/bash
# Script para build e push da BIA para ECR
set -e

REGION="us-east-1"
ACCOUNT_ID="794038217446"
REPO_NAME="bia"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"
GIT_REPO="https://github.com/LiviaMor/bia.git"

echo "=========================================="
echo "   Build & Push BIA → ECR"
echo "=========================================="

# 1. Criar repositório ECR (ignora se já existe)
echo ""
echo "--- Criando repositório ECR ---"
aws ecr create-repository --repository-name $REPO_NAME --region $REGION 2>/dev/null && echo "Repositório criado!" || echo "Repositório já existe."

# 2. Login no ECR
echo ""
echo "--- Login no ECR ---"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# 3. Clone do repo
echo ""
echo "--- Clonando repositório ---"
TEMP_DIR=$(mktemp -d)
git clone $GIT_REPO "$TEMP_DIR/bia"
cd "$TEMP_DIR/bia"

# 4. Build da imagem
echo ""
echo "--- Build da imagem ---"
docker build -t $REPO_NAME:latest .

# 5. Tag e Push
echo ""
echo "--- Push para ECR ---"
docker tag $REPO_NAME:latest $ECR_URI:latest
docker push $ECR_URI:latest

# 6. Cleanup
echo ""
echo "--- Limpeza ---"
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "✅ Imagem enviada: $ECR_URI:latest"
echo "=========================================="
echo ""
echo "Force novo deploy no ECS:"
echo "aws ecs update-service --cluster bia-cluster --service bia-service --force-new-deployment --region $REGION"
