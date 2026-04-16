#!/bin/bash
set -euo pipefail

read -p "Perfil AWS a usar (ex: awscli): " AWS_PROFILE
AWS_PROFILE="${AWS_PROFILE:-awscli}"

export AWS_PROFILE

echo "Profile atual: $AWS_PROFILE"
echo "Teste de identidade:"
aws sts get-caller-identity --profile "$AWS_PROFILE"

echo "Buckets com profile $AWS_PROFILE:"
aws s3 ls --profile "$AWS_PROFILE"