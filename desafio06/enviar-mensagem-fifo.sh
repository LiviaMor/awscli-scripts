#!/bin/bash
# Enviar mensagens para fila SQS FIFO
# FIFO requer MessageGroupId e MessageDeduplicationId
# Uso: ./enviar-mensagem-fifo.sh

REGION="us-east-1"
QUEUE_URL="${QUEUE_URL}"

echo "=========================================="
echo "   Enviar Mensagem - SQS FIFO"
echo "=========================================="

# Se não tem QUEUE_URL, listar filas FIFO
if [[ -z "$QUEUE_URL" ]]; then
  echo "Filas FIFO disponíveis:"
  aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null | tr '\t' '\n' | while read Q; do
    [[ "$Q" == *.fifo ]] && echo "  📨 $Q"
  done
  echo ""
  read -p "URL da fila (.fifo): " QUEUE_URL
  [[ -z "$QUEUE_URL" ]] && echo "❌ URL obrigatória." && exit 1
fi

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
    read -p "MessageGroupId (ex: pedidos, pagamentos): " GROUP_ID
    [[ -z "$GROUP_ID" ]] && echo "❌ GroupId obrigatório em FIFO." && exit 1
    read -p "Mensagem: " MSG
    [[ -z "$MSG" ]] && echo "❌ Mensagem obrigatória." && exit 1
    aws sqs send-message \
      --queue-url "$QUEUE_URL" \
      --message-body "$MSG" \
      --message-group-id "$GROUP_ID" \
      --message-deduplication-id "$(date +%s%N)" \
      --region $REGION
    echo "✅ Mensagem enviada! (grupo: $GROUP_ID)"
    ;;

  2)
    read -p "MessageGroupId: " GROUP_ID
    [[ -z "$GROUP_ID" ]] && echo "❌ GroupId obrigatório." && exit 1
    read -p "Quantas mensagens? " QTD
    [[ -z "$QTD" ]] && echo "❌ Quantidade obrigatória." && exit 1
    for i in $(seq 1 $QTD); do
      MSG="Mensagem FIFO #$i - $(date '+%H:%M:%S')"
      aws sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$MSG" \
        --message-group-id "$GROUP_ID" \
        --message-deduplication-id "$(date +%s%N)-$i" \
        --region $REGION \
        --output text --query 'MessageId'
      echo "  ✅ Enviada: $MSG (grupo: $GROUP_ID, ordem: $i)"
    done
    echo ""
    echo "✅ $QTD mensagens enviadas em ordem FIFO!"
    ;;

  3)
    read -p "MessageGroupId: " GROUP_ID
    [[ -z "$GROUP_ID" ]] && echo "❌ GroupId obrigatório." && exit 1
    echo "Digite o JSON (ex: {\"pedido\":123,\"produto\":\"camiseta\"}):"
    read -p "> " JSON_MSG
    [[ -z "$JSON_MSG" ]] && echo "❌ JSON obrigatório." && exit 1
    aws sqs send-message \
      --queue-url "$QUEUE_URL" \
      --message-body "$JSON_MSG" \
      --message-group-id "$GROUP_ID" \
      --message-deduplication-id "$(date +%s%N)" \
      --region $REGION
    echo "✅ Mensagem JSON enviada! (grupo: $GROUP_ID)"
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
