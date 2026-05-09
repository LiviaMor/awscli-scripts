#!/bin/bash
# ============================================================
# 🚀 DEPLOY — Landing Page AWS Women User Group Goiânia
# 
# Este script faz o deploy completo da landing page do
# repositório https://github.com/LiviaMor/awswomengoiania.git
#
# O projeto é um app Next.js 16 + React 19 + Tailwind CSS.
# Estratégia: build estático (next export) → S3 + CloudFront
#
# Profile AWS: awscli
# Role: arn:aws:iam::794038217446:role/role-time-dev
# Região: us-east-1
# Conta: 794038217446
#
# ============================================================
# 🔐 POR QUE USAMOS CREDENCIAIS TEMPORÁRIAS?
# ============================================================
#
# Neste projeto, NÃO usamos access keys fixas diretamente.
# O fluxo de autenticação é:
#
#   1. Profile "awscli" → IAM User com permissão MÍNIMA
#      (só pode fazer sts:AssumeRole, nada mais)
#
#   2. sts assume-role → Gera credenciais TEMPORÁRIAS (expiram em 1h)
#      com as permissões da role "role-time-dev"
#
#   3. A role "role-time-dev" → Tem as permissões reais
#      (S3, CloudFront, etc.)
#
# POR QUE ISSO É IMPORTANTE:
#
#   ✅ Se alguém roubar suas access keys, não consegue fazer nada
#      (o user só pode assumir role, não tem permissão direta)
#
#   ✅ Credenciais temporárias expiram sozinhas (1h por padrão)
#      (se vazar, o estrago é limitado no tempo)
#
#   ✅ A role precisa AUTORIZAR quem pode assumi-la
#      (Trust Policy define quais users/contas podem usar)
#
#   ✅ Auditoria: CloudTrail registra QUEM assumiu a role e QUANDO
#
# SE VOCÊ NÃO CONFIGUROU A MÁQUINA:
#
#   ❌ Sem o profile "awscli" → não consegue assumir a role
#   ❌ Sem a role autorizar seu user → "Access Denied"
#   ❌ Sem rodar o assume-role → não tem permissão pra criar S3/CloudFront
#
# É por isso que o install-setup.sh existe: ele configura o
# profile base que permite todo o resto funcionar.
#
# ============================================================
#
# Pré-requisitos:
#   - AWS CLI v2 configurado (profile awscli)
#   - Role "role-time-dev" autorizando seu IAM user
#   - Node.js 18+ e npm instalados
#   - Git instalado
#
# Uso: bash deploy-landingpage-awswomengoiania.sh
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURAÇÕES
# ============================================================
AWS_PROFILE="awscli"
AWS_REGION="us-east-1"
BUCKET_NAME="awswomengoiania-landingpage"
REPO_URL="https://github.com/LiviaMor/awswomengoiania.git"
CLONE_DIR="/tmp/awswomengoiania"
PROJECT_DIR="${CLONE_DIR}/aws-women-landing"
BUILD_OUTPUT="${PROJECT_DIR}/out"
ROLE_ARN="arn:aws:iam::794038217446:role/role-time-dev"
SESSION_NAME="deploy-landingpage"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${PURPLE}============================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}============================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================
# ETAPA 1: Validar pré-requisitos
# ============================================================
print_header "🔍 ETAPA 1: Validando pré-requisitos"

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI não encontrado. Execute install-setup.sh primeiro."
    exit 1
fi
print_success "AWS CLI instalado: $(aws --version 2>&1 | head -1)"

# Verificar Git
if ! command -v git &> /dev/null; then
    print_error "Git não encontrado. Instale com: sudo apt install git"
    exit 1
fi
print_success "Git instalado: $(git --version)"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js não encontrado!"
    print_info "Instale com: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs"
    print_info "Ou use nvm: https://github.com/nvm-sh/nvm"
    exit 1
fi

NODE_VERSION=$(node --version)
print_success "Node.js instalado: ${NODE_VERSION}"

# Verificar se é Node 18+
NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
    print_error "Node.js 18+ é necessário para Next.js 16. Versão atual: ${NODE_VERSION}"
    exit 1
