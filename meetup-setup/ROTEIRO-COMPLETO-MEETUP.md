# 🚀 Meetup "Zero to Hero #1" — Roteiro Completo
## Decolando na AWS com Kiro CLI
### AWS Women User Group Goiânia

---

## 🎬 SLIDE 1: Capa

**Visual:** Título grande "Zero to Hero #1", subtítulo "Decolando na AWS com Kiro CLI" e a logo do AWS Women User Group Goiânia.

**Sugestão de fala:**
> "Boa noite, pessoal! Bem-vindas ao nosso primeiro Meetup oficial. Hoje vamos sair do zero e mostrar como a nuvem da AWS pode ser acessível, especialmente com o apoio de IA e ferramentas como o Kiro CLI."

---

## 👩‍💻 SLIDE 2: Quem Somos (As Líderes)

**Visual:** Foto das três, nomes e o curso (ADS).

**Conteúdo:**
- **Kassia:** [Breve resumo/foco]
- **Lívia:** [Breve resumo/foco]
- **Luciana:** [Breve resumo/foco]

**Sugestão de fala:**
> "Somos estudantes de Análise e Desenvolvimento de Sistemas e apaixonadas pela cultura Cloud. Nosso grupo nasceu para conectar mulheres que, assim como nós, querem dominar a AWS e construir carreiras sólidas em tecnologia."

---

## ☁️ SLIDE 3: O que é a AWS? (A Maior Nuvem do Mundo)

**Visual:** Comparativo "Tradicional vs. Nuvem". Gráfico de um Data Center local vs. Nuvem Global.

**Conteúdo:**

### Escala Global
A infraestrutura global da AWS é a nuvem mais segura, confiável e abrangente, fornecendo diversas soluções de infraestrutura para executar suas aplicações em qualquer lugar. Com três zonas de disponibilidade (AZs) por região e data centers otimizados, a infraestrutura global da AWS maximiza a resiliência, o desempenho e a inovação.

Usando mais de 9 milhões de quilômetros de cabeamento de fibra óptica, o backbone de rede global da AWS permite uma transferência de dados mais rápida, latência reduzida e desempenho aprimorado do aplicativo.

**AWS Global Infrastructure:**
- 123 Availability Zones
- 39 Geographic Regions
- Planos para mais 7 AZs e 2 Regiões (Arábia Saudita e Chile)

### Segurança
A essência da AWS: Criptografia e conformidade em todos os níveis.

**Sugestão de fala:**
> "Imagine que antigamente você precisava comprar e manter seus próprios servidores físicos. Com a AWS, você aluga essa infraestrutura sob demanda. É como o serviço de energia elétrica: você usa o que precisa e paga só pelo que consumir, com a segurança de uma rede global gigantesca."

---

## 🌍 SLIDE 4: Alta Disponibilidade

**Visual:** Mapa-múndi com os pontos de presença da AWS.

**Sugestão de fala:**
> "O grande diferencial é a alta disponibilidade. Se um servidor falha em uma cidade, sua aplicação continua rodando em outra. A internet hoje funciona na escala global graças a essa redundância que a AWS oferece."

---

## 📚 SLIDE 5: Primeiros Passos e Educação

**Visual:** Logos do AWS Builder Center e AWS re/Start.

**Conteúdo:**
- Entrar em **comunidades** para apoio, conexão e linguagem técnica
- **AWS Builder Center** — tutoriais e laboratórios práticos
- **AWS re/Start** — programa de preparação para o mercado de trabalho em nuvem

**Sugestão de fala:**
> "Para quem está começando agora, existem caminhos gratuitos. O Builder Center é excelente para tutoriais e o programa re/Start foca justamente em preparar pessoas para o mercado de trabalho em nuvem."

---

## 🆓 SLIDE 6: Mão na Massa (Console e Free Tier)

**Visual:** Print do Console da AWS e destaque para "Free Tier".

**Dica Técnica — Plano Gratuito:**
- ✅ Experimente a AWS por até 6 meses sem custo ou compromisso
- ✅ Receba até 200 USD em créditos
- ✅ Inclui o uso gratuito de serviços selecionados
- ✅ Não há cobranças, a menos que você mude para o plano pago
- ⚠️ Workloads que ultrapassam os limites de crédito podem gerar cobrança
- ✅ Acesso a todos os serviços e recursos da AWS

**Sugestão de fala:**
> "O primeiro passo prático é abrir sua conta. A AWS oferece o nível gratuito por 12 meses. É o laboratório perfeito para testar serviços sem custo, desde que você respeite os limites de cada recurso."

