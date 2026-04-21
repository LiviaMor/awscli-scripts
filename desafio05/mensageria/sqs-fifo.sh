#!/bin/bash
# SQS FIFO Queue - Criar fila, enviar e ler mensagens com ordenação garantida
# FIFO = First In, First Out (ordem garantida + deduplicação)
# Fonte: https://docs.aws.amazon.com/cli/latest/reference/sqs/

REGION="us-east-1"
export AWS_PROFILE=awscli
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "=========================================="
echo "   SQS FIFO - Menu Interativo"
echo "=========================================="
echo ""
echo "  FIFO garante:"
echo "  ✔ Ordem de entrega (First In, First Out)"
echo "  ✔ Exatamente uma entrega (deduplicação)"
echo "  ✔ Agrupamento por MessageGroupId"
echo ""
echo "--- Filas ---"
echo "1) Listar filas FIFO"
echo "2) Criar fila FIFO"
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
echo "10) Criar fila FIFO com Dead Letter Queue"
echo ""
echo "0) Sair"
echo ""
read -p "Escolha uma opção: " OPCAO

# Função para listar e escolher fila FIFO
escolher_fila_fifo() {
  QUEUES=$(aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null)
  if [[ -z "$QUEUES" ]]; then
    echo "Nenhuma fila encontrada."
    exit 0
  fi
  echo "Filas FIFO disponíveis:"
  for Q in $QUEUES; do
    [[ "$Q" != *.fifo ]] && continue
    echo "  📨 $(basename $Q)"
  done
  echo ""
  read -p "URL da fila (.fifo): " QUEUE_URL
}

