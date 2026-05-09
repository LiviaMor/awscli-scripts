#!/bin/bash
# ============================================================
# 🚀 SCRIPT DE INSTALAÇÃO — Meetup Zero to Hero #1
# AWS Women User Group Goiânia
# 
# Este script instala e configura:
#   1. AWS CLI v2
#   2. Node.js 20 LTS (necessário para build da landing page)
#   3. Kiro CLI
#
# Uso: bash install-setup.sh
# ============================================================

set -e

# Cores para output bonito no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de utilidade
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

# Detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        OS="unknown"
    fi
    echo "$OS"
}

# ============================================================
# ETAPA 1: Verificar pré-requisitos
# ============================================================
print_header "🔍 ETAPA 1: Verificando pré-requisitos"

OS=$(detect_os)
print_info "Sistema operacional detectado: $OS"

# Verificar curl
if command -v curl &> /dev/null; then
    print_success "curl está instalado"
else
    print_error "curl não encontrado. Instale com: sudo apt install curl"
    exit 1
fi

# Verificar unzip (necessário para Linux)
if [[ "$OS" == "linux" ]]; then
    if command -v unzip &> /dev/null; then
        print_success "unzip está instalado"
    else
        print_warning "unzip não encontrado. Instalando..."
        sudo apt-get update && sudo apt-get install -y unzip
        print_success "unzip instalado"
    fi
fi

# ============================================================
# ETAPA 2: Instalar AWS CLI v2
# ============================================================
print_header "☁️  ETAPA 2: Instalando AWS CLI v2"

# Verificar se já está instalado
if command -v aws &> /dev/null; then
    CURRENT_VERSION=$(aws --version 2>&1 | head -1)
    print_warning "AWS CLI já instalado: $CURRENT_VERSION"
    echo ""
    read -p "Deseja reinstalar/atualizar? (s/n): " REINSTALL
    if [[ "$REINSTALL" != "s" && "$REINSTALL" != "S" ]]; then
        print_info "Pulando instalação do AWS CLI..."
    else
        print_step "Atualizando AWS CLI..."
        if [[ "$OS" == "macos" ]]; then
            curl -s "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm -f AWSCLIV2.pkg
        elif [[ "$OS" == "linux" ]]; then
            curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip -qo awscliv2.zip
            sudo ./aws/install --update
            rm -rf aws awscliv2.zip
        fi
        print_success "AWS CLI atualizado!"
    fi
else
    print_step "Baixando e instalando AWS CLI v2..."
    
    if [[ "$OS" == "macos" ]]; then
        curl -s "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm -f AWSCLIV2.pkg
    elif [[ "$OS" == "linux" ]]; then
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -qo awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
    
    print_success "AWS CLI v2 instalado com sucesso!"
fi

# Verificação
echo ""
print_step "Verificando instalação do AWS CLI..."
aws --version
echo ""