---

## 🤖 SLIDE 7: Por que o Kiro CLI?

**Visual:** Terminal (tela preta) com o Kiro CLI em destaque.

**Conteúdo:**
- **O Diferencial:** Agente de IA focado em infraestrutura e código.
- **Kiro vs. Amazon Q:** Enquanto o Q é mais voltado para o console e chat, o Kiro atua direto no seu terminal (onde o trabalho de infra acontece).
- **Pilares 2.0:** Suporte Windows, Modo Headless e Nova UX.

**Sugestão de fala:**
> "Quando avançamos na AWS, saímos do clique no console e vamos para o terminal (a famosa tela preta). O Kiro CLI é o nosso agente de IA que vive ali. Ele resolve gargalos em segundo plano, tira dúvidas técnicas na hora e ajuda nos guardrails de segurança. É a ponte perfeita para quem quer agilidade sem se perder nos comandos complexos."

---

## 🛠️ SLIDE 8: Setup de Sobrevivência (Como Instalar)

**Visual:** Lista com 3 passos simples, ícones de terminal e o site `kiro.dev/docs/cli/installation/`

**Conteúdo do Slide:**
1. **AWS CLI:** A base de tudo (Configuração de credenciais)
2. **Kiro CLI:** O cérebro de IA no seu terminal
3. **Check:** `kiro --version` (Pronta para decolar!)

**Sugestão de fala:**
> "Agora, vamos para o Setup de Sobrevivência. Para rodar na nuvem, precisamos de duas ferramentas: o AWS CLI, que é a ponte oficial, e o Kiro CLI, que será nosso guia. É uma instalação rápida e, a partir daqui, você não precisa mais decorar centenas de comandos complexos; o Kiro entende suas intenções."

---

### 📋 Comandos de Instalação (Detalhamento Técnico)

#### Passo 1: AWS CLI v2

**macOS:**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
```

**Linux (Ubuntu/Debian):**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

**Windows (PowerShell):**
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
aws --version
```

#### Passo 2: Configurar Credenciais
```bash
aws configure
# AWS Access Key ID: SUA_KEY
# AWS Secret Access Key: SUA_SECRET
# Default region: us-east-1
# Output format: json
```

#### Passo 3: Kiro CLI

**macOS / Linux:**
```bash
curl -fsSL https://cli.kiro.dev/install | bash
```

**macOS via Homebrew:**
```bash
brew install kiro
```

**Windows (PowerShell):**
```powershell
irm 'https://cli.kiro.dev/install.ps1' | iex
```

#### Passo 4: Autenticação e Verificação
```bash
kiro login          # Abre o navegador para autenticar
kiro --version      # Confirmar instalação
```

> 💡 **Dica:** O AWS Builder ID é GRATUITO. Qualquer pessoa cria em 2 minutos: https://profile.aws.amazon.com/

---

## 🎬 SLIDE 9: Kiro na Real (Live Demo)

**Visual:** Diagrama simplificado: **Ideia → Kiro → Deploy**

**Conteúdo do Slide:**
- **Ideia:** Aplicação Completa
- **Infra:** Banco de Dados (RDS) + Segurança (IAM/Guardrails)
- **Ação:** Deploy automatizado via terminal

**Sugestão de fala:**
> "Chegou a hora do 'Kiro na Real'. Vamos mostrar ao vivo como transformar uma ideia simples em uma aplicação estruturada. O Kiro vai nos ajudar a subir o banco de dados, configurar as regras de segurança e fazer o deploy. Tudo o que antes levava horas de configuração, vamos fazer agora com automação e inteligência."

---

### 🎯 Roteiro Técnico da Demo (Para as Líderes)

#### CENA 1: Verificar ambiente
```bash
aws --version
kiro --version
```
> 💬 "Ambiente pronto! Duas ferramentas, prontas para decolar."

#### CENA 2: Entrar no Kiro Chat
```bash
kiro chat
```
> 💬 "Agora vou abrir o Kiro. É como ter uma colega que sabe tudo sobre AWS."

**Digitar no chat:**
```
Preciso criar uma aplicação web simples com banco de dados.
Me ajude a configurar um RDS PostgreSQL com segurança.
```

#### CENA 3: Segurança Automática (Guardrails)
O Kiro vai sugerir automaticamente:
- ✅ Security Group dedicado
- ✅ Subnet privada (banco não exposto)
- ✅ Criptografia habilitada
- ✅ Senha forte via Secrets Manager

