#!/bin/bash
# Este script assume uma role temporária, lista as instâncias EC2 disponíveis e permite ao usuário escolher uma instância para terminar.



read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$ROLE_CREDENTIALS"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Listar instâncias disponíveis
echo "Instâncias disponíveis:"
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:grupo,Values=AutomacaoAWSCLI" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Perguntar qual instância terminar
echo ""
read -p "Digite o ID da instância que deseja terminar: " INSTANCE_ID

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Erro: ID da instância não pode ser vazio."
  exit 1
fi

# Terminar a instância
echo "Terminando instância $INSTANCE_ID..."
aws ec2 terminate-instances \
  --instance-ids "$INSTANCE_ID" \
  --region us-east-1

echo "Instância $INSTANCE_ID terminada (shutdown) com sucesso!"