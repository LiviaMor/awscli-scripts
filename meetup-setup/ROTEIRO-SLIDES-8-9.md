# 🚀 Meetup Zero to Hero #1 — Roteiro Técnico (Slides 8 e 9)
## AWS Women User Group Goiânia

---

## 📋 SLIDE 8: Setup de Sobrevivência (Mão na Massa)

### Passo 1: Instalação do AWS CLI v2

#### 🍎 macOS
```bash
# Download do instalador
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

# Instalar
sudo installer -pkg AWSCLIV2.pkg -target /

# Verificar instalação
aws --version
```

#### 🐧 Linux (Ubuntu/Debian)
```bash
# Download do instalador
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Descompactar
unzip awscliv2.zip

# Instalar
sudo ./aws/install

# Verificar instalação
aws --version
```

#### 🪟 Windows
```powershell
# Baixar o instalador MSI direto do site:
# https://awscli.amazonaws.com/AWSCLIV2.msi

# Ou via PowerShell:
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verificar instalação (abrir novo terminal)
aws --version
```

#### ✅ Saída esperada:
```
aws-cli/2.x.x Python/3.x.x Linux/x86_64
```

---

### Passo 2: Configurar Credenciais AWS

```bash
# Configuração básica (Access Key + Secret Key)
aws configure
```

**O que será pedido:**
```
AWS Access Key ID [None]: SUA_ACCESS_KEY
AWS Secret Access Key [None]: SUA_SECRET_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

> 💡 **Dica para a apresentação:** "Essa é a chave do carro. Sem ela, o AWS CLI não sabe quem você é."

---

### Passo 3: Instalação do Kiro CLI

#### 🍎 macOS / 🐧 Linux (Comando Universal)
```bash
# Instalar o Kiro CLI (uma única linha!)
curl -fsSL https://cli.kiro.dev/install | bash
```

#### 🍺 macOS via Homebrew (alternativa)
```bash
brew install kiro
```

#### 🪟 Windows (PowerShell)
```powershell
# Abrir Windows Terminal ou PowerShell e executar:
irm 'https://cli.kiro.dev/install.ps1' | iex
```

> ⚠️ **Nota:** Windows requer Windows 11. Use Windows Terminal para melhor experiência.

---

### Passo 4: Autenticação do Kiro CLI

```bash
# Fazer login (abrirá o navegador automaticamente)
kiro login
```

**Opções de autenticação:**
- 🆔 **AWS Builder ID** (gratuito — ideal para quem está começando!)
- 🏢 **IAM Identity Center** (para empresas)

> 💡 **Dica para a apresentação:** "O Builder ID é gratuito. Qualquer pessoa pode criar em 2 minutos e já sair usando."

---

### Passo 5: Verificação Final (O "Check" ✅)

```bash
# Verificar se tudo está funcionando
kiro --version

# Testar com uma pergunta rápida
kiro chat
```

**Saída esperada do `kiro --version`:**
```
kiro-cli/x.x.x
```

> 🎯 **Sugestão de fala:** "Pronto! Duas ferramentas, 5 minutos de instalação, e agora temos um superpoder no terminal."

---

## 🎬 SLIDE 9: Kiro na Real (Live Demo)

### Roteiro Técnico para as Líderes

---

### 🎯 Objetivo da Demo
Mostrar o fluxo: **Ideia → Kiro → Deploy**
Transformar uma aplicação simples em infra real na AWS com ajuda do Kiro.

---

### Parte 1: Iniciar o Kiro Chat

```bash
# Entrar no modo chat interativo
kiro chat
```

> 💬 **Fala:** "Agora estou dentro do Kiro. Posso conversar com ele como se fosse um colega de trabalho que sabe TUDO sobre AWS."

---

### Parte 2: Pedir ajuda para criar infraestrutura

Dentro do chat do Kiro, digitar:

```
Preciso criar uma aplicação web simples com banco de dados.
Me ajude a configurar um RDS PostgreSQL com as melhores práticas de segurança.
```

> 💬 **Fala:** "Vejam que eu não precisei decorar nenhum comando. Só disse o que preciso e o Kiro entende minha intenção."

---

### Parte 3: O Kiro sugere segurança automaticamente

O Kiro vai sugerir:
- ✅ Security Group dedicado para o RDS
- ✅ Subnet privada (banco não exposto à internet)
- ✅ Senha forte via AWS Secrets Manager
- ✅ Criptografia habilitada

> 💬 **Fala:** "Vejam que o Kiro já me avisou sobre segurança! Ele sugeriu que o banco precisa estar numa subnet privada e com criptografia. Isso é guardrail automático."

---

### Parte 4: Comparação — CLI Tradicional vs. Kiro

#### ❌ Sem Kiro (comando AWS CLI puro — assustador!):
```bash
aws rds create-db-instance \
  --db-instance-identifier meu-banco \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username admin \
  --master-user-password MinhaS3nhaF0rt3! \
  --allocated-storage 20 \
  --storage-type gp3 \
  --vpc-security-group-ids sg-0abc123def456 \
  --db-subnet-group-name minha-subnet-group \
  --storage-encrypted \
  --backup-retention-period 7 \
  --multi-az \
  --no-publicly-accessible \
  --tags Key=Environment,Value=production Key=Project,Value=meetup