fi

# Verificar npm
if ! command -v npm &> /dev/null; then
    print_error "npm não encontrado!"
    exit 1
fi
print_success "npm instalado: $(npm --version)"

# Verificar credenciais AWS
print_step "Validando credenciais do profile '${AWS_PROFILE}'..."
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --output text &> /dev/null; then
    print_error "Profile '${AWS_PROFILE}' inválido ou expirado."
    print_info "Configure com: aws configure --profile ${AWS_PROFILE}"
    print_info "Ou execute primeiro: bash install-setup.sh"
    exit 1
fi

CALLER_ARN=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query "Arn" --output text)
print_success "Profile base autenticado: ${CALLER_ARN}"

# ============================================================
# ETAPA 2: Assumir Role (credenciais temporárias)
# ============================================================
print_header "🔐 ETAPA 2: Assumindo Role (credenciais temporárias)"

print_step "Assumindo role: ${ROLE_ARN}..."
print_info "Isso gera credenciais temporárias (expiram em 1h) com permissões reais."
echo ""

CREDENTIALS=$(aws sts assume-role \
    --profile "$AWS_PROFILE" \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text 2>&1) || {
    print_error "Falha ao assumir role: ${ROLE_ARN}"
    echo ""
    print_info "Possíveis causas:"
    echo "  1. Seu IAM user não está autorizado na Trust Policy da role"
    echo "  2. A role não existe ou o ARN está errado"
    echo "  3. Suas credenciais base (profile awscli) expiraram"
    echo ""
    print_info "Peça ao admin da conta para adicionar seu user na Trust Policy:"
    echo "  {\"Effect\": \"Allow\", \"Principal\": {\"AWS\": \"SEU_USER_ARN\"}, \"Action\": \"sts:AssumeRole\"}"
    exit 1
}

read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$CREDENTIALS"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

# Verificar que as credenciais temporárias funcionam
ASSUMED_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
print_success "Role assumida com sucesso!"
print_info "Identidade atual: ${ASSUMED_ARN}"
print_info "Credenciais expiram em 1 hora."
echo ""
print_info "Agora temos permissão para: S3, CloudFront, e outros serviços da role."

# A partir daqui, todos os comandos AWS usam as credenciais temporárias
# exportadas como variáveis de ambiente (não precisa mais de --profile)

# ============================================================
# ETAPA 2: Clonar o repositório
# ============================================================
print_header "📦 ETAPA 2: Clonando repositório"

if [ -d "$CLONE_DIR" ]; then
    print_warning "Diretório ${CLONE_DIR} já existe. Atualizando..."
    git -C "$CLONE_DIR" pull origin main 2>/dev/null || git -C "$CLONE_DIR" pull origin master 2>/dev/null || true
else
    print_step "Clonando ${REPO_URL}..."
    git clone "$REPO_URL" "$CLONE_DIR"
fi

print_success "Repositório pronto em: ${CLONE_DIR}"

# Verificar se a pasta do projeto existe
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Pasta do projeto não encontrada em: ${PROJECT_DIR}"
    print_info "Estrutura do repositório:"
    ls -la "$CLONE_DIR"
    exit 1
fi

print_success "Projeto Next.js encontrado em: ${PROJECT_DIR}"

# ============================================================
# ETAPA 3: Configurar Next.js para export estático
# ============================================================
print_header "⚙️  ETAPA 3: Configurando Next.js para export estático"

# Verificar se next.config.ts já tem output: 'export'
if grep -q "output.*export" "${PROJECT_DIR}/next.config.ts" 2>/dev/null; then
    print_success "next.config.ts já está configurado para export estático"
else
    print_step "Adicionando output: 'export' ao next.config.ts..."
    
    # Reescrever o next.config.ts com output export
    cat > "${PROJECT_DIR}/next.config.ts" << 'EOF'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
EOF

    print_success "next.config.ts configurado para gerar site estático"
    print_info "output: 'export' → gera HTML/CSS/JS puros na pasta 'out/'"
    print_info "images.unoptimized: true → necessário para export estático (sem server)"
