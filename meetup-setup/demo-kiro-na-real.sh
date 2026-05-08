#!/bin/bash
# ============================================================
# 🎬 DEMO SCRIPT — "Kiro na Real" (Slide 9)
# AWS Women User Group Goiânia — Zero to Hero #1
#
# ⚠️  IMPORTANTE: Este script é um GUIA para a apresentadora.
# Não execute tudo automaticamente! Siga passo a passo.
#
# Objetivo: Mostrar o fluxo Ideia → Kiro → Deploy
# ============================================================

# Cores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

clear
echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║          🎬 DEMO: Kiro na Real                   ║"
echo "  ║     AWS Women User Group Goiânia                 ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""


# ============================================================
# CENA 1: Conversa com o Kiro — acesso e permissões
# ============================================================
clear
echo -e "${CYAN}━━━ CENA 1: Conversando com o Kiro ━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Vou abrir o Kiro e conversar com ele como se fosse"
echo "   minha primeira vez usando AWS. Olhem como é natural.\""
echo ""
echo -e "${YELLOW}Comando:${NC} kiro chat"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}👩 Você:${NC}"
echo "  Kiro, nunca usei AWS pelo terminal. Como faço para ter"
echo "  acesso à minha conta? Preciso de alguma permissão especial?"
echo ""
echo -e "${CYAN}🤖 Kiro:${NC}"
echo "  Claro! Para acessar sua conta AWS pelo terminal, você precisa"
echo "  de algumas coisas configuradas. Vou te explicar:"
echo ""
echo "  1. **IAM User** — É sua identidade na AWS. Você cria um usuário"
echo "     no serviço IAM e ele recebe credenciais (Access Key ID +"
echo "     Secret Access Key) para autenticar no terminal."
echo ""
echo "  2. **IAM Policy** — É um documento JSON que define O QUE você"
echo "     pode fazer. Sem policy, seu usuário existe mas não faz nada."
echo "     Exemplo: para criar um banco de dados, precisa de permissão"
echo "     em \"rds:CreateDBInstance\"."
echo ""
echo "  3. **IAM Role** — Identidade temporária. Em vez de usar suas"
echo "     chaves permanentes, você \"assume\" uma role via STS e recebe"
echo "     credenciais que expiram. Mais seguro!"
echo ""
echo "  4. **STS (Security Token Service)** — Serviço que gera essas"
echo "     credenciais temporárias. Ideal para não deixar chaves fixas."
echo ""
echo "  5. **Princípio do Menor Privilégio** — Dê ao usuário APENAS as"
echo "     permissões que ele precisa. Nada mais."
echo ""
echo "  Para começar, rode: aws configure"
echo "  Depois valide com: aws sts get-caller-identity"
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}👩 Você:${NC}"
echo "  E quais permissões eu preciso pra criar um banco de dados RDS?"
echo ""
echo -e "${CYAN}🤖 Kiro:${NC}"
echo "  Para criar um RDS PostgreSQL com segurança, seu usuário precisa"
echo "  dessas permissões mínimas:"
echo ""
echo '  {'
echo '    "Version": "2012-10-17",'
echo '    "Statement": [{'
echo '      "Effect": "Allow",'
echo '      "Action": ['
echo '        "rds:CreateDBInstance", "rds:DescribeDBInstances",'
echo '        "rds:DeleteDBInstance", "rds:CreateDBSubnetGroup",'
echo '        "ec2:DescribeVpcs", "ec2:DescribeSubnets",'
echo '        "ec2:DescribeSecurityGroups", "ec2:CreateSecurityGroup",'
echo '        "ec2:AuthorizeSecurityGroupIngress"'
echo '      ],'
echo '      "Resource": "*"'
echo '    }]'
echo '  }'
echo ""
echo "  ⚠️  Nunca use a conta root! Crie um usuário IAM dedicado."
echo "  Se quiser, posso criar essa policy pra você agora."
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Viram? Perguntei em português, sem saber nada, e o Kiro"
echo "   me explicou IAM, policies, roles, STS e já me deu o JSON"
echo "   pronto. Vamos validar que estou autenticada:\""
echo ""
echo -e "${YELLOW}Comando:${NC} aws sts get-caller-identity"
aws sts get-caller-identity 2>/dev/null || echo -e "${RED}⚠️  Credenciais não configuradas!${NC}"
echo ""
read -p "⏸️  [Pressione ENTER para continuar a demo...]"

# ============================================================
# CENA 2: Entrar no Kiro Chat
# ============================================================
clear
echo -e "${CYAN}━━━ CENA 2: Iniciando o Kiro Chat ━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Agora vou abrir o Kiro. É como ter uma colega"
echo "   que sabe tudo sobre AWS, direto no meu terminal.\""
echo ""
echo -e "${YELLOW}Comando:${NC} kiro chat"
echo ""
echo -e "${GREEN}📝 Dentro do chat, digite:${NC}"
echo ""
echo "  \"Preciso criar uma aplicação web simples com banco de dados."
echo "   Me ajude a configurar um RDS PostgreSQL com segurança.\""
echo ""
read -p "⏸️  [Execute 'kiro chat' agora. ENTER quando terminar...]"

