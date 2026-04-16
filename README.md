# AWS CLI Automation Scripts

Este repositório contém scripts para automatizar tarefas de **cloud computing** na AWS usando a **AWS CLI**.

## Objetivo

A ideia principal é criar um conjunto de scripts que:

- Automatizam a criação e listagem de instâncias EC2.
- Gerenciam buckets e objetos no S3 (upload, download, sync, storage classes, presigned URLs).
- Usam **perfis de AWS CLI** e assumem roles temporárias (via STS) para evitar o uso de credenciais permanentes.
- Executam comandos AWS dentro de containers Docker.
- Mantêm o mesmo fluxo de trabalho em múltiplos terminais, sem precisar reconfigurar credenciais a cada novo shell.

## Estrutura de scripts

### EC2

| Script | Descrição |
|--------|-----------|
| `desafio01/script-ec2.sh` | Cria instâncias EC2 com tags e parâmetros definidos |
| `desafio01/describe-ec2-instances.sh` | Lista instâncias EC2 com tag `grupo=AutomacaoAWSCLI` |
| `desafio01/stop-ec2.sh` | Para uma instância EC2 (interativo) |
| `desafio01/start-ec2.sh` | Inicia uma instância EC2 (interativo) |
| `desafio01/start-ssm-ec2.sh` | Inicia sessão SSM em uma instância EC2 |
| `desafio01/terminate-ec2.sh` | Termina uma instância EC2 (interativo) |

### S3

| Script | Descrição |
|--------|-----------|
| `desafio01/scripts-s3.sh` | Menu interativo com operações S3 (ver opções abaixo) |

Opções do menu S3:

1. **Listar buckets** — `aws s3 ls`
2. **Listar conteúdo de um bucket** — com `--human-readable`
3. **CP upload** — Copiar arquivo local para S3
4. **CP download** — Baixar arquivo do S3 para local
5. **SYNC local → S3** — Sincroniza pasta local com bucket (só envia o que mudou)
6. **SYNC S3 → local** — Sincroniza bucket com pasta local
7. **Storage Class** — Upload com classe de armazenamento (Standard_IA, Glacier, Deep Archive, Intelligent Tiering)
8. **DRY-RUN** — Simula sync sem transferir nenhum arquivo
9. **Presign** — Gera URL pré-assinada temporária para um objeto

### Configuração e Credenciais

| Script | Descrição |
|--------|-----------|
| `desafio01/configure-aws.sh` | Mostra perfis AWS CLI e permite configurar/editar via `aws configure` |
| `desafio01/set-aws-temp-creds.sh` | Gera credenciais temporárias (STS) e exporta como variáveis de ambiente |

### Docker

| Script | Descrição |
|--------|-----------|
| `desafio01/Dockerfile` | Imagem Docker com AWS CLI (baseada em `amazon/aws-cli`) |
| `desafio01/run_docker.sh` | Executa container Docker com credenciais AWS via `.env.aws` |

## Como usar

1. Configure seu perfil base (ex: `awscli`) via `aws configure`.
2. Execute o script de credenciais temporárias diretamente no shell atual:

```bash
source ./desafio01/set-aws-temp-creds.sh
```

3. Execute o script que você precisar:

```bash
./desafio01/configure-aws.sh          # Configura/edita perfis AWS CLI
./desafio01/set-aws-temp-creds.sh     # Gera credenciais temporárias (STS)
./desafio01/script-ec2.sh             # Criar instâncias
./desafio01/describe-ec2-instances.sh  # Listar instâncias
./desafio01/stop-ec2.sh               # Parar instância (interativo)
./desafio01/start-ec2.sh              # Iniciar instância (interativo)
./desafio01/terminate-ec2.sh          # Terminar instância (interativo)
./desafio01/scripts-s3.sh             # Menu interativo S3
```

### Usando com Docker

1. Preencha o arquivo `desafio01/.env.aws` com suas credenciais:

```
AWS_ACCESS_KEY_ID=<sua_access_key>
AWS_SECRET_ACCESS_KEY=<sua_secret_key>
AWS_SESSION_TOKEN=<seu_session_token>
AWS_DEFAULT_REGION=us-east-1
```

2. Build e execução:

```bash
docker build -t automacao-awscli ./desafio01/
./desafio01/run_docker.sh
```

## Nota

- As credenciais retornadas pelo STS expiram (normalmente em 1 hora). Sempre que precisar de uma nova sessão, rode novamente o script `set-aws-temp-creds.sh`.
- O arquivo `.env.aws` está no `.gitignore` para não subir credenciais ao repositório.
