#!/bin/bash
# Script interativo para listar e lançar recursos AWS
# EC2, ECS, RDS e Security Groups

REGION="us-east-1"

echo "=========================================="
echo "   AWS Resources - Menu Interativo"
echo "=========================================="
echo ""
echo "--- Listar ---"
echo "1) Listar instâncias EC2"
echo "2) Listar clusters ECS"
echo "3) Listar instâncias RDS"
echo "4) Listar Security Groups"
echo ""
echo "--- Lançar ---"
echo "5) Lançar instância EC2"
echo "6) Lançar instância RDS"
echo ""
echo "--- Gerenciar ---"
echo "7) Iniciar instância EC2"
echo "8) Parar instância EC2"
echo "9) Terminar instância EC2"
echo "10) Iniciar instância RDS"
echo "11) Parar instância RDS"
echo "12) Deletar instância RDS"
echo ""
echo "0) Sair"
echo ""
read -p "Escolha uma opção: " OPCAO

case $OPCAO in
  1)
    echo "Listando instâncias EC2..."
    aws ec2 describe-instances \
      --region $REGION \
      --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0],PublicIpAddress]' \
      --output table
    ;;

  2)
    echo "Listando clusters ECS..."
    CLUSTERS=$(aws ecs list-clusters --region $REGION --query 'clusterArns[]' --output text)
    if [[ -z "$CLUSTERS" ]]; then
      echo "Nenhum cluster ECS encontrado."
    else
      aws ecs describe-clusters \
        --region $REGION \
        --clusters $CLUSTERS \
        --query 'clusters[].[clusterName,status,runningTasksCount,activeServicesCount]' \
        --output table
    fi
    ;;

  3)
    echo "Listando instâncias RDS..."
    aws rds describe-db-instances \
      --region $REGION \
      --query 'DBInstances[].[DBInstanceIdentifier,Engine,DBInstanceClass,DBInstanceStatus,Endpoint.Address]' \
      --output table
    ;;

  4)
    echo "Listando Security Groups..."
    aws ec2 describe-security-groups \
      --region $REGION \
      --query 'SecurityGroups[].[GroupId,GroupName,Description]' \
      --output table
    ;;

  5)
    echo "=== Lançar instância EC2 ==="
    read -p "Nome da instância: " EC2_NAME
    read -p "AMI ID (padrão Amazon Linux 2023: ami-02dfbd4ff395f2a1b): " AMI_ID
    AMI_ID=${AMI_ID:-ami-02dfbd4ff395f2a1b}
    read -p "Tipo da instância (padrão t3.micro): " INSTANCE_TYPE
    INSTANCE_TYPE=${INSTANCE_TYPE:-t3.micro}

    echo ""
    echo "Security Groups disponíveis:"
    aws ec2 describe-security-groups \
      --region $REGION \
      --query 'SecurityGroups[].[GroupId,GroupName]' \
      --output table
    echo ""
    read -p "Security Group ID: " SG_ID
    [[ -z "$SG_ID" ]] && echo "Erro: Security Group obrigatório." && exit 1

    echo ""
    echo "Lançando EC2: $EC2_NAME ($INSTANCE_TYPE)..."
    aws ec2 run-instances \
      --region $REGION \
      --image-id "$AMI_ID" \
      --instance-type "$INSTANCE_TYPE" \
      --security-group-ids "$SG_ID" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_NAME}]" \
      --query 'Instances[].[InstanceId,State.Name]' \
      --output table
    echo "Instância lançada!"
    ;;

  6)
    echo "=== Lançar instância RDS ==="
    read -p "Identificador do DB (ex: meu-banco): " DB_ID
    [[ -z "$DB_ID" ]] && echo "Erro: identificador obrigatório." && exit 1

    echo ""
    echo "Engines disponíveis: mysql | postgres | mariadb"
    read -p "Engine (padrão mysql): " ENGINE
    ENGINE=${ENGINE:-mysql}

    read -p "Classe da instância (padrão db.t3.micro): " DB_CLASS
    DB_CLASS=${DB_CLASS:-db.t3.micro}
    read -p "Tamanho do storage em GB (padrão 20): " STORAGE
    STORAGE=${STORAGE:-20}
    read -p "Master username (padrão admin): " MASTER_USER
    MASTER_USER=${MASTER_USER:-admin}
    read -p "Master password (mínimo 8 caracteres): " MASTER_PASS
    [[ ${#MASTER_PASS} -lt 8 ]] && echo "Erro: senha precisa ter no mínimo 8 caracteres." && exit 1

    echo ""
    echo "Security Groups disponíveis:"
    aws ec2 describe-security-groups \
      --region $REGION \
      --query 'SecurityGroups[].[GroupId,GroupName]' \
      --output table
    echo ""
    read -p "Security Group ID: " SG_ID
    [[ -z "$SG_ID" ]] && echo "Erro: Security Group obrigatório." && exit 1

    echo ""
    echo "Lançando RDS: $DB_ID ($ENGINE / $DB_CLASS)..."
    aws rds create-db-instance \
      --region $REGION \
      --db-instance-identifier "$DB_ID" \
      --engine "$ENGINE" \
      --db-instance-class "$DB_CLASS" \
      --allocated-storage "$STORAGE" \
      --master-username "$MASTER_USER" \
      --master-user-password "$MASTER_PASS" \
      --vpc-security-group-ids "$SG_ID" \
      --no-multi-az \
      --query 'DBInstance.[DBInstanceIdentifier,Engine,DBInstanceStatus]' \
      --output table
    echo "RDS em criação! Pode levar alguns minutos."
    ;;

  7)
    echo "=== Iniciar instância EC2 ==="
    aws ec2 describe-instances \
      --region $REGION \
      --filters "Name=instance-state-name,Values=stopped" \
      --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
      --output table
    echo ""
    read -p "ID da instância para iniciar: " INSTANCE_ID
    [[ -z "$INSTANCE_ID" ]] && echo "Erro: ID obrigatório." && exit 1
    aws ec2 start-instances --instance-ids "$INSTANCE_ID" --region $REGION
    echo "Instância $INSTANCE_ID iniciando!"
    ;;

  8)
    echo "=== Parar instância EC2 ==="
    aws ec2 describe-instances \
      --region $REGION \
      --filters "Name=instance-state-name,Values=running" \
      --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
      --output table
    echo ""
    read -p "ID da instância para parar: " INSTANCE_ID
    [[ -z "$INSTANCE_ID" ]] && echo "Erro: ID obrigatório." && exit 1
    aws ec2 stop-instances --instance-ids "$INSTANCE_ID" --region $REGION
    echo "Instância $INSTANCE_ID parando!"
    ;;

  9)
    echo "=== Terminar instância EC2 ==="
    aws ec2 describe-instances \
      --region $REGION \
      --filters "Name=instance-state-name,Values=running,stopped" \
      --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
      --output table
    echo ""
    read -p "ID da instância para TERMINAR: " INSTANCE_ID
    [[ -z "$INSTANCE_ID" ]] && echo "Erro: ID obrigatório." && exit 1
    read -p "Tem certeza? Isso é irreversível! (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region $REGION
    echo "Instância $INSTANCE_ID sendo terminada!"
    ;;

  10)
    echo "=== Iniciar instância RDS ==="
    aws rds describe-db-instances \
      --region $REGION \
      --query 'DBInstances[?DBInstanceStatus==`stopped`].[DBInstanceIdentifier,Engine,DBInstanceStatus]' \
      --output table
    echo ""
    read -p "Identificador do RDS para iniciar: " DB_ID
    [[ -z "$DB_ID" ]] && echo "Erro: identificador obrigatório." && exit 1
    aws rds start-db-instance --db-instance-identifier "$DB_ID" --region $REGION
    echo "RDS $DB_ID iniciando!"
    ;;

  11)
    echo "=== Parar instância RDS ==="
    aws rds describe-db-instances \
      --region $REGION \
      --query 'DBInstances[?DBInstanceStatus==`available`].[DBInstanceIdentifier,Engine,DBInstanceStatus]' \
      --output table
    echo ""
    read -p "Identificador do RDS para parar: " DB_ID
    [[ -z "$DB_ID" ]] && echo "Erro: identificador obrigatório." && exit 1
    aws rds stop-db-instance --db-instance-identifier "$DB_ID" --region $REGION
    echo "RDS $DB_ID parando!"
    ;;

  12)
    echo "=== Deletar instância RDS ==="
    aws rds describe-db-instances \
      --region $REGION \
      --query 'DBInstances[].[DBInstanceIdentifier,Engine,DBInstanceStatus]' \
      --output table
    echo ""
    read -p "Identificador do RDS para DELETAR: " DB_ID
    [[ -z "$DB_ID" ]] && echo "Erro: identificador obrigatório." && exit 1
    read -p "Tem certeza? Isso é irreversível! (s/n): " CONFIRMA
    [[ "$CONFIRMA" != "s" ]] && echo "Cancelado." && exit 0
    aws rds delete-db-instance --db-instance-identifier "$DB_ID" --skip-final-snapshot --region $REGION
    echo "RDS $DB_ID sendo deletado!"
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
