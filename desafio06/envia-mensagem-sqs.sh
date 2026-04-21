#!/bin/bash
# Envia mensagens para fila SQS
# Uso: ./envia-mensagem-sqs.sh

REGION="us-east-1"
export AWS_PROFILE=awscli
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "=========================================="
echo "   Enviar Mensagens para SQS"
echo "=========================================="

# Listar filas
echo ""
echo "Filas disponíveis:"
aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null | tr '\t' '\n' | while read Q; do
  echo "  📨 $(basename $Q)"
done

echo ""
read -p "URL da fila: " QUEUE_URL
[[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1

echo ""
echo "1) Enviar uma mensagem"
echo "2) Enviar várias mensagens"
echo "3) Enviar mensagem JSON"
echo ""
read -p "Escolha: " OPCAO

case $OPCAO in
  1)
    read -p "Mensagem: " MSG
    [[ -z "$MSG" ]] && echo "Erro: mensagem obrigatória." && exit 1

    # Verificar se é fila FIFO
    if [[ "$QUEUE_URL" == *.fifo ]]; then
      read -p "MessageGroupId: " GROUP_ID
      GROUP_ID=${GROUP_ID:-default}
      aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$MSG" \
        --message-group-id "$GROUP_ID" \
        --region $REGION
    else
      aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$MSG" \
        --region $REGION
    fi
    echo "✅ Mensagem enviada!"
    ;;

  2)
    read -p "Quantas mensagens? " QTD
    [[ -z "$QTD" ]] && echo "Erro: quantidade obrigatória." && exit 1

    for i in $(seq 1 $QTD); do
      MSG="Mensagem #$i - $(date '+%H:%M:%S')"
      if [[ "$QUEUE_URL" == *.fifo ]]; then
        aws sqs send-message \
          --queue-url "$QUEUE_URL" \
          --message-body "$MSG" \
          --message-group-id "lote" \
          --message-deduplication-id "msg-$i-$(date +%s%N)" \
          --region $REGION --output text --query 'MessageId'
      else
        aws sqs send-message \
          --queue-url "$QUEUE_URL" \
          --message-body "$MSG" \
          --region $REGION --output text --query 'MessageId'
      fi
      echo "  ✅ Enviada: $MSG"
    done
    echo ""
    echo "✅ $QTD mensagens enviadas!"
    ;;

  3)
    echo "Digite o JSON (ex: {\"pedido\":123,\"produto\":\"camiseta\"}):"
    read -p "> " JSON_MSG
    [[ -z "$JSON_MSG" ]] && echo "Erro: JSON obrigatório." && exit 1

    if [[ "$QUEUE_URL" == *.fifo ]]; then
      read -p "MessageGroupId: " GROUP_ID
      GROUP_ID=${GROUP_ID:-default}
      aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$JSON_MSG" \
        --message-group-id "$GROUP_ID" \
        --region $REGION
    else
      aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$JSON_MSG" \
        --region $REGION
    fi
    echo "✅ Mensagem JSON enviada!"
    ;;

  *)
    echo "Opção inválida."
    exit 1
    ;;
esac