fi

# ============================================================
# ETAPA 4: Instalar dependências e fazer build
# ============================================================
print_header "🔨 ETAPA 4: Build do projeto Next.js"

print_step "Instalando dependências (npm install)..."
cd "$PROJECT_DIR"
npm install

print_success "Dependências instaladas!"

print_step "Executando build (npm run build)..."
npm run build

# Verificar se o output foi gerado
if [ ! -d "$BUILD_OUTPUT" ]; then
    print_error "Build falhou! Pasta 'out/' não foi gerada."
    print_info "Verifique se há erros no código do projeto."
    exit 1
fi

FILE_COUNT=$(find "$BUILD_OUTPUT" -type f | wc -l)
print_success "Build concluído! ${FILE_COUNT} arquivos gerados em ${BUILD_OUTPUT}"

# Voltar ao diretório original
cd - > /dev/null

# ============================================================
# ETAPA 5: Criar bucket S3
# ============================================================
print_header "🪣 ETAPA 5: Criando bucket S3"

# Verificar se bucket já existe
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    print_warning "Bucket '${BUCKET_NAME}' já existe. Continuando..."
else
    print_step "Criando bucket '${BUCKET_NAME}' em ${AWS_REGION}..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION"
    print_success "Bucket criado!"
fi

# ============================================================
# ETAPA 6: Configurar bucket para hospedagem estática
# ============================================================
print_header "🌐 ETAPA 6: Configurando hospedagem estática"

# Desabilitar Block Public Access
print_step "Desabilitando Block Public Access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
print_success "Block Public Access desabilitado"

# Configurar website hosting
print_step "Habilitando website hosting..."
aws s3api put-bucket-website \
    --bucket "$BUCKET_NAME" \
    --website-configuration '{
        "IndexDocument": {"Suffix": "index.html"},
        "ErrorDocument": {"Key": "404.html"}
    }'
print_success "Website hosting habilitado"

# Aplicar bucket policy para acesso público de leitura
print_step "Aplicando bucket policy (acesso público de leitura)..."
BUCKET_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF
)

echo "$BUCKET_POLICY" | aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file:///dev/stdin
print_success "Bucket policy aplicada"

# ============================================================
# ETAPA 7: Fazer upload dos arquivos buildados
# ============================================================
print_header "📤 ETAPA 7: Fazendo upload dos arquivos"

print_step "Sincronizando build output para o S3..."
aws s3 sync "$BUILD_OUTPUT" "s3://${BUCKET_NAME}" \
    --delete

# Configurar Content-Type correto para arquivos comuns
print_step "Ajustando Content-Types..."

# CSS
aws s3 cp "s3://${BUCKET_NAME}" "s3://${BUCKET_NAME}" \
    --recursive \
    --exclude "*" \
    --include "*.css" \
    --content-type "text/css" \
    --metadata-directive REPLACE 2>/dev/null || true

# JavaScript
aws s3 cp "s3://${BUCKET_NAME}" "s3://${BUCKET_NAME}" \
    --recursive \
    --exclude "*" \
    --include "*.js" \
    --content-type "application/javascript" \
    --metadata-directive REPLACE 2>/dev/null || true

# SVG
aws s3 cp "s3://${BUCKET_NAME}" "s3://${BUCKET_NAME}" \
    --recursive \
    --exclude "*" \
    --include "*.svg" \
    --content-type "image/svg+xml" \
    --metadata-directive REPLACE 2>/dev/null || true

# JSON
aws s3 cp "s3://${BUCKET_NAME}" "s3://${BUCKET_NAME}" \
    --recursive \
    --exclude "*" \
    --include "*.json" \
    --content-type "application/json" \
    --metadata-directive REPLACE 2>/dev/null || true

print_success "Upload concluído com Content-Types corretos!"

# Contar arquivos enviados
UPLOADED_COUNT=$(aws s3 ls "s3://${BUCKET_NAME}" --recursive | wc -l)
print_info "Total de arquivos no bucket: ${UPLOADED_COUNT}"

