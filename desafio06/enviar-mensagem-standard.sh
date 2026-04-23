#!/bin/bash
# Enviar mensagens para fila SQS Standard
# Uso: ./enviar-mensagem-standard.sh

REGION="us-east-1"
QUEUE_URL="${QUEUE_URL:-https://sqs.us-east-1.amazonaws.com/794038217446/formacao-mensageria}"

echo "=========================================="
echo "   Enviar Mensagem - SQS Standard"
echo "=========================================="
echo "Fila: $(basename $QUEUE_URL)"
echo ""
echo "1) Enviar uma mensagem"
echo "2) Enviar várias mensagens"
echo "3) Enviar mensagem JSON"
echo "0) Sair"
echo ""
read -p "Escolha: " OPCAO

case $OPCAO in
  1)
    read -p "Mensagem: " MSG
    [[ -z "$MSG" ]] && echo "❌ Mensagem obrigatória." && exit 1
    aws sqs send-message \
      --queue-url "$QUEUE_URL" \
      --message-body "$MSG" \
      --region $REGION
    echo "✅ Mensagem enviada!"
    ;;

  2)
    read -p "Quantas mensagens? " QTD
    [[ -z "$QTD" ]] && echo "❌ Quantidade obrigatória." && exit 1
    for i in $(seq 1 $QTD); do
      MSG="Mensagem Standard #$i - $(date '+%H:%M:%S')"
      aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$MSG" \
        --region $REGION \
        --output text --query 'MessageId'
      echo "  ✅ Enviada: $MSG"
    done
    echo ""
    echo "✅ $QTD mensagens enviadas!"
    ;;

  3)
    echo "Digite o JSON (ex: {\"pedido\":123,\"produto\":\"camiseta\"}):"
    read -p "> " JSON_MSG
    [[ -z "$JSON_MSG" ]] && echo "❌ JSON obrigatório." && exit 1
    aws sqs send-message \
      --queue-url "$QUEUE_URL" \
      --message-body "$JSON_MSG" \
      --region $REGION
    echo "✅ Mensagem JSON enviada!"
    ;;

  0)
    echo "Saindo."
    exit 0
    ;;

  *)
    echo "Opção inválida."
    exit 1
    ;;
esac
