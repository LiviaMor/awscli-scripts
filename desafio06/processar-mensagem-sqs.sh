#!/bin/bash
# Processador de mensagens SQS
# Roda em loop contínuo com long polling (20s)
# Sem dependência de Python — usa apenas jq

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
QUEUE_URL="${QUEUE_URL}"

# Usar profile awscli se disponível (local), senão usa role da task (ECS)
if [[ -f /root/.aws/credentials || -f ~/.aws/credentials ]]; then
  export AWS_PROFILE=${AWS_PROFILE:-awscli}
fi

if [[ -z "$QUEUE_URL" ]]; then
  echo "Filas disponíveis:"
  aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null | tr '\t' '\n' | while read Q; do
    MSGS=$(aws sqs get-queue-attributes --queue-url "$Q" --attribute-names ApproximateNumberOfMessages --region $REGION --query 'Attributes.ApproximateNumberOfMessages' --output text 2>/dev/null)
    echo "  📨 $(basename $Q) | Mensagens: $MSGS"
  done
  echo ""
  read -p "URL da fila: " QUEUE_URL
  [[ -z "$QUEUE_URL" ]] && echo "❌ URL obrigatória." && exit 1
fi

echo "=========================================="
echo "   Processador de Mensagens SQS"
echo "=========================================="
echo "Fila: $QUEUE_URL"
echo "Região: $REGION"
echo "Aguardando mensagens (long polling 20s)..."
echo ""

TOTAL=0

while true; do
  RESPONSE=$(aws sqs receive-message \
    --queue-url "$QUEUE_URL" \
    --max-number-of-messages 1 \
    --wait-time-seconds 20 \
    --attribute-names All \
    --region $REGION \
    --output json 2>/dev/null)

  # Verificar se response está vazio ou sem mensagens
  if [[ -z "$RESPONSE" ]] || ! echo "$RESPONSE" | jq -e '.Messages[0]' > /dev/null 2>&1; then
    echo "⏳ $(date '+%H:%M:%S') | Nenhuma mensagem. Aguardando..."
    continue
  fi

  # Extrair dados com jq
  MSG_ID=$(echo "$RESPONSE" | jq -r '.Messages[0].MessageId')
  MSG_BODY=$(echo "$RESPONSE" | jq -r '.Messages[0].Body')
  RECEIPT=$(echo "$RESPONSE" | jq -r '.Messages[0].ReceiptHandle')

  # Exibir mensagem
  echo "──────────────────────────────────────"
  echo "📩 $(date '+%H:%M:%S') | Mensagem recebida"
  echo "   ID: $MSG_ID"
  echo "   Conteúdo: $MSG_BODY"

  # Iniciar processamento
  START=$(date +%s%N)
  echo "   ⏳ Processando..."

  # === LÓGICA DE PROCESSAMENTO AQUI ===
  sleep 1
  # =====================================

  # Calcular tempo
  END=$(date +%s%N)
  DURATION=$(( (END - START) / 1000000 ))
  echo "   ⏱️  Tempo de processamento: ${DURATION}ms"

  # Excluir mensagem da fila
  aws sqs delete-message \
    --queue-url "$QUEUE_URL" \
    --receipt-handle "$RECEIPT" \
    --region $REGION 2>/dev/null

  if [[ $? -eq 0 ]]; then
    echo "   ✅ Mensagem processada e excluída da fila!"
  else
    echo "   ❌ Erro ao excluir mensagem"
  fi

  TOTAL=$((TOTAL+1))
  echo "   📊 Total processado: $TOTAL"
done