# ============================================================
# CENA 3: Destacar a segurança automática
# ============================================================
clear
echo -e "${CYAN}━━━ CENA 3: O Kiro sugere SEGURANÇA automaticamente ━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Vejam! Eu não pedi, mas o Kiro já está me avisando"
echo "   sobre segurança. Ele sugeriu:\""
echo ""
echo -e "  ${GREEN}✅ Security Group dedicado${NC}"
echo -e "  ${GREEN}✅ Subnet privada (banco não fica exposto)${NC}"
echo -e "  ${GREEN}✅ Criptografia habilitada${NC}"
echo -e "  ${GREEN}✅ Senha forte via Secrets Manager${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Isso são GUARDRAILS de segurança automáticos."
echo "   O Kiro não deixa você criar algo inseguro sem avisar.\""
echo ""
read -p "⏸️  [Pressione ENTER para continuar...]"

# ============================================================
# CENA 4: Comparação Dramática
# ============================================================
clear
echo -e "${CYAN}━━━ CENA 4: CLI Tradicional vs. Kiro ━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Agora olhem o que seria fazer isso SEM o Kiro...\""
echo ""
echo -e "\033[0;31m❌ Comando AWS CLI puro (15 linhas!):\033[0m"
echo ""
echo "  aws rds create-db-instance \\"
echo "    --db-instance-identifier meu-banco \\"
echo "    --db-instance-class db.t3.micro \\"
echo "    --engine postgres \\"
echo "    --engine-version 15.4 \\"
echo "    --master-username admin \\"
echo "    --master-user-password MinhaS3nhaF0rt3! \\"
echo "    --allocated-storage 20 \\"
echo "    --storage-type gp3 \\"
echo "    --vpc-security-group-ids sg-0abc123def456 \\"
echo "    --db-subnet-group-name minha-subnet-group \\"
echo "    --storage-encrypted \\"
echo "    --backup-retention-period 7 \\"
echo "    --multi-az \\"
echo "    --no-publicly-accessible"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"15 linhas. 10 parâmetros que precisam estar CERTOS."
echo "   Um erro de digitação e seu banco fica EXPOSTO na internet.\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Com o Kiro (1 frase em português!):\033[0m"
echo ""
echo "  \"Crie um banco PostgreSQL Free Tier, com criptografia,"
echo "   sem acesso público, backup de 7 dias.\""
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"1 frase vs. 15 linhas. ISSO é produtividade.\""
echo ""
read -p "⏸️  [Pressione ENTER para continuar...]"

# ============================================================
# CENA 5: Verificar o que foi criado
# ============================================================
clear
echo -e "${CYAN}━━━ CENA 5: Verificando os recursos criados ━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Agora vamos confirmar que tudo foi criado certinho.\""
echo ""
echo -e "${YELLOW}Comando:${NC}"
echo "  aws rds describe-db-instances \\"
echo "    --query \"DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]\" \\"
echo "    --output table"
echo ""
echo -e "${GREEN}Saída esperada:${NC}"
echo "  ┌─────────────────┬───────────┬──────────┐"
echo "  │  meu-banco      │ available │ postgres │"
echo "  └─────────────────┴───────────┴──────────┘"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Banco criado, rodando, seguro. Do zero ao deploy"
echo "   em minutos!\""
echo ""
read -p "⏸️  [Pressione ENTER para continuar...]"

# ============================================================
# CENA 6: Gran Finale — Resumo com Kiro
# ============================================================
clear
echo -e "${CYAN}━━━ CENA 6: Gran Finale — Resumo e Custos ━━━${NC}"
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"Para fechar com chave de ouro, vou pedir ao Kiro"
echo "   um relatório completo do que criamos.\""
echo ""
echo -e "${GREEN}📝 No chat do Kiro, digite:${NC}"
echo ""
echo "  \"Me dê um resumo dos recursos AWS criados,"
echo "   custos estimados e recomendações de segurança.\""
echo ""
echo -e "${YELLOW}💬 Fala:${NC} \"O Kiro me dá: o que criou, quanto custa, e o que"
echo "   posso melhorar. É como uma consultora AWS 24h no terminal.\""
echo ""
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}           🎉 FIM DA DEMO! 🎉${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}  Mensagem final:${NC}"
echo ""
echo "  \"Vocês viram o poder da combinação AWS CLI + Kiro."
echo "   Sem decorar nada. Sem medo de errar. Com segurança"
echo "   automática. É a nuvem acessível para TODAS.\""
echo ""
echo -e "${PURPLE}  AWS Women User Group Goiânia — Zero to Hero #1 🚀${NC}"
echo ""
