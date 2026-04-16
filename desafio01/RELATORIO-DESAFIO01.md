# Relatório Final — Desafio 01

**Gerenciamento de EC2 e S3 via AWS CLI com Role Temporária e Agente de IA**

Data: 23/03/2026
Autora: Livia

---

## 1. Objetivo do Desafio

Gerenciar instâncias EC2 e sincronizar arquivos com o S3 usando AWS CLI, com as seguintes restrições:

- O usuário IAM configurado na CLI **não possui nenhuma policy atachada** diretamente
- Toda operação é feita via **AssumeRole** com credenciais temporárias (STS)
- Uma **role específica** (`role-time-dev`) concentra as permissões para EC2 e S3
- O processo foi construído com auxílio de **agente de IA** (Kiro CLI)

---

## 2. Arquitetura de Segurança

```
┌──────────────────┐     AssumeRole      ┌─────────────────────┐
│  Usuário IAM     │ ──────────────────►  │  role-time-dev      │
│  (sem policies)  │   STS Token temp.    │  (EC2 + S3 perms)   │
│  profile: awscli │ ◄──────────────────  │                     │
└──────────────────┘                      └─────────────────────┘
        │                                          │
        │  usa credenciais temporárias             │
        ▼                                          ▼
   ┌─────────┐                              ┌─────────────┐
   │   EC2   │                              │     S3      │
   └─────────┘                              └─────────────┘
```

- **Role ARN**: `arn:aws:iam::794038217446:role/role-time-dev`
- **Profile AWS CLI**: `awscli`
- **Região**: `us-east-1`
- **Session Name**: `vm-livia`

O usuário IAM possui apenas a permissão de `sts:AssumeRole` na trust policy da role, sem nenhuma policy diretamente atachada ao seu usuário. Isso segue o princípio de menor privilégio.

---

## 3. Scripts Criados

### 3.1 Configuração e Credenciais

| Script | Descrição |
|--------|-----------|
| `configure-aws.sh` | Configura/lista perfis AWS CLI |
| `aws-profile.sh` | Testa identidade e lista buckets com um profile |
| `set-aws-temp-creds.sh` | Assume role via STS e exporta credenciais temporárias para a sessão |
| `client/bia/scripts/generate-sts-token.sh` | Gerador avançado de token STS com opções de duração e export |

### 3.2 Gerenciamento de EC2

| Script | Descrição |
|--------|-----------|
| `script-ec2.sh` | **Lança instâncias EC2** — assume role, pede nome da instância e cria 2x `t2.micro` com tag `grupo=AutomacaoAWSCLI` |
| `start-ec2.sh` | **Inicia instância** — lista instâncias do grupo, permite escolher e iniciar |
| `stop-ec2.sh` | **Para instância** — lista instâncias do grupo, permite escolher e parar |
| `terminate-ec2.sh` | **Termina instância** — lista instâncias do grupo, permite escolher e terminar |
| `describe-ec2-instances.sh` | **Lista instâncias** — assume role e exibe ID + Nome das instâncias do grupo |
| `2script-ec2.sh` | Versão alternativa de listagem de instâncias |
| `start-ssm-ec2.sh` | **Conecta via SSM** Session Manager a uma instância EC2 |

### 3.3 Operações S3

| Script | Descrição |
|--------|-----------|
| `script-new-s3.sh` | **Cria bucket S3** — valida profile, cria bucket, configura ACL/ownership |
| `scripts-s3.sh` | **Menu interativo S3** com 9 operações: ls, cp (upload/download), sync (local→S3, S3→local), storage class, dry-run, presigned URL |

### 3.4 Docker / Container

| Script | Descrição |
|--------|-----------|
| `Dockerfile` | Imagem baseada em `amazon/aws-cli:latest` |
| `run_docker.sh` | Executa container com credenciais via `.env.aws` e volume montado |
| `.env.aws` | Template de variáveis de ambiente para credenciais temporárias |

---

## 4. Fluxo de Operação

### 4.1 Lançar uma EC2

