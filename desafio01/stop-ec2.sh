#!/bin/bash

# Assumir a role temporária
ROLE_CREDENTIALS=$(aws sts assume-role \
  --role-arn arn:aws:iam::794038217446:role/role-time-dev \
  --role-session-name vm-livia \
  --profile awscli \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$ROLE_CREDENTIALS"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Listar instâncias disponíveis
echo "Instâncias disponíveis:"
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:grupo,Values=AutomacaoAWSCLI" \
  --query 'Reservations[].Instances[].[
InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Perguntar qual instância parar
echo ""
read -p "Digite o ID da instância que deseja parar: " INSTANCE_ID

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Erro: ID da instância não pode ser vazio."
  exit 1
fi

# Parar a instância
echo "Parando instância $INSTANCE_ID..."
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --region us-east-1

echo "Instância $INSTANCE_ID parada com sucesso!"