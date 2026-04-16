#!/bin/bash
# Este script assume uma role temporária, exporta as credenciais para um arquivo e executa um container Docker com essas credenciais.
AWS_CONFIG_ENV=./.env.aws
docker run --rm --env-file=$AWS_CONFIG_ENV -v "/home/livia/desafiolabs/desafio01/arquivo.txt:/arquivo.txt" -ti automacao-awscli