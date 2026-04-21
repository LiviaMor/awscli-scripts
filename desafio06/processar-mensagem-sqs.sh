#!/bin/bash
# Processa mensagens da fila SQS
# Exibe mensagem, tempo de processamento, e exclui após processar
# Uso: ./processar-mensagem-sqs.sh [URL_DA_FILA]

REGION="us-east-1"
export AWS_PROFILE=awscli
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

QUEUE_URL=$1

echo "=========================================="
echo "   Processador de Mensagens SQS"
echo "=========================================="

# Se não passou URL como argumento, perguntar
if [[ -z "$QUEUE_URL" ]]; then
  echo ""
  echo "Filas disponíveis:"
  aws sqs list-queues --region $REGION --query 'QueueUrls[]' --output text 2>/dev/null | tr '\t' '\n' | while read Q; do
    MSGS=$(aws sqs get-queue-attributes --queue-url "$Q" --attribute-names ApproximateNumberOfMessages --region $REGION --query 'Attributes.ApproximateNumberOfMessages' --output text 2>/dev/null)
    echo "  📨 $(basename $Q) | Mensagens: $MSGS"
  done
  echo ""
  read -p "URL da fila: " QUEUE_URL
  [[ -z "$QUEUE_URL" ]] && echo "Erro: URL obrigatória." && exit 1
fi

echo ""
echo "1) Processar uma mensagem"
echo "2) Processar todas as mensagens"
echo "3) Modo contínuo (polling)"
echo ""
read -p "Escolha: " MODO

processar_mensagem() {
  local RESULT=$1
  local BODY=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Messages'][0]['Body'])" 2>/dev/null)
  local RECEIPT=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Messages'][0]['ReceiptHandle'])" 2>/dev/null)
  local MSG_ID=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Messages'][0]['MessageId'])" 2>/dev/null)

  if [[ -z "$RECEIPT" ]]; then
    return 1
  fi

  # Início do processamento
  local START=$(date +%s%N)
  echo "──────────────────────────────────────"
  echo "📩 Mensagem recebida"
  echo "   ID: $MSG_ID"
  echo "   Conteúdo: $BODY"
  echo "   ⏳ Processando..."

  # Simula processamento (aqui você coloca a lógica real)
  sleep 1

  # Fim do processamento
  local END=$(date +%s%N)
  local DURATION=$(( (END - START) / 1000000 ))

  echo "   ⏱️  Tempo de processamento: ${DURATION}ms"

  # Deletar mensagem da fila
  aws sqs delete-message \
    --queue-url "$QUEUE_URL" \
    --receipt-handle "$RECEIPT" \
    --region $REGION 2>/dev/null

  if [[ $? -eq 0 ]]; then
    echo "   ✅ Mensagem processada e excluída da fila!"
  else
    echo "   ❌ Erro ao excluir mensagem da fila"
  fi

  return 0
}

case $MODO in
  1)
    echo ""
    echo "Buscando mensagem..."
    RESULT=$(aws sqs receive-message \
      --queue-url "$QUEUE_URL" \
      --max-number-of-messages 1 \
      --wait-time-seconds 5 \
      --attribute-names All \
      --region $REGION --output json 2>/dev/null)

    if [[ -z "$RESULT" || $(echo "$RESULT" | grep -c "Messages") -eq 0 ]]; then
      echo "Nenhuma mensagem na fila."
      exit 0
    fi

    processar_mensagem "$RESULT"
    ;;

  2)
    echo ""
    echo "Processando todas as mensagens..."
    TOTAL=0
    while true; do
      RESULT=$(aws sqs receive-message \
        --queue-url "$QUEUE_URL" \
        --max-number-of-messages 10 \
        --wait-time-seconds 3 \
        --attribute-names All \
        --region $REGION --output json 2>/dev/null)

      if [[ -z "$RESULT" || $(echo "$RESULT" | grep -c "Messages") -eq 0 ]]; then
        break
      fi

      # Processar cada mensagem do lote
      COUNT=$(echo "$RESULT" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('Messages',[])))" 2>/dev/null)
      for i in $(seq 0 $((COUNT-1))); do
        SINGLE=$(echo "$RESULT" | python3 -c "
import sys,json
data=json.load(sys.stdin)
msg=data['Messages'][$i]
print(json.dumps({'Messages':[msg]}))" 2>/dev/null)
        processar_mensagem "$SINGLE"
        TOTAL=$((TOTAL+1))
      done
    done
    echo ""
    echo "=========================================="
    echo "✅ Total processado: $TOTAL mensagens"
    echo "=========================================="
    ;;

  3)
    echo ""
    echo "Modo contínuo (Ctrl+C para parar)..."
    echo ""
    TOTAL=0
    while true; do
      RESULT=$(aws sqs receive-message \
        --queue-url "$QUEUE_URL" \
        --max-number-of-messages 1 \
        --wait-time-seconds 20 \
        --attribute-names All \
        --region $REGION --output json 2>/dev/null)

      if [[ -z "$RESULT" || $(echo "$RESULT" | grep -c "Messages") -eq 0 ]]; then
        echo "⏳ Aguardando mensagens... ($(date '+%H:%M:%S'))"
        continue
      fi

      processar_mensagem "$RESULT"
      TOTAL=$((TOTAL+1))
      echo "   📊 Total processado: $TOTAL"
    done
    ;;

  *)
    echo "Opção inválida."
    exit 1
    ;;
esac
