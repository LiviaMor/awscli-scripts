#!/bin/bash
# SQS Standard Queue - Criar fila, enviar e ler mensagens
# Fonte: https://docs.aws.amazon.com/cli/latest/reference/sqs/

REGION="us-east-1"
export AWS_PROFILE=awscli
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "=========================================="
echo "   SQS Standard - Menu Interativo"
echo "=========================================="
echo ""
echo "--- Filas ---"
echo "1) Listar filas Standard"
echo "2) Criar fila Standard"
echo "3) Atributos de uma fila"
echo "4) Deletar fila"
echo ""
echo "--- Mensagens ---"
echo "5) Enviar mensagem"
echo "6) Enviar mensagem em lote (batch)"
echo "7) Ler mensagens"
echo "8) Deletar mensagem após leitura"
echo "9) Purge (limpar fila)"
echo ""
echo "--- DLQ ---"
echo "10) Criar fila com Dead Letter Queue"
echo ""
echo "0) Sair"
echo ""
read -p "Escolha uma opção: " OPCAO

# Função para listar e escolher fila
escolher_fila() {
  QUEUES=$(aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null)
  if [[ -z "$QUEUES" ]]; then
    echo "Nenhuma fila encontrada."
    exit 0
  fi
  echo "Filas disponíveis:"
  i=1
  for Q in $QUEUES; do
    echo "  $i) $(basename $Q)"
    i=$((i+1))
  done
  echo ""
  read -p "URL da fila: " QUEUE_URL
}

