#!/bin/bash
# Script para validar infra e analisar custos
REGION="us-east-1"
DOMAIN="formacaoaws.ninehealth.com.br"

echo "=========================================="
echo "   Validação da Infra + Análise de Custos"
echo "=========================================="

# --- Health Check ---
echo ""
echo "--- 1. App Online? ---"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN" 2>/dev/null)
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "301" || "$HTTP_CODE" == "302" ]]; then
  echo "✅ $DOMAIN respondendo (HTTP $HTTP_CODE)"
else
  echo "❌ $DOMAIN não respondeu (HTTP $HTTP_CODE)"
fi

# --- DNS ---
echo ""
echo "--- 2. DNS ---"
echo "Resolução de $DOMAIN:"
nslookup "$DOMAIN" 2>/dev/null | grep -A2 "Name:" || dig +short "$DOMAIN" 2>/dev/null || echo "❌ Não resolveu"

# --- Certificado HTTPS ---
echo ""
echo "--- 3. Certificado HTTPS ---"
CERT_INFO=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null)
if [[ -n "$CERT_INFO" ]]; then
  echo "✅ Certificado válido:"
  echo "$CERT_INFO"
else
  echo "❌ Certificado não encontrado ou inválido"
fi

# --- ALB ---
echo ""
echo "--- 4. ALB ---"
aws elbv2 describe-load-balancers --region $REGION \
  --query 'LoadBalancers[].[LoadBalancerName,State.Code,DNSName,Type]' \
  --output table

# --- ECS ---
echo ""
echo "--- 5. ECS ---"
CLUSTERS=$(aws ecs list-clusters --region $REGION --query 'clusterArns[]' --output text 2>/dev/null)
if [[ -n "$CLUSTERS" ]]; then
  aws ecs describe-clusters --region $REGION --clusters $CLUSTERS \
    --query 'clusters[].[clusterName,status,runningTasksCount,activeServicesCount]' \
    --output table

  for CLUSTER in $CLUSTERS; do
    SERVICES=$(aws ecs list-services --region $REGION --cluster "$CLUSTER" --query 'serviceArns[]' --output text 2>/dev/null)
    if [[ -n "$SERVICES" ]]; then
      echo ""
      echo "Tasks rodando:"
      aws ecs describe-services --region $REGION --cluster "$CLUSTER" --services $SERVICES \
        --query 'services[].[serviceName,status,runningCount,desiredCount,launchType]' \
        --output table
    fi
  done
else
  echo "❌ Nenhum cluster ECS encontrado"
fi

# --- RDS ---
echo ""
echo "--- 6. RDS ---"
aws rds describe-db-instances --region $REGION \
  --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus,MultiAZ,AllocatedStorage]' \
  --output table

# --- EC2 rodando ---
echo ""
echo "--- 7. EC2 Instâncias Rodando ---"
aws ec2 describe-instances --region $REGION \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# --- Estimativa de Custos ---
echo ""
echo "=========================================="
echo "   💰 Estimativa de Custos (us-east-1)"
echo "=========================================="
echo ""

# ECS Fargate
echo "--- ECS Fargate ---"
TASKS=$(aws ecs list-tasks --region $REGION --cluster bia-cluster --query 'taskArns[]' --output text 2>/dev/null)
if [[ -n "$TASKS" ]]; then
  TASK_COUNT=$(echo "$TASKS" | wc -w)
  echo "Tasks rodando: $TASK_COUNT"
  echo "Config: 0.5 vCPU / 1GB RAM"
  echo "Custo estimado: ~\$0.03/hora = ~\$22/mês por task"
  echo "Total: ~\$$(echo "$TASK_COUNT * 22" | bc)/mês"
else
  echo "Nenhuma task rodando (custo: \$0)"
fi

echo ""
echo "--- RDS ---"
DB_CLASS=$(aws rds describe-db-instances --region $REGION \
  --query 'DBInstances[0].DBInstanceClass' --output text 2>/dev/null)
DB_STORAGE=$(aws rds describe-db-instances --region $REGION \
  --query 'DBInstances[0].AllocatedStorage' --output text 2>/dev/null)
DB_MULTI=$(aws rds describe-db-instances --region $REGION \
  --query 'DBInstances[0].MultiAZ' --output text 2>/dev/null)
echo "Classe: $DB_CLASS"
echo "Storage: ${DB_STORAGE}GB"
echo "Multi-AZ: $DB_MULTI"
if [[ "$DB_CLASS" == "db.t3.micro" ]]; then
  echo "Custo estimado: ~\$15/mês (instância) + ~\$1.15/mês (10GB gp2)"
  echo "Total RDS: ~\$16/mês"
fi

echo ""
echo "--- ALB ---"
ALB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION \
  --query 'length(LoadBalancers)' --output text 2>/dev/null)
echo "ALBs ativos: $ALB_COUNT"
echo "Custo estimado: ~\$16/mês (fixo) + ~\$0.008/LCU-hora"
echo "Total ALB: ~\$18-22/mês (tráfego baixo)"

echo ""
echo "--- EC2 ---"
EC2_TYPES=$(aws ec2 describe-instances --region $REGION \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceType' --output text 2>/dev/null)
if [[ -n "$EC2_TYPES" ]]; then
  for TYPE in $EC2_TYPES; do
    case $TYPE in
      t3.micro) echo "$TYPE: ~\$8/mês" ;;
      t3.small) echo "$TYPE: ~\$15/mês" ;;
      t3.medium) echo "$TYPE: ~\$30/mês" ;;
      *) echo "$TYPE: consulte https://calculator.aws" ;;
    esac
  done
else
  echo "Nenhuma EC2 rodando (\$0)"
fi

echo ""
echo "--- Route53 ---"
echo "Hosted Zone: \$0.50/mês"
echo "Queries: ~\$0.40/milhão"

echo ""
echo "=========================================="
echo "   📊 Resumo Estimado Mensal"
echo "=========================================="
echo "ECS Fargate (1 task):  ~\$22/mês"
echo "RDS db.t3.micro:       ~\$16/mês"
echo "ALB:                   ~\$20/mês"
echo "Route53:               ~\$1/mês"
echo "ECR:                   ~\$1/mês"
echo "CloudWatch Logs:       ~\$1/mês"
echo "----------------------------------"
echo "TOTAL ESTIMADO:        ~\$61/mês"
echo ""
echo "💡 Dicas para economizar:"
echo "  - Pare o RDS quando não usar: aws rds stop-db-instance --db-instance-identifier bia"
echo "  - Scale ECS para 0 à noite: aws ecs update-service --cluster bia-cluster --service bia-service --desired-count 0"
echo "  - Use https://calculator.aws para estimativas detalhadas"
echo "=========================================="
