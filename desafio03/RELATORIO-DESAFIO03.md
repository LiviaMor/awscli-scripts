# Relatório — Desafio 03: Deploy BIA no ECS com ALB + HTTPS

## Objetivo

Realizar o deploy da aplicação **BIA** na AWS utilizando **ECS Fargate**, com **ALB**, **certificado HTTPS**, **domínio customizado** e **banco de dados RDS PostgreSQL**, tudo gerenciado via **Terraform** e scripts de automação.

## Arquitetura

```
Usuário
  │
  ▼
formacaoaws.ninehealth.com.br (Route53)
  │
  ▼
ALB (bia-alb) — HTTPS:443 (ACM Certificate)
  │  HTTP:80 → Redirect HTTPS
  ▼
ECS Fargate (bia-cluster / bia-service)
  │  Container: bia:latest (porta 8080)
  │  Imagem: 794038217446.dkr.ecr.us-east-1.amazonaws.com/bia:latest
  ▼
RDS PostgreSQL 17 (bia.c4zy4cykm0n7.us-east-1.rds.amazonaws.com:5432)
  │  Database: bia
  │  Classe: db.t3.micro
  │  Parameter Group: bia-postgres17 (SSL desabilitado)
```

## Recursos Criados

### Terraform (IaC)

| Arquivo | Recurso |
|---------|---------|
| `init.tf` | Provider AWS com assume_role (role-time-dev) |
| `ecs.tf` | ECS Cluster, Task Definition (Fargate 512cpu/1GB), Service |
| `alb.tf` | ALB, Target Group (porta 8080), Listeners HTTP/HTTPS |
| `acm.tf` | Certificado HTTPS + validação DNS automática |
| `route53.tf` | Record A → ALB (formacaoaws.ninehealth.com.br) |
| `iam_ecs.tf` | Execution Role + Task Role para ECS |
| `out_sg.tf` | Data sources dos Security Groups existentes |
| `out_db.tf` | RDS PostgreSQL (importado) |
| `variables.tf` | Variáveis (VPC, subnets, imagem ECR, credenciais DB) |
| `outputs.tf` | URL da app, DNS do ALB, endpoint RDS |

### Security Groups

| SG | Nome | Função |
|----|------|--------|
| `sg-0dcd164e0b3a63af1` | bia-alb-teste | ALB — entrada HTTP/HTTPS do mundo |
| `sg-0dfdd93e3ddae2f4b` | bia-ec2-teste | ECS Tasks — recebe do ALB, sai pro DB |
| `sg-04eb26de8b00feb9b` | bia-db | RDS — porta 5432 restrita aos SGs internos |
| `sg-04721b37b7a06da28` | bia-web | Porta 80 aberta |

### Scripts de Automação

| Script | Descrição |
|--------|-----------|
| `aws-resources.sh` | Menu interativo: listar/lançar/gerenciar EC2, ECS, RDS, SGs |
| `build-push-ecr.sh` | Clone Git → Build Docker → Push ECR |
| `check-infra.sh` | Validação da infra (health check, DNS, cert, custos) |
| `info-infra.sh` | Coleta informações da infra (VPC, subnets, SGs, ECR, RDS) |
| `set-aws-temp-creds.sh` | Assume role via STS e exporta credenciais |

## Configurações Importantes

### ECS Task Definition

- **Imagem**: `794038217446.dkr.ecr.us-east-1.amazonaws.com/bia:latest`
- **CPU/Memória**: 512 / 1024 MB (Fargate)
- **Porta**: 8080
- **Variáveis de ambiente**:
  - `NODE_ENV=production`
  - `PORT=8080`
  - `DB_HOST=bia.c4zy4cykm0n7.us-east-1.rds.amazonaws.com`
  - `DB_PORT=5432`
  - `DB_USER=postgres`
  - `DB_PWD=***`

### RDS

- **Engine**: PostgreSQL 17.6
- **Classe**: db.t3.micro
- **Storage**: 10GB gp2
- **Multi-AZ**: Não
- **Parameter Group**: `bia-postgres17` (rds.force_ssl=0)
- **Database**: `bia`

### ALB

- **Listener HTTPS (443)**: Forward → Target Group (porta 8080)
- **Listener HTTP (80)**: Redirect → HTTPS (301)
- **SSL Policy**: ELBSecurityPolicy-TLS13-1-2-2021-06
- **Certificado**: ACM (formacaoaws.ninehealth.com.br)