case $OPCAO in
  1)
    echo "Filas SQS Standard:"
    QUEUES=$(aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null)
    if [[ -z "$QUEUES" ]]; then
      echo "Nenhuma fila encontrada."
      exit 0
    fi
    for Q in $QUEUES; do
      # Ignorar filas FIFO
      [[ "$Q" == *.fifo ]] && continue
      NAME=$(basename "$Q")
      MSGS=$(aws sqs get-queue-attributes --queue-url "$Q" --attribute-names ApproximateNumberOfMessages --region $REGION --query 'Attributes.ApproximateNumberOfMessages' --output text 2>/dev/null)
      echo "  📨 $NAME | Mensagens: $MSGS"
    done
    ;;

  2)
    read -p "Nome da fila: " QUEUE_NAME
    [[ -z "$QUEUE_NAME" ]] && echo "Erro: nome obrigatório." && exit 1
    echo ""
    echo "Configurações (ENTER para padrão):"
    read -p "  Visibility Timeout em segundos (padrão 30): " VIS
    VIS=${VIS:-30}
    read -p "  Retenção de mensagem em segundos (padrão 345600 = 4 dias): " RET
    RET=${RET:-345600}
    read -p "  Delay em segundos (padrão 0): " DELAY
    DELAY=${DELAY:-0}
    echo ""
    echo "Criando fila Standard: $QUEUE_NAME..."
    aws sqs create-queue \
      --queue-name "$QUEUE_NAME" \
      --attributes "VisibilityTimeout=$VIS,MessageRetentionPeriod=$RET,DelaySeconds=$DELAY" \
      --region $REGION
    ;;

  3)
    escolher_fila
    aws sqs get-queue-attributes \
      --queue-url "$QUEUE_URL" \
      --attribute-names All \
      --region $REGION \
      --output table
    ;;

  4)
    escolher_fila
    read -p "Tem certeza que deseja deletar? (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs delete-queue --queue-url "$QUEUE_URL" --region $REGION
    echo "Fila deletada!"
    ;;

  5)
    escolher_fila
    read -p "Mensagem: " MSG
    [[ -z "$MSG" ]] && echo "Erro: mensagem obrigatória." && exit 1
    aws sqs send-message \
      --queue-url "$QUEUE_URL" \
      --message-body "$MSG" \
      --region $REGION
    echo "✅ Mensagem enviada!"
    ;;

  6)
    escolher_fila
    echo "Digite as mensagens (máx 10). Linha vazia para parar:"
    ENTRIES="["
    i=1
    while [[ $i -le 10 ]]; do
      read -p "  Mensagem $i: " MSG
      [[ -z "$MSG" ]] && break
      [[ $i -gt 1 ]] && ENTRIES="$ENTRIES,"
      ENTRIES="$ENTRIES{\"Id\":\"msg$i\",\"MessageBody\":\"$MSG\"}"
      i=$((i+1))
    done
    ENTRIES="$ENTRIES]"
    if [[ "$ENTRIES" == "[]" ]]; then
      echo "Nenhuma mensagem informada."
      exit 0
    fi
    aws sqs send-message-batch \
      --queue-url "$QUEUE_URL" \
      --entries "$ENTRIES" \
      --region $REGION
    echo "✅ Lote enviado!"
    ;;

  7)
    escolher_fila
    read -p "Quantidade (máx 10, padrão 1): " QTD
    QTD=${QTD:-1}
    read -p "Wait time em segundos (padrão 5): " WAIT
    WAIT=${WAIT:-5}
    echo "Lendo mensagens..."
    RESULT=$(aws sqs receive-message \
      --queue-url "$QUEUE_URL" \
      --max-number-of-messages "$QTD" \
      --wait-time-seconds "$WAIT" \
      --attribute-names All \
      --region $REGION \
      --output json 2>/dev/null)
    if [[ -z "$RESULT" || $(echo "$RESULT" | grep -c "Messages") -eq 0 ]]; then
      echo "Nenhuma mensagem na fila."
    else
      echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
    fi
    ;;

  8)
    escolher_fila
    echo "Lendo próxima mensagem..."
    RESULT=$(aws sqs receive-message \
      --queue-url "$QUEUE_URL" \
      --max-number-of-messages 1 \
      --region $REGION --output json 2>/dev/null)
    BODY=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Messages'][0]['Body'])" 2>/dev/null)
    RECEIPT=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Messages'][0]['ReceiptHandle'])" 2>/dev/null)
    if [[ -z "$RECEIPT" ]]; then
      echo "Nenhuma mensagem para deletar."
      exit 0
    fi
    echo "Mensagem: $BODY"
    read -p "Deletar? (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs delete-message --queue-url "$QUEUE_URL" --receipt-handle "$RECEIPT" --region $REGION
    echo "✅ Mensagem deletada!"
    ;;

  9)
    escolher_fila
    read -p "ATENÇÃO: Isso remove TODAS as mensagens! (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs purge-queue --queue-url "$QUEUE_URL" --region $REGION
    echo "✅ Fila limpa!"
    ;;

  10)
    read -p "Nome da fila principal: " MAIN_NAME
    [[ -z "$MAIN_NAME" ]] && echo "Erro: nome obrigatório." && exit 1
    DLQ_NAME="${MAIN_NAME}-dlq"
    read -p "Nome da DLQ (padrão $DLQ_NAME): " DLQ_INPUT
    DLQ_NAME=${DLQ_INPUT:-$DLQ_NAME}
    read -p "Máx tentativas antes da DLQ (padrão 3): " MAX_RCV
    MAX_RCV=${MAX_RCV:-3}

    echo "Criando DLQ: $DLQ_NAME..."
    DLQ_URL=$(aws sqs create-queue --queue-name "$DLQ_NAME" --region $REGION --query 'QueueUrl' --output text)
    DLQ_ARN=$(aws sqs get-queue-attributes --queue-url "$DLQ_URL" --attribute-names QueueArn --region $REGION --query 'Attributes.QueueArn' --output text)

    echo "Criando fila principal: $MAIN_NAME..."
    POLICY="{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":\"$MAX_RCV\"}"
    aws sqs create-queue \
      --queue-name "$MAIN_NAME" \
      --attributes "{\"RedrivePolicy\":\"$(echo $POLICY | sed 's/"/\\"/g')\"}" \
      --region $REGION

    echo ""
    echo "✅ Fila: $MAIN_NAME"
    echo "✅ DLQ: $DLQ_NAME (após $MAX_RCV tentativas)"
    echo "✅ DLQ ARN: $DLQ_ARN"
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
