#!/bin/bash
# ============================================================
# 🧹 TEARDOWN — Destruir Landing Page AWS Women Goiânia
#
# Este script remove TODOS os recursos criados pelo deploy:
#   1. Esvazia e deleta o bucket S3
#   2. Desabilita e deleta a distribuição CloudFront
#   3. Remove o clone local do repositório
#
# Profile AWS: awscli
# Role: arn:aws:iam::794038217446:role/role-time-dev
# Região: us-east-1
#
# ⚠️  Usa credenciais temporárias via assume-role
#     (mesmo modelo do script de deploy)
#
# Uso: bash teardown-landingpage-awswomengoiania.sh
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURAÇÕES (devem bater com o script de deploy)
# ============================================================
AWS_PROFILE="awscli"
AWS_REGION="us-east-1"
BUCKET_NAME="awswomengoiania-landingpage"
CLONE_DIR="/tmp/awswomengoiania"
ROLE_ARN="arn:aws:iam::794038217446:role/role-time-dev"
SESSION_NAME="teardown-landingpage"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${RED}============================================================${NC}"
    echo -e "${RED}  $1${NC}"
    echo -e "${RED}============================================================${NC}"
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
# CONFIRMAÇÃO DE SEGURANÇA
# ============================================================
print_header "🧹 TEARDOWN — Destruição de Recursos AWS"

echo -e "${RED}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  ⚠️  ATENÇÃO: ESTA AÇÃO É IRREVERSÍVEL!             ║"
echo "  ║                                                      ║"
echo "  ║  Este script vai DELETAR permanentemente:            ║"
echo "  ║                                                      ║"
echo "  ║  • Bucket S3: ${BUCKET_NAME}        ║"
echo "  ║  • Todos os arquivos dentro do bucket                ║"
echo "  ║  • Distribuição CloudFront associada                 ║"
echo "  ║  • Clone local em ${CLONE_DIR}              ║"
echo "  ║                                                      ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

read -p "Tem certeza que deseja destruir TUDO? (digite 'sim' para confirmar): " CONFIRM
if [[ "$CONFIRM" != "sim" ]]; then
    echo ""
    print_info "Teardown cancelado. Nenhum recurso foi removido."
    exit 0
fi

echo ""
read -p "Última chance! Confirma a destruição dos recursos na conta AWS? (s/n): " CONFIRM2
if [[ "$CONFIRM2" != "s" && "$CONFIRM2" != "S" ]]; then
    print_info "Teardown cancelado."
    exit 0
fi

echo ""

# ============================================================
# ETAPA 0: Validar credenciais e assumir role
# ============================================================
print_header "🔍 ETAPA 0: Validando credenciais e assumindo role"

if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --output text &> /dev/null; then
    print_error "Profile '${AWS_PROFILE}' inválido ou expirado."
    print_info "Configure com: aws configure --profile ${AWS_PROFILE}"
    exit 1
fi

CALLER_ARN=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query "Arn" --output text)
print_success "Profile base autenticado: ${CALLER_ARN}"

# Assumir role para obter permissões reais
print_step "Assumindo role: ${ROLE_ARN}..."
CREDENTIALS=$(aws sts assume-role \
    --profile "$AWS_PROFILE" \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text 2>&1) || {
    print_error "Falha ao assumir role: ${ROLE_ARN}"
    print_info "Seu IAM user precisa estar autorizado na Trust Policy da role."
    exit 1
}

read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "$CREDENTIALS"
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
print_success "Role assumida! Conta: ${ACCOUNT_ID}"

# A partir daqui, todos os comandos AWS usam as credenciais temporárias

# ============================================================
# ETAPA 1: Encontrar e desabilitar distribuição CloudFront
# ============================================================
print_header "⚡ ETAPA 1: Removendo CloudFront"

S3_WEBSITE_ENDPOINT="${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"

# Buscar distribuição associada ao bucket
print_step "Buscando distribuição CloudFront associada ao bucket..."

DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Origins.Items[0].DomainName=='${S3_WEBSITE_ENDPOINT}' || Origins.Items[0].DomainName=='${BUCKET_NAME}.s3.amazonaws.com'].Id" \
    --output text 2>/dev/null || echo "")

if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" == "None" ]; then
    print_warning "Nenhuma distribuição CloudFront encontrada. Pulando..."