```

> 💬 **Fala:** "ESTE é o comando que teríamos que digitar na mão. 15 linhas, 10 parâmetros que precisam estar certos. Um erro de digitação e o banco fica exposto à internet."

#### ✅ Com Kiro (linguagem natural):
```
Crie um banco PostgreSQL com Free Tier, criptografia habilitada, 
sem acesso público, com backup de 7 dias.
```

> 💬 **Fala:** "Com o Kiro, eu disse em português o que preciso. Ele monta o comando, valida a segurança, e ainda me pergunta antes de executar. ISSO é produtividade."

---

### Parte 5: Verificar recursos criados

```bash
# Listar instâncias RDS
aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]" --output table

# Verificar Security Groups
aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='meetup-rds-sg']" --output table
```

> 💬 **Fala:** "E aqui confirmamos: banco criado, rodando, seguro. Do zero ao deploy em minutos."

---

### Parte 6: Gran Finale — Pedir um resumo ao Kiro

No chat do Kiro:
```
Me dê um resumo de todos os recursos AWS que acabamos de criar, 
incluindo custos estimados e recomendações de segurança.
```

> 💬 **Fala:** "Para fechar com chave de ouro: o Kiro me dá um relatório completo. Quanto vou gastar, o que está seguro, e o que posso melhorar. É como ter uma consultora AWS 24h no seu terminal."

---

## 🛡️ Plano B — Caso a Demo Ao Vivo Falhe

### Prints de Reserva para mostrar:
1. Screenshot do `kiro --version` funcionando
2. Screenshot do chat do Kiro respondendo
3. Screenshot do RDS criado no Console AWS
4. Vídeo curto (30s) de backup com o fluxo completo

> 💡 **Dica:** Gravem um vídeo de 1 minuto antes do Meetup mostrando todo o fluxo. Se a internet cair, vocês têm o backup perfeito!

---

## 📌 Links Úteis para Colocar nos Slides

| Recurso | Link |
|---------|------|
| AWS CLI - Instalação | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| Kiro CLI - Instalação | https://kiro.dev/docs/cli/installation/ |
| Kiro CLI - Getting Started | https://kiro.dev/docs/cli/ |
| AWS Free Tier | https://aws.amazon.com/free/ |
| AWS Builder ID (Gratuito) | https://profile.aws.amazon.com/ |
| Kiro CLI - Autenticação | https://kiro.dev/docs/cli/authentication |

---

## 🎤 Resumo das Falas-Chave (Cola Rápida)

| Momento | Fala |
|---------|------|
| Início Setup | "Para rodar na nuvem, precisamos de duas ferramentas: AWS CLI e Kiro CLI." |
| Após instalar | "5 minutos de instalação e agora temos um superpoder no terminal." |
| Início Demo | "Vou conversar com o Kiro como se fosse um colega de trabalho." |
| Segurança | "Vejam que o Kiro já me avisou sobre segurança automaticamente!" |
| Comparação | "15 linhas de comando vs. 1 frase em português. ISSO é produtividade." |
| Encerramento | "Do zero ao deploy em minutos, com segurança e sem decorar nada." |

---

## ⏱️ Tempo Estimado

| Slide | Tempo |
|-------|-------|
| Slide 8 (Setup) | 5-7 minutos |
| Slide 9 (Demo) | 10-15 minutos |
| **Total** | **15-22 minutos** |

---

*Criado para o Meetup "Zero to Hero #1" — AWS Women User Group Goiânia* 🚀
