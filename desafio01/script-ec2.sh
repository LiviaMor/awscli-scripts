#!/bin/bash

# Assumir a role temporária
ROLE_CREDENTIALS=$(aws sts assume-role \
  --role-arn arn:aws:iam::794038217446:role/role-time-dev \
  --role-session-name vm-livia \
  --profile awscli \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

# Extrair credenciais
read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$ROLE_CREDENTIALS"

# Exportar como variáveis de ambiente
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

# Executar comando EC2
aws ec2 run-instances \
  --image-id ami-02dfbd4ff395f2a1b \
  --instance-type t2.micro \
  --key-name formacao \
  --security-group-ids sg-0349b0097235500ee \
  --subnet-id subnet-004fc006f214f0ad1 \
  --region us-east-1 \
  --count 2 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=grupo,Value=AutomacaoAWSCLI}]' 