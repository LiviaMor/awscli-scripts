#!/bin/bash
# Script para buscar informações necessárias para deploy ECS + ALB
REGION="us-east-1"

echo "=========================================="
echo "   Coletando informações da infra AWS"
echo "=========================================="

echo ""
echo "--- VPC e Subnets ---"
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
echo "VPC padrão: $VPC_ID"
echo "Subnets:"
aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].[SubnetId,AvailabilityZone,CidrBlock]' --output table

echo ""
echo "--- Security Groups ---"
aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[].[GroupId,GroupName,Description]' --output table

echo ""
echo "--- ECR Repositórios ---"
aws ecr describe-repositories --region $REGION --query 'repositories[].[repositoryName,repositoryUri]' --output table

echo ""
echo "--- Imagens no ECR (bia) ---"
aws ecr describe-images --region $REGION --repository-name bia --query 'imageDetails[].imageTags[]' --output table 2>/dev/null || echo "Repositório 'bia' não encontrado"

echo ""
echo "--- RDS ---"
aws rds describe-db-instances --region $REGION --query 'DBInstances[].[DBInstanceIdentifier,Engine,DBInstanceClass,DBInstanceStatus,Endpoint.Address,Endpoint.Port]' --output table

echo ""
echo "--- ECS Clusters ---"
CLUSTERS=$(aws ecs list-clusters --region $REGION --query 'clusterArns[]' --output text)
if [[ -z "$CLUSTERS" ]]; then
  echo "Nenhum cluster ECS encontrado."
else
  aws ecs describe-clusters --region $REGION --clusters $CLUSTERS --query 'clusters[].[clusterName,status,runningTasksCount]' --output table
fi

echo ""
echo "--- ACM Certificados ---"
aws acm list-certificates --region $REGION --query 'CertificateSummaryList[].[DomainName,CertificateArn,Status]' --output table

echo ""
echo "--- Route53 Hosted Zone ---"
aws route53 list-hosted-zones --query 'HostedZones[].[Id,Name,Config.PrivateZone]' --output table

echo ""
echo "--- IAM Roles (ECS) ---"
aws iam list-roles --query 'Roles[?contains(RoleName,`ecs`) || contains(RoleName,`ECS`)].RoleName' --output table 2>/dev/null

echo ""
echo "=========================================="
echo "   Coleta finalizada!"
echo "=========================================="
