#!/bin/bash

# Script para facilitar a configuração de perfis AWS CLI.
# Ele lista os perfis já configurados e permite escolher um perfil existente
# ou criar/editar um novo perfil usando o comando `aws configure`.

set -euo pipefail

# Lista perfis configurados
EXISTING_PROFILES=$(aws configure list-profiles 2>/dev/null || true)

echo "Perfis AWS já configurados neste ambiente:"
if [[ -z "$EXISTING_PROFILES" ]]; then
  echo "  (nenhum perfil encontrado)"
else
  nl -w2 -s". " <<< "$EXISTING_PROFILES"
fi

echo ""
read -p "Use um perfil existente ou informe um novo nome de perfil [default]: " PROFILE
PROFILE=${PROFILE:-default}

echo "Configurando perfil '$PROFILE'..."

aws configure --profile "$PROFILE"

echo "Perfil '$PROFILE' atualizado com sucesso."