### Dockerfile (BIA)

- Base: `node:22-slim`
- Build do frontend com `VITE_API_URL=https://formacaoaws.ninehealth.com.br`
- Migrations rodam no startup: `npx sequelize-cli db:migrate && npm start`
- Porta exposta: 8080

## IAM — Permissões Utilizadas

### Usuário: desafios (profile awscli)

- `AmazonEC2ContainerRegistryFullAccess` — Push de imagens ECR

### Role: role-time-dev (assume role via Terraform)

| Policy | Motivo |
|--------|--------|
| `AmazonEC2FullAccess` | Gerenciar EC2 e SGs |
| `AmazonRDSFullAccess` | Gerenciar RDS |
| `AmazonECS_FullAccess` | Gerenciar ECS |
| `ElasticLoadBalancingFullAccess` | Gerenciar ALB |
| `IAMFullAccess` | Criar roles ECS |
| `AmazonRoute53FullAccess` | Gerenciar DNS |
| `AWSCertificateManagerFullAccess` | Certificado HTTPS |
| `AmazonS3FullAccess` | Operações S3 |
| `AmazonEC2ContainerRegistryFullAccess` | ECR |

### Roles ECS

- **bia-ecs-execution-role**: Puxa imagem do ECR, envia logs
- **bia-ecs-task-role**: Permissões da aplicação em runtime

## Estimativa de Custos (us-east-1)

| Recurso | Custo/mês |
|---------|-----------|
| ECS Fargate (1 task, 0.5vCPU/1GB) | ~$22 |
| RDS db.t3.micro (10GB) | ~$16 |
| ALB | ~$20 |
| Route53 | ~$1 |
| ECR + CloudWatch Logs | ~$2 |
| **Total estimado** | **~$61/mês** |

### Dicas para Economizar

- Parar RDS quando não usar: `aws rds stop-db-instance --db-instance-identifier bia`
- Escalar ECS para 0 à noite: `aws ecs update-service --cluster bia-cluster --service bia-service --desired-count 0`
- Usar [AWS Pricing Calculator](https://calculator.aws) para estimativas detalhadas

## Problemas Encontrados e Soluções

| Problema | Causa | Solução |
|----------|-------|---------|
| Task ECS não inicia | Não conseguia puxar imagem do ECR | Repositório ECR não existia — criado e feito push |
| `VITE_API_URL=localhost:3001` | Variável de build time embutida no JS | Rebuild da imagem com URL correta |
| `no pg_hba.conf entry, no encryption` | RDS exigia SSL | Criado parameter group custom com `rds.force_ssl=0` |
| `database "bia" does not exist` | Database não criado no RDS | Criado via `psql -c "CREATE DATABASE bia;"` |
| Cycle nos Security Groups | Referências circulares no Terraform | Convertido SGs para data sources |
| Limite de 10 policies na role | AWS quota | Removidas policies desnecessárias |
| `npm install -g npm@11` falha no build | Desnecessário com Node 22 | Removida linha do Dockerfile |

## Comandos Úteis

```bash
# Deploy
terraform apply
./build-push-ecr.sh
aws ecs update-service --cluster bia-cluster --service bia-service --force-new-deployment --region us-east-1

# Validação
./check-infra.sh

# Logs ECS
aws logs get-log-events --log-group-name /ecs/bia --log-stream-name <stream> --region us-east-1

# Parar tudo (economizar)
aws ecs update-service --cluster bia-cluster --service bia-service --desired-count 0 --region us-east-1
aws rds stop-db-instance --db-instance-identifier bia --region us-east-1

# Subir tudo
aws rds start-db-instance --db-instance-identifier bia --region us-east-1
aws ecs update-service --cluster bia-cluster --service bia-service --desired-count 1 --region us-east-1
```

## Acesso

- **URL**: https://formacaoaws.ninehealth.com.br
- **ALB DNS**: bia-alb-1053684008.us-east-1.elb.amazonaws.com
- **RDS Endpoint**: bia.c4zy4cykm0n7.us-east-1.rds.amazonaws.com:5432
- **ECR**: 794038217446.dkr.ecr.us-east-1.amazonaws.com/bia
