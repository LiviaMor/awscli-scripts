#!/bin/bash
# Usage:
#   source ./set-aws-temp-creds.sh
#   # or
#   eval "$(./set-aws-temp-creds.sh)"
#
# This script assumes a role via STS and prints export statements for the
# temporary credentials so they can be used in the current shell session.
# 
# Esse script assume uma role via STS e imprime as declarações de exportação 
# para as credenciais temporárias, para que possam ser usadas na sessão atual do shell.
set -euo pipefail

PROFILE=${1:-awscli}
ROLE_ARN=${2:-arn:aws:iam::794038217446:role/role-time-dev}
SESSION_NAME=${3:-vm-livia}

# Get temporary credentials
CREDENTIALS=$(aws sts assume-role \
  --profile "${PROFILE}" \
  --role-arn "${ROLE_ARN}" \
  --role-session-name "${SESSION_NAME}" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

if [[ -z "$CREDENTIALS" ]]; then
  echo "Failed to assume role: ${ROLE_ARN}" >&2
  exit 1
fi

read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$CREDENTIALS"

cat <<EOF
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
EOF