# ============================================================
# ETAPA 3: Instalar Node.js (necessário para o deploy da landing page)
# ============================================================
print_header "📦 ETAPA 3: Instalando Node.js 20 LTS"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
    
    if [ "$NODE_MAJOR" -ge 18 ]; then
        print_success "Node.js já instalado: $NODE_VERSION (compatível)"
        echo ""
        read -p "Deseja reinstalar/atualizar? (s/n): " REINSTALL_NODE
        if [[ "$REINSTALL_NODE" != "s" && "$REINSTALL_NODE" != "S" ]]; then
            print_info "Pulando instalação do Node.js..."
        else
            print_step "Atualizando Node.js..."
            if [[ "$OS" == "macos" ]]; then
                if command -v brew &> /dev/null; then
                    brew install node@20
                else
                    curl -fsSL https://nodejs.org/dist/v20.18.0/node-v20.18.0.pkg -o node.pkg
                    sudo installer -pkg node.pkg -target /
                    rm -f node.pkg
                fi
            elif [[ "$OS" == "linux" ]]; then
                curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                sudo apt-get install -y nodejs
            fi
            print_success "Node.js atualizado!"
        fi
    else
        print_warning "Node.js $NODE_VERSION é muito antigo. Precisa ser 18+."
        print_step "Instalando Node.js 20 LTS..."
        if [[ "$OS" == "macos" ]]; then
            if command -v brew &> /dev/null; then
                brew install node@20
            else
                curl -fsSL https://nodejs.org/dist/v20.18.0/node-v20.18.0.pkg -o node.pkg
                sudo installer -pkg node.pkg -target /
                rm -f node.pkg
            fi
        elif [[ "$OS" == "linux" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
        print_success "Node.js 20 LTS instalado!"
    fi
else
    print_step "Instalando Node.js 20 LTS..."
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            brew install node@20
        else
            print_step "Baixando instalador do Node.js..."
            curl -fsSL https://nodejs.org/dist/v20.18.0/node-v20.18.0.pkg -o node.pkg
            sudo installer -pkg node.pkg -target /
            rm -f node.pkg
        fi
    elif [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    print_success "Node.js 20 LTS instalado com sucesso!"
fi

# Verificação
echo ""
print_step "Verificando instalação do Node.js..."
if command -v node &> /dev/null; then
    echo "  Node.js: $(node --version)"
    echo "  npm:     $(npm --version)"
else
    print_warning "Node.js instalado. Reinicie o terminal se não aparecer."
fi
echo ""

# ============================================================
# ETAPA 4: Instalar Kiro CLI
# ============================================================
print_header "🤖 ETAPA 4: Instalando Kiro CLI"

# Verificar se já está instalado
if command -v kiro &> /dev/null; then
    KIRO_VERSION=$(kiro --version 2>&1 | head -1)
    print_warning "Kiro CLI já instalado: $KIRO_VERSION"
    echo ""
    read -p "Deseja reinstalar/atualizar? (s/n): " REINSTALL_KIRO
    if [[ "$REINSTALL_KIRO" != "s" && "$REINSTALL_KIRO" != "S" ]]; then
        print_info "Pulando instalação do Kiro CLI..."
    else
        print_step "Reinstalando Kiro CLI..."
        curl -fsSL https://cli.kiro.dev/install | bash
        print_success "Kiro CLI reinstalado!"
    fi
else
    print_step "Instalando Kiro CLI..."
    echo ""
    
    # Método principal: script de instalação oficial
    curl -fsSL https://cli.kiro.dev/install | bash
    
    print_success "Kiro CLI instalado com sucesso!"
fi

# Recarregar PATH
export PATH="$HOME/.local/bin:$PATH"

# Verificação
echo ""
print_step "Verificando instalação do Kiro CLI..."
if command -v kiro &> /dev/null; then
    kiro --version
    print_success "Kiro CLI está pronto!"
else
    print_warning "Kiro CLI instalado. Reinicie o terminal ou execute:"
    echo -e "  ${CYAN}source ~/.bashrc${NC}  (ou ~/.zshrc se usar zsh)"
fi

# ============================================================
# ETAPA 5: Configurar credenciais AWS
# ============================================================
print_header "🔑 ETAPA 5: Configuração de Credenciais AWS"

echo -e "${YELLOW}Agora vamos configurar suas credenciais AWS.${NC}"
echo ""
echo "Você precisará de:"
echo "  • AWS Access Key ID"
echo "  • AWS Secret Access Key"
echo "  • Região padrão (recomendado: us-east-1)"
echo ""
echo -e "${BLUE}📌 Para criar suas chaves, acesse:${NC}"
echo "   https://console.aws.amazon.com/iam/home#/security_credentials"
echo ""

read -p "Deseja configurar as credenciais agora? (s/n): " CONFIG_AWS
if [[ "$CONFIG_AWS" == "s" || "$CONFIG_AWS" == "S" ]]; then
    aws configure
    print_success "Credenciais AWS configuradas!"
else
    print_info "Você pode configurar depois com: aws configure"
fi

# ============================================================
# ETAPA 6: Autenticar no Kiro CLI
# ============================================================
print_header "🔐 ETAPA 6: Autenticação no Kiro CLI"

echo -e "${YELLOW}O Kiro CLI precisa de autenticação via AWS Builder ID (gratuito).${NC}"
echo ""
echo "Opções de autenticação:"
echo "  1. 🆔 AWS Builder ID (GRATUITO — recomendado para iniciantes)"
echo "  2. 🏢 IAM Identity Center (para uso corporativo)"
echo ""
echo -e "${BLUE}📌 Crie seu Builder ID gratuito em:${NC}"
echo "   https://profile.aws.amazon.com/"
echo ""

read -p "Deseja fazer login no Kiro agora? (s/n): " LOGIN_KIRO
if [[ "$LOGIN_KIRO" == "s" || "$LOGIN_KIRO" == "S" ]]; then
    print_step "Abrindo autenticação no navegador..."
    kiro login
    print_success "Kiro CLI autenticado!"
else
    print_info "Você pode autenticar depois com: kiro login"
fi

# ============================================================
# ETAPA 7: Verificação Final
# ============================================================
print_header "🎯 ETAPA 7: Verificação Final — Check Completo"

echo ""
ERRORS=0

# Check AWS CLI
print_step "Verificando AWS CLI..."
if command -v aws &> /dev/null; then
    AWS_VER=$(aws --version 2>&1 | head -1)
    print_success "AWS CLI: $AWS_VER"
else
    print_error "AWS CLI não encontrado!"
    ((ERRORS++))
fi

# Check AWS Credentials
print_step "Verificando credenciais AWS..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
    print_success "Credenciais válidas! Conta: $ACCOUNT"
else
    print_warning "Credenciais AWS não configuradas ou inválidas"
    print_info "Execute: aws configure"
fi

# Check Node.js
print_step "Verificando Node.js..."
if command -v node &> /dev/null; then
    NODE_VER=$(node --version)
    NPM_VER=$(npm --version 2>/dev/null || echo "não encontrado")
    print_success "Node.js: $NODE_VER | npm: $NPM_VER"
else
    print_warning "Node.js não encontrado no PATH atual"
    print_info "Reinicie o terminal e tente: node --version"
fi

# Check Kiro CLI
print_step "Verificando Kiro CLI..."
if command -v kiro &> /dev/null; then
    KIRO_VER=$(kiro --version 2>&1 | head -1)
    print_success "Kiro CLI: $KIRO_VER"
else
    print_warning "Kiro CLI não encontrado no PATH atual"
    print_info "Reinicie o terminal e tente: kiro --version"
fi

echo ""
print_header "🏁 SETUP CONCLUÍDO!"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║   🎉 Tudo pronto para decolar na AWS!   ║"
    echo "  ║                                          ║"
    echo "  ║   Próximo passo:                         ║"
    echo "  ║   $ kiro chat                            ║"
    echo "  ║                                          ║"
    echo "  ║   E comece a conversar com o Kiro! 🚀    ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
else
    echo -e "${YELLOW}"
    echo "  Setup parcialmente completo."
    echo "  Resolva os erros acima e execute novamente."
    echo -e "${NC}"
fi

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  AWS Women User Group Goiânia — Zero to Hero #1  ${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