# ============================================================
# ETAPA 8: Criar distribuição CloudFront (CDN + HTTPS)
# ============================================================
print_header "⚡ ETAPA 8: Configurando CloudFront (CDN + HTTPS)"

S3_WEBSITE_ENDPOINT="${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"

# Verificar se já existe uma distribuição para este bucket
EXISTING_DIST=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Origins.Items[0].DomainName=='${S3_WEBSITE_ENDPOINT}'].Id" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_DIST" ] && [ "$EXISTING_DIST" != "None" ]; then
    print_warning "Distribuição CloudFront já existe: ${EXISTING_DIST}"
    DISTRIBUTION_ID="$EXISTING_DIST"

    # Invalidar cache para pegar as mudanças
    print_step "Invalidando cache do CloudFront..."
    aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" > /dev/null
    print_success "Cache invalidado!"
else
    print_step "Criando distribuição CloudFront..."
    
    CF_CONFIG=$(cat <<EOF
{
    "CallerReference": "awswomengoiania-$(date +%s)",
    "Comment": "AWS Women User Group Goiania - Landing Page",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-${BUCKET_NAME}",
                "DomainName": "${S3_WEBSITE_ENDPOINT}",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "Enabled": true,
    "DefaultRootObject": "index.html",
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/404.html",
                "ResponseCode": "404",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "PriceClass": "PriceClass_100",
    "HttpVersion": "http2"
}
EOF
)

    DISTRIBUTION_ID=$(echo "$CF_CONFIG" | aws cloudfront create-distribution \
        --distribution-config file:///dev/stdin \
        --query "Distribution.Id" \
        --output text)
    
    print_success "Distribuição CloudFront criada: ${DISTRIBUTION_ID}"
fi

# Obter o domínio do CloudFront
CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "$DISTRIBUTION_ID" \
    --query "Distribution.DomainName" \
    --output text)

# ============================================================
# ETAPA 9: Verificação final
# ============================================================
print_header "🎯 ETAPA 9: Verificação Final — SITE NO AR!"

echo ""
echo -e "${GREEN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║   🎉 DEPLOY CONCLUÍDO COM SUCESSO!                      ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}📌 URLs de acesso ao site:${NC}"
echo ""
echo -e "  ${BLUE}🌐 S3 Website (HTTP — acesso imediato):${NC}"
echo -e "    ${YELLOW}http://${S3_WEBSITE_ENDPOINT}${NC}"
echo ""
echo -e "  ${BLUE}🔒 CloudFront (HTTPS — pode levar 5-15 min):${NC}"
echo -e "    ${YELLOW}https://${CF_DOMAIN}${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_info "A URL do S3 já funciona imediatamente!"
print_info "O CloudFront pode levar 5-15 minutos para propagar globalmente."
echo ""
print_step "Verificando status do CloudFront..."
CF_STATUS=$(aws cloudfront get-distribution \
    --id "$DISTRIBUTION_ID" \
    --query "Distribution.Status" \
    --output text)
echo -e "  Status: ${CF_STATUS}"
echo ""

# ============================================================
# COMANDOS ÚTEIS PÓS-DEPLOY
# ============================================================
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  📋 COMANDOS ÚTEIS PÓS-DEPLOY${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${RED}⚠️  Lembre: credenciais temporárias expiram em 1h!${NC}"
echo -e "  ${RED}   Se expirar, rode novamente o assume-role antes dos comandos abaixo.${NC}"
echo ""
echo -e "  ${YELLOW}Atualizar o site (após mudanças no código):${NC}"
echo "    git -C ${CLONE_DIR} pull"
echo "    cd ${PROJECT_DIR} && npm run build && cd -"
echo "    aws s3 sync ${BUILD_OUTPUT} s3://${BUCKET_NAME} --delete"
echo "    aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'"
echo ""
echo -e "  ${YELLOW}Ver status do CloudFront:${NC}"
echo "    aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --query \"Distribution.Status\""
echo ""
echo -e "  ${YELLOW}Destruir tudo (teardown):${NC}"
echo "    bash teardown-landingpage-awswomengoiania.sh"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  AWS Women User Group Goiânia 🚀${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