else
    print_info "Distribuição encontrada: ${DISTRIBUTION_ID}"

    # Verificar status atual
    CF_STATUS=$(aws cloudfront get-distribution \
        --id "$DISTRIBUTION_ID" \
        --query "Distribution.Status" \
        --output text)

    CF_ENABLED=$(aws cloudfront get-distribution-config \
        --id "$DISTRIBUTION_ID" \
        --query "DistributionConfig.Enabled" \
        --output text)

    print_info "Status: ${CF_STATUS} | Enabled: ${CF_ENABLED}"

    # Se está habilitada, precisamos desabilitar primeiro
    if [ "$CF_ENABLED" == "true" ]; then
        print_step "Desabilitando distribuição CloudFront..."

        # Obter ETag e config atual
        ETAG=$(aws cloudfront get-distribution-config \
            --id "$DISTRIBUTION_ID" \
            --query "ETag" \
            --output text)

        # Salvar config atual e modificar Enabled para false
        aws cloudfront get-distribution-config \
            --id "$DISTRIBUTION_ID" \
            --query "DistributionConfig" \
            --output json > /tmp/cf-disable-config.json

        # Trocar Enabled de true para false
        if command -v python3 &> /dev/null; then
            python3 -c "
import json
with open('/tmp/cf-disable-config.json', 'r') as f:
    config = json.load(f)
config['Enabled'] = False
with open('/tmp/cf-disable-config.json', 'w') as f:
    json.dump(config, f)
"
        elif command -v sed &> /dev/null; then
            sed -i 's/"Enabled": true/"Enabled": false/g' /tmp/cf-disable-config.json
        fi

        # Aplicar config desabilitada
        aws cloudfront update-distribution \
            --id "$DISTRIBUTION_ID" \
            --if-match "$ETAG" \
            --distribution-config file:///tmp/cf-disable-config.json > /dev/null

        print_success "Distribuição desabilitada!"
        print_warning "Aguardando CloudFront propagar a desabilitação..."
        print_info "Isso pode levar 5-15 minutos. O script vai aguardar..."

        # Aguardar até ficar Deployed
        WAIT_COUNT=0
        MAX_WAIT=60  # 60 x 15s = 15 minutos máximo
        while true; do
            CF_STATUS=$(aws cloudfront get-distribution \
                --id "$DISTRIBUTION_ID" \
                --query "Distribution.Status" \
                --output text 2>/dev/null)

            if [ "$CF_STATUS" == "Deployed" ]; then
                break
            fi

            WAIT_COUNT=$((WAIT_COUNT + 1))
            if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
                print_warning "Timeout aguardando CloudFront. Continuando mesmo assim..."
                break
            fi

            echo -ne "\r  ⏳ Aguardando... Status: ${CF_STATUS} (${WAIT_COUNT}/${MAX_WAIT})"
            sleep 15
        done
        echo ""
        print_success "CloudFront está Deployed!"
    fi

    # Agora deletar a distribuição
    print_step "Deletando distribuição CloudFront..."

    # Obter ETag atualizado
    ETAG=$(aws cloudfront get-distribution-config \
        --id "$DISTRIBUTION_ID" \
        --query "ETag" \
        --output text)

    if aws cloudfront delete-distribution \
        --id "$DISTRIBUTION_ID" \
        --if-match "$ETAG" 2>/dev/null; then
        print_success "Distribuição CloudFront deletada: ${DISTRIBUTION_ID}"
    else
        print_warning "Não foi possível deletar a distribuição agora."
        print_info "Pode ser que ainda esteja propagando. Tente manualmente depois:"
        echo "  aws cloudfront delete-distribution --id ${DISTRIBUTION_ID} --if-match ETAG"
    fi

    # Limpar arquivo temporário
    rm -f /tmp/cf-disable-config.json
fi

# ============================================================
# ETAPA 2: Esvaziar bucket S3
# ============================================================
print_header "🪣 ETAPA 2: Esvaziando bucket S3"

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    print_step "Removendo todos os objetos do bucket '${BUCKET_NAME}'..."

    # Contar objetos antes
    OBJ_COUNT=$(aws s3 ls "s3://${BUCKET_NAME}" --recursive 2>/dev/null | wc -l)
    print_info "Objetos encontrados: ${OBJ_COUNT}"

    # Remover todos os objetos
    aws s3 rm "s3://${BUCKET_NAME}" --recursive
    print_success "Todos os objetos removidos!"

    # Remover versões (caso o bucket tenha versionamento)
    print_step "Verificando objetos versionados..."
    VERSIONS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --query "Versions[].{Key:Key,VersionId:VersionId}" \
        --output text 2>/dev/null || echo "")

    if [ -n "$VERSIONS" ] && [ "$VERSIONS" != "None" ]; then
        print_step "Removendo versões antigas..."
        aws s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --query "Versions[]" \
            --output json 2>/dev/null | \
        python3 -c "