```bash
# 1. Executar o script de lançamento
./script-ec2.sh

# O script internamente:
# - Assume a role-time-dev via STS
# - Pede o nome da instância
# - Lança 2x t2.micro com AMI ami-02dfbd4ff395f2a1b
# - Aplica tags: Name=<nome>, grupo=AutomacaoAWSCLI
```

Parâmetros da instância:
- **AMI**: `ami-02dfbd4ff395f2a1b`
- **Tipo**: `t2.micro`
- **Key Pair**: `formacao`
- **Security Group**: `sg-0349b0097235500ee`
- **Subnet**: `subnet-004fc006f214f0ad1`
- **Tags**: `Name=<input>`, `grupo=AutomacaoAWSCLI`

### 4.2 Sincronizar Arquivos com S3

```bash
# 1. Criar bucket (se necessário)
./script-new-s3.sh

# 2. Usar o menu interativo para sync
./scripts-s3.sh
# Opção 5: SYNC pasta local → S3
# Opção 6: SYNC S3 → pasta local
# Opção 8: DRY-RUN (simular sem executar)
```

O diretório `desafio01/sync/` foi criado como pasta de sincronização com o S3.

### 4.3 Obter Credenciais Temporárias

```bash
# Opção 1: Exportar na sessão atual
source ./set-aws-temp-creds.sh

# Opção 2: Gerador avançado com duração customizada
./client/bia/scripts/generate-sts-token.sh awscli 7200 --export
```

---

## 5. Estrutura de Diretórios

```
desafio01/
├── script-ec2.sh              # Lançar EC2
├── start-ec2.sh               # Iniciar EC2
├── stop-ec2.sh                # Parar EC2
├── terminate-ec2.sh           # Terminar EC2
├── describe-ec2-instances.sh  # Listar EC2
├── 2script-ec2.sh             # Listar EC2 (alternativo)
├── start-ssm-ec2.sh           # Conectar via SSM
├── scripts-s3.sh              # Menu interativo S3
├── script-new-s3.sh           # Criar bucket S3
├── set-aws-temp-creds.sh      # Exportar credenciais STS
├── configure-aws.sh           # Configurar perfis AWS CLI
├── aws-profile.sh             # Testar profile
├── aws-configure.sh           # Validar credenciais e listar buckets
├── Dockerfile                 # Container AWS CLI
├── run_docker.sh              # Executar container
├── .env.aws                   # Template de credenciais
├── arquivo.txt                # Arquivo de teste
└── desafio01/sync/            # Diretório de sincronização com S3
```

---

## 6. Conceitos Aplicados

| Conceito | Aplicação |
|----------|-----------|
| **Princípio do menor privilégio** | Usuário IAM sem policies; acesso somente via AssumeRole |
| **Credenciais temporárias (STS)** | Todos os scripts usam `aws sts assume-role` antes de operar |
| **Automação via Shell Script** | Scripts interativos para todas as operações EC2 e S3 |
| **Tags para organização** | Instâncias tagueadas com `grupo=AutomacaoAWSCLI` para filtragem |
| **Containerização** | Dockerfile + script para rodar AWS CLI em container isolado |
| **Sync incremental** | `aws s3 sync` envia apenas arquivos novos/modificados |
| **Dry-run** | Simulação de sync antes da execução real |
| **Presigned URLs** | Geração de URLs temporárias para acesso a objetos S3 |
| **SSM Session Manager** | Acesso à EC2 sem necessidade de SSH/porta 22 aberta |
| **Agente de IA** | Kiro CLI utilizado para auxiliar na criação dos scripts e automações |

---

## 7. Resumo

O desafio foi concluído com sucesso. Foram criados **14 scripts** que cobrem todo o ciclo de vida:

1. **Configuração** — perfis AWS CLI e validação de credenciais
2. **Autenticação** — AssumeRole com tokens temporários STS (sem policies no usuário)
3. **EC2** — lançar, iniciar, parar, terminar, listar e conectar via SSM
4. **S3** — criar bucket, upload, download, sync bidirecional, storage classes, dry-run e presigned URLs
5. **Container** — execução isolada via Docker com credenciais injetadas

Toda a infraestrutura é operada exclusivamente via `role-time-dev` com credenciais temporárias, garantindo que o usuário IAM permanece sem nenhuma policy atachada diretamente.
