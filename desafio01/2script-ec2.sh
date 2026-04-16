#!/bin/bash
# Este script assume uma role temporária e lista as instâncias EC2 usando as credenciais temporárias.
# Assumir a role temporária (renova credenciais a cada execução)
ROLE_CREDENTIALS=$(aws sts assume-role \
  --role-arn arn:aws:iam::794038217446:role/role-time-dev \
  --role-session-name vm-livia \
  --profile awscli \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$ROLE_CREDENTIALS"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Listar instâncias
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:grupo,Values=AutomacaoAWSCLI" \
  --query 'Reservations[].Instances[].[
InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output text