case $OPCAO in
  1)
    echo "Filas SQS FIFO:"
    QUEUES=$(aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null)
    if [[ -z "$QUEUES" ]]; then
      echo "Nenhuma fila encontrada."
      exit 0
    fi
    FOUND=false
    for Q in $QUEUES; do
      [[ "$Q" != *.fifo ]] && continue
      FOUND=true
      NAME=$(basename "$Q")
      MSGS=$(aws sqs get-queue-attributes --queue-url "$Q" --attribute-names ApproximateNumberOfMessages --region $REGION --query 'Attributes.ApproximateNumberOfMessages' --output text 2>/dev/null)
      echo "  📨 $NAME | Mensagens: $MSGS"
    done
    [[ "$FOUND" == false ]] && echo "Nenhuma fila FIFO encontrada."
    ;;

  2)
    read -p "Nome da fila (sem .fifo): " QUEUE_NAME
    [[ -z "$QUEUE_NAME" ]] && echo "Erro: nome obrigatório." && exit 1
    QUEUE_NAME="${QUEUE_NAME}.fifo"
    echo ""
    echo "Configurações (ENTER para padrão):"
    read -p "  Visibility Timeout em segundos (padrão 30): " VIS
    VIS=${VIS:-30}
    read -p "  Deduplicação baseada no conteúdo? (s/n, padrão s): " DEDUP
    DEDUP=${DEDUP:-s}
    [[ "$DEDUP" == "s" ]] && DEDUP_VAL="true" || DEDUP_VAL="false"
    echo ""
    echo "Criando fila FIFO: $QUEUE_NAME..."
    aws sqs create-queue \
      --queue-name "$QUEUE_NAME" \
      --attributes "FifoQueue=true,ContentBasedDeduplication=$DEDUP_VAL,VisibilityTimeout=$VIS" \
      --region $REGION
    echo ""
    echo "✅ Fila FIFO criada: $QUEUE_NAME"
    echo "   Deduplicação por conteúdo: $DEDUP_VAL"
    ;;

  3)
    escolher_fila_fifo
    aws sqs get-queue-attributes \
      --queue-url "$QUEUE_URL" \
      --attribute-names All \
      --region $REGION \
      --output table
    ;;

  4)
    escolher_fila_fifo
    read -p "Tem certeza que deseja deletar? (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs delete-queue --queue-url "$QUEUE_URL" --region $REGION
    echo "✅ Fila deletada!"
    ;;

  5)
    escolher_fila_fifo
    read -p "MessageGroupId (agrupa mensagens, ex: pedidos): " GROUP_ID
    [[ -z "$GROUP_ID" ]] && echo "Erro: GroupId obrigatório em FIFO." && exit 1
    read -p "Mensagem: " MSG
    [[ -z "$MSG" ]] && echo "Erro: mensagem obrigatória." && exit 1

    # Verificar se a fila tem deduplicação por conteúdo
    DEDUP=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names ContentBasedDeduplication --region $REGION --query 'Attributes.ContentBasedDeduplication' --output text 2>/dev/null)

    CMD="aws sqs send-message --queue-url $QUEUE_URL --message-body \"$MSG\" --message-group-id $GROUP_ID --region $REGION"
    if [[ "$DEDUP" != "true" ]]; then
      DEDUP_ID=$(date +%s%N)
      CMD="$CMD --message-deduplication-id $DEDUP_ID"
    fi
    eval $CMD
    echo "✅ Mensagem enviada! (grupo: $GROUP_ID)"
    ;;

  6)
    escolher_fila_fifo
    read -p "MessageGroupId para o lote: " GROUP_ID
    [[ -z "$GROUP_ID" ]] && echo "Erro: GroupId obrigatório." && exit 1
    echo "Digite as mensagens (máx 10). Linha vazia para parar:"
    ENTRIES="["
    i=1
    while [[ $i -le 10 ]]; do
      read -p "  Mensagem $i: " MSG
      [[ -z "$MSG" ]] && break
      [[ $i -gt 1 ]] && ENTRIES="$ENTRIES,"
      DEDUP_ID=$(date +%s%N)$i
      ENTRIES="$ENTRIES{\"Id\":\"msg$i\",\"MessageBody\":\"$MSG\",\"MessageGroupId\":\"$GROUP_ID\",\"MessageDeduplicationId\":\"$DEDUP_ID\"}"
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
    echo "✅ Lote enviado! (grupo: $GROUP_ID)"
    ;;

  7)
    escolher_fila_fifo
    read -p "Quantidade (máx 10, padrão 1): " QTD
    QTD=${QTD:-1}
    read -p "Wait time em segundos (padrão 5): " WAIT
    WAIT=${WAIT:-5}
    echo "Lendo mensagens (ordem FIFO garantida)..."
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
    escolher_fila_fifo
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
    escolher_fila_fifo
    read -p "ATENÇÃO: Isso remove TODAS as mensagens! (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws sqs purge-queue --queue-url "$QUEUE_URL" --region $REGION
    echo "✅ Fila limpa!"
    ;;

  10)
    read -p "Nome da fila principal (sem .fifo): " MAIN_NAME
    [[ -z "$MAIN_NAME" ]] && echo "Erro: nome obrigatório." && exit 1
    DLQ_NAME="${MAIN_NAME}-dlq"
    read -p "Nome da DLQ (padrão $DLQ_NAME): " DLQ_INPUT
    DLQ_NAME=${DLQ_INPUT:-$DLQ_NAME}
    read -p "Máx tentativas antes da DLQ (padrão 3): " MAX_RCV
    MAX_RCV=${MAX_RCV:-3}

    echo "Criando DLQ FIFO: ${DLQ_NAME}.fifo..."
    DLQ_URL=$(aws sqs create-queue \
      --queue-name "${DLQ_NAME}.fifo" \
      --attributes "FifoQueue=true,ContentBasedDeduplication=true" \
      --region $REGION --query 'QueueUrl' --output text)
    DLQ_ARN=$(aws sqs get-queue-attributes --queue-url "$DLQ_URL" --attribute-names QueueArn --region $REGION --query 'Attributes.QueueArn' --output text)

    echo "Criando fila principal: ${MAIN_NAME}.fifo..."
    POLICY="{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":\"$MAX_RCV\"}"
    aws sqs create-queue \
      --queue-name "${MAIN_NAME}.fifo" \
      --attributes "{\"FifoQueue\":\"true\",\"ContentBasedDeduplication\":\"true\",\"RedrivePolicy\":\"$(echo $POLICY | sed 's/"/\\"/g')\"}" \
      --region $REGION

    echo ""
    echo "✅ Fila FIFO: ${MAIN_NAME}.fifo"
    echo "✅ DLQ FIFO: ${DLQ_NAME}.fifo (após $MAX_RCV tentativas)"
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
