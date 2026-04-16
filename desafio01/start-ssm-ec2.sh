#!/bin/bash

# Script para conectar numa instância EC2 via SSM Session Manager
# Requisitos:
# - aws cli v2 configurado (perfil, região)
# - instância EC2 com SSM Agent ativo e role IAM com AmazonSSMManagedInstanceCore
# - instância em estado running

read -p "ID da instância EC2: " INSTANCE_ID

if [ -z "$INSTANCE_ID" ]; then
  echo "ID da instância é obrigatório."
  exit 1
fi

echo "Verificando estado e managed instance..."
INFO=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[State.Name, InstanceId]' --output text 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$INFO" ]; then
  echo "Instância não encontrada ou sem permissão."
  exit 1
fi

STATE=$(echo "$INFO" | awk '{print $1}')
if [ "$STATE" != "running" ]; then
  echo "Instância está $STATE. Precisa estar running."
  exit 1
fi

echo "Iniciando sessão SSM na instância $INSTANCE_ID..."
aws ssm start-session --target "$INSTANCE_ID"