> 💬 "Vejam que o Kiro já me avisou sobre segurança! Ele sugeriu que o banco precisa estar numa subnet privada e com criptografia. Isso é guardrail automático."

#### CENA 4: Comparação Dramática

**❌ Sem Kiro (CLI puro — 15 linhas!):**
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
  --no-publicly-accessible
```

> 💬 "ESTE é o comando que teríamos que digitar na mão. 15 linhas, 10 parâmetros que precisam estar certos. Um erro e o banco fica exposto."

**✅ Com Kiro (1 frase!):**
```
Crie um banco PostgreSQL Free Tier, com criptografia, sem acesso público, backup de 7 dias.
```

> 💬 "1 frase vs. 15 linhas. ISSO é produtividade."

#### CENA 5: Verificar recursos
```bash
aws rds describe-db-instances \
  --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]" \
  --output table
```

> 💬 "Banco criado, rodando, seguro. Do zero ao deploy em minutos!"

#### CENA 6: Gran Finale — Resumo
No chat do Kiro:
```
Me dê um resumo dos recursos AWS criados, custos estimados e recomendações de segurança.
```

> 💬 "O Kiro me dá: o que criou, quanto custa, e o que posso melhorar. É como uma consultora AWS 24h no terminal."

---

## 🎤 SLIDE 10: Encerramento e Q&A

**Visual:** QR Code para o LinkedIn das líderes e link do próximo encontro.

**Sugestão de fala:**
> "Queremos ouvir vocês agora! Dúvidas? Conexões? Estamos à disposição para ajudar vocês a decolarem nessa jornada."

---

## 🛡️ Plano B — Caso a Demo Ao Vivo Falhe

1. 📸 Screenshots do `kiro --version` funcionando
2. 📸 Screenshot do chat do Kiro respondendo
3. 📸 Screenshot do RDS criado no Console AWS
4. 🎥 Vídeo curto (30s-1min) de backup com o fluxo completo

> 💡 **Dica:** Gravem um vídeo antes do Meetup. Se a internet cair, vocês têm backup!

---

## 📌 Links Úteis (Para os Slides)

| Recurso | Link |
|---------|------|
| AWS CLI - Instalação | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| Kiro CLI - Instalação | https://kiro.dev/docs/cli/installation/ |
| Kiro CLI - Getting Started | https://kiro.dev/docs/cli/ |
| AWS Free Tier | https://aws.amazon.com/free/ |
| AWS Builder ID (Gratuito) | https://profile.aws.amazon.com/ |
| Kiro CLI - Autenticação | https://kiro.dev/docs/cli/authentication |
| AWS re/Start | https://aws.amazon.com/training/restart/ |

---

## 🎤 Cola Rápida — Falas-Chave por Slide

| Slide | Fala Principal |
|-------|---------------|
| 1 | "Bem-vindas ao nosso primeiro Meetup oficial!" |
| 2 | "Somos estudantes de ADS apaixonadas pela cultura Cloud." |
| 3 | "É como energia elétrica: usa o que precisa, paga o que consumir." |
| 4 | "Se um servidor falha, sua aplicação continua rodando em outra cidade." |
| 5 | "Existem caminhos gratuitos. O re/Start prepara para o mercado." |
| 6 | "O Free Tier é o laboratório perfeito para testar sem custo." |
| 7 | "O Kiro é a ponte perfeita para quem quer agilidade sem decorar comandos." |
| 8 | "5 minutos de instalação e agora temos um superpoder no terminal." |
| 9 | "1 frase vs. 15 linhas de comando. ISSO é produtividade." |
| 10 | "Queremos ouvir vocês! Dúvidas? Conexões?" |

---

## ⏱️ Tempo Estimado por Slide

| Slide | Conteúdo | Tempo |
|-------|----------|-------|
| 1 | Capa | 1 min |
| 2 | Quem Somos | 2 min |
| 3 | O que é AWS | 3 min |
| 4 | Alta Disponibilidade | 2 min |
| 5 | Primeiros Passos | 2 min |
| 6 | Console e Free Tier | 3 min |
| 7 | Por que Kiro CLI | 3 min |
| 8 | Setup de Sobrevivência | 5-7 min |
| 9 | Kiro na Real (Demo) | 10-15 min |
| 10 | Encerramento e Q&A | 5-10 min |
| **TOTAL** | | **36-48 min** |

---

*AWS Women User Group Goiânia — Zero to Hero #1* 🚀