import json, sys, subprocess
versions = json.load(sys.stdin)
if versions:
    for v in versions:
        subprocess.run([
            'aws', 's3api', 'delete-object',
            '--bucket', '${BUCKET_NAME}',
            '--key', v['Key'],
            '--version-id', v['VersionId']
        ], capture_output=True)
    print(f'  Removidas {len(versions)} versoes.')
" 2>/dev/null || true
    fi

    # Remover delete markers
    DELETE_MARKERS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --query "DeleteMarkers[]" \
        --output json 2>/dev/null || echo "[]")

    if [ "$DELETE_MARKERS" != "[]" ] && [ "$DELETE_MARKERS" != "null" ]; then
        print_step "Removendo delete markers..."
        echo "$DELETE_MARKERS" | python3 -c "
import json, sys, subprocess
markers = json.load(sys.stdin)
if markers:
    for m in markers:
        subprocess.run([
            'aws', 's3api', 'delete-object',
            '--bucket', '${BUCKET_NAME}',
            '--key', m['Key'],
            '--version-id', m['VersionId']
        ], capture_output=True)
    print(f'  Removidos {len(markers)} delete markers.')
" 2>/dev/null || true
    fi

    print_success "Bucket esvaziado completamente!"
else
    print_warning "Bucket '${BUCKET_NAME}' não encontrado. Pulando..."
fi

# ============================================================
# ETAPA 3: Deletar bucket S3
# ============================================================
print_header "🗑️  ETAPA 3: Deletando bucket S3"

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    print_step "Deletando bucket '${BUCKET_NAME}'..."
    aws s3api delete-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION"
    print_success "Bucket deletado!"
else
    print_warning "Bucket já não existe. Pulando..."
fi

# ============================================================
# ETAPA 4: Remover clone local
# ============================================================
print_header "📁 ETAPA 4: Removendo arquivos locais"

if [ -d "$CLONE_DIR" ]; then
    print_step "Removendo ${CLONE_DIR}..."
    rm -rf "$CLONE_DIR"
    print_success "Diretório local removido!"
else
    print_warning "Diretório ${CLONE_DIR} não encontrado. Pulando..."
fi

# ============================================================
# VERIFICAÇÃO FINAL
# ============================================================
print_header "🎯 Verificação Final"

echo ""
ERRORS=0

# Verificar bucket
print_step "Verificando se bucket foi removido..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    print_error "Bucket ainda existe!"
    ((ERRORS++))
else
    print_success "Bucket removido com sucesso"
fi

# Verificar CloudFront
print_step "Verificando se CloudFront foi removido..."
REMAINING_DIST=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Origins.Items[0].DomainName=='${S3_WEBSITE_ENDPOINT}' || Origins.Items[0].DomainName=='${BUCKET_NAME}.s3.amazonaws.com'].Id" \
    --output text 2>/dev/null || echo "")

if [ -n "$REMAINING_DIST" ] && [ "$REMAINING_DIST" != "None" ]; then
    print_warning "Distribuição CloudFront ainda existe (pode estar desabilitando): ${REMAINING_DIST}"
    print_info "Delete manualmente quando o status for 'Deployed':"
    echo "  aws cloudfront delete-distribution --id ${REMAINING_DIST} --if-match ETAG"
else
    print_success "CloudFront removido com sucesso"
fi

# Verificar diretório local
print_step "Verificando diretório local..."
if [ -d "$CLONE_DIR" ]; then
    print_error "Diretório local ainda existe!"
    ((ERRORS++))
else
    print_success "Diretório local removido"
fi

echo ""
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $ERRORS -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║   🧹 TEARDOWN COMPLETO!                              ║"
    echo "  ║                                                      ║"
    echo "  ║   Todos os recursos foram removidos com sucesso.     ║"
    echo "  ║   Sua conta AWS está limpa.                          ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
else
    echo ""
    echo -e "${YELLOW}"
    echo "  Teardown parcialmente completo."
    echo "  Verifique os itens com erro acima."
    echo -e "${NC}"
fi

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  AWS Women User Group Goiânia 🧹${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
