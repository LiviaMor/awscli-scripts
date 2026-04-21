#!/bin/bash
# Script interativo para mensageria com Amazon SQS
# Criar filas, enviar, ler e deletar mensagens
# Fonte: https://docs.aws.amazon.com/cli/latest/reference/sqs/

REGION="us-east-1"

echo "=========================================="
echo "   SQS - Mensageria - Menu Interativo"
echo "=========================================="
echo ""
echo "--- Filas ---"
echo "1) Listar filas"
echo "2) Criar fila"
echo "3) Deletar fila"
echo "4) Atributos de uma fila"
echo ""
echo "--- Mensagens ---"
echo "5) Enviar mensagem"
echo "6) Ler mensagens"
echo "7) Deletar mensagem"
echo "8) Purge (limpar todas as mensagens)"
echo ""
echo "--- Dead Letter Queue ---"
echo "9) Criar fila DLQ"
echo ""
echo "0) Sair"
echo ""
read -p "Escolha uma opção: " OPCAO

case $OPCAO in
  1)
    echo "Listando filas SQS..."
    QUEUES=$(aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null)
    if [[ -z "$QUEUES" ]]; then
      echo "Nenhuma fila encontrada."
    else
      for Q in $QUEUES; do
        NAME=$(basename "$Q")
        ATTRS=$(aws sqs get-queue-attributes --queue-url "$Q" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --region $REGION --query 'Attributes' --output json 2>/dev/null)
        MSGS=$(echo "$ATTRS" | grep -o '"ApproximateNumberOfMessages":"[^"]*"' | cut -d'"' -f4)
        INFLIGHT=$(echo "$ATTRS" | grep -o '"ApproximateNumberOfMessagesNotVisible":"[^"]*"' | cut -d'"' -f4)
        echo "  📨 $NAME | Mensagens: $MSGS | Em processamento: $INFLIGHT"
      done
    fi
    ;;

  2)
    read -p "Nome da fila: " QUEUE_NAME
    [[ -z "$QUEUE_NAME" ]] && echo "Erro: nome obrigatório." && exit 1
    read -p "Tempo de visibilidade em segundos (padrão 30): " VISIBILITY
    VISIBILITY=${VISIBILITY:-30}
    read -p "Tempo de retenção em segundos (padrão 345600 = 4 dias): " RETENTION
    RETENTION=${RETENTION:-345600}
    echo "Criando fila $QUEUE_NAME..."
    aws sqs create-queue \
      --queue-name "$QUEUE_NAME" \
      --attributes "VisibilityTimeout=$VISIBILITY,MessageRetentionPeriod=$RETENTION" \
      --region $REGION
    echo "Fila criada!"
    ;;

  3)
    echo "Filas disponíveis:"
    aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output table
    echo ""
    read -p "URL da fila para deletar: " QUEUE_URL
    [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
    read -p "Tem certeza? (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs delete-queue --queue-url "$QUEUE_URL" --region $REGION
    echo "Fila deletada!"
    ;;

  4)
    echo "Filas disponíveis:"
    aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output table
    echo ""
    read -p "URL da fila: " QUEUE_URL
    [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
    aws sqs get-queue-attributes \
      --queue-url "$QUEUE_URL" \
      --attribute-names All \
      --region $REGION \
      --output table
    ;;

  5)
    echo "Filas disponíveis:"
    aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output table
    echo ""
    read -p "URL da fila: " QUEUE_URL
    [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
    read -p "Mensagem: " MSG_BODY
    [[ -z "$MSG_BODY" ]] && echo "Erro: mensagem obrigatória." && exit 1
    echo "Enviando mensagem..."
    aws sqs send-message \
      --queue-url "$QUEUE_URL" \
      --message-body "$MSG_BODY" \
      --region $REGION
    echo "Mensagem enviada!"
    ;;

  6)
    echo "Filas disponíveis:"
    aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output table
    echo ""
    read -p "URL da fila: " QUEUE_URL
    [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
    read -p "Quantidade de mensagens (máx 10, padrão 1): " MAX_MSGS
    MAX_MSGS=${MAX_MSGS:-1}
    read -p "Tempo de espera em segundos (padrão 5): " WAIT_TIME
    WAIT_TIME=${WAIT_TIME:-5}
    echo "Lendo mensagens..."
    RESULT=$(aws sqs receive-message \
      --queue-url "$QUEUE_URL" \
      --max-number-of-messages "$MAX_MSGS" \
      --wait-time-seconds "$WAIT_TIME" \
      --attribute-names All \
      --region $REGION \
      --output json)
    if [[ "$RESULT" == "" || "$RESULT" == "null" || $(echo "$RESULT" | grep -c "Messages") -eq 0 ]]; then
      echo "Nenhuma mensagem na fila."
    else
      echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
    fi
    ;;

  7)
    echo "Filas disponíveis:"
    aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output table
    echo ""
    read -p "URL da fila: " QUEUE_URL
    [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
    echo "Lendo mensagem para obter ReceiptHandle..."
    RESULT=$(aws sqs receive-message \
      --queue-url "$QUEUE_URL" \
      --max-number-of-messages 1 \
      --region $REGION \
      --output json)
    RECEIPT=$(echo "$RESULT" | grep -o '"ReceiptHandle":"[^"]*"' | head -1 | cut -d'"' -f4)
    BODY=$(echo "$RESULT" | grep -o '"Body":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -z "$RECEIPT" ]]; then
      echo "Nenhuma mensagem para deletar."
      exit 0
    fi
    echo "Mensagem: $BODY"
    read -p "Deletar esta mensagem? (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs delete-message \
      --queue-url "$QUEUE_URL" \
      --receipt-handle "$RECEIPT" \
      --region $REGION
    echo "Mensagem deletada!"
    ;;

  8)
    echo "Filas disponíveis:"
    aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output table
    echo ""
    read -p "URL da fila para limpar: " QUEUE_URL
    [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
    read -p "Tem certeza? Isso remove TODAS as mensagens! (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs purge-queue --queue-url "$QUEUE_URL" --region $REGION
    echo "Fila limpa!"
    ;;

  9)
    read -p "Nome da fila principal: " MAIN_QUEUE
    DLQ_NAME="${MAIN_QUEUE}-dlq"
    read -p "Nome da DLQ (padrão $DLQ_NAME): " DLQ_INPUT
    DLQ_NAME=${DLQ_INPUT:-$DLQ_NAME}
    read -p "Máximo de tentativas antes de ir pra DLQ (padrão 3): " MAX_RECEIVE
    MAX_RECEIVE=${MAX_RECEIVE:-3}

    echo "Criando DLQ: $DLQ_NAME..."
    DLQ_URL=$(aws sqs create-queue \
      --queue-name "$DLQ_NAME" \
      --region $REGION \
      --query 'QueueUrl' --output text)
    DLQ_ARN=$(aws sqs get-queue-attributes \
      --queue-url "$DLQ_URL" \
      --attribute-names QueueArn \
      --region $REGION \
      --query 'Attributes.QueueArn' --output text)

    echo "Criando fila principal: $MAIN_QUEUE com DLQ..."
    aws sqs create-queue \
      --queue-name "$MAIN_QUEUE" \
      --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"$MAX_RECEIVE\\\"}\"}" \
      --region $REGION
    echo ""
    echo "✅ Fila: $MAIN_QUEUE"
    echo "✅ DLQ: $DLQ_NAME (após $MAX_RECEIVE tentativas)"
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
