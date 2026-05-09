# 🚀 Meetup Setup — AWS Women User Group Goiânia

Automação completa para o deploy da landing page do **AWS Women User Group Goiânia** na AWS, usando S3 + CloudFront.

## Por que S3 + CloudFront?

O site é uma landing page estática (HTML/CSS/JS puro gerado pelo Next.js). Não precisa de servidor rodando — só precisa servir arquivos. Por isso:

- **S3** — Armazena os arquivos estáticos e serve como website. É o jeito mais barato e simples de hospedar um site estático na AWS (custa centavos por mês).
- **CloudFront** — CDN que distribui o site em servidores ao redor do mundo, garantindo carregamento rápido para qualquer visitante. Também fornece **HTTPS gratuito** (certificado SSL automático), que o S3 sozinho não oferece.

Resumo: S3 guarda os arquivos, CloudFront entrega com velocidade e segurança.

## Arquitetura

```
Next.js (build estático) → S3 (hospedagem) → CloudFront (CDN + HTTPS)
```

O projeto usa **credenciais temporárias** via `sts:AssumeRole` para segurança:

```
Profile "awscli" (IAM User) → assume-role → role-time-dev (permissões reais)
```

## Onde está o código da landing page?

O código-fonte da landing page fica no repositório [github.com/LiviaMor/awswomengoiania](https://github.com/LiviaMor/awswomengoiania.git). O script de deploy clona esse repositório automaticamente durante a execução — você não precisa clonar manualmente.

## Pré-requisitos

- AWS CLI v2
- Node.js 18+
- Git
- Profile AWS `awscli` configurado
- Role `role-time-dev` autorizando seu IAM user

## Scripts

| Script | Descrição |
|--------|-----------|
| `install-setup.sh` | Instala AWS CLI, Node.js 20, Kiro CLI e configura credenciais |
| `deploy-landingpage-awswomengoiania.sh` | Deploy completo da landing page |
| `teardown-landingpage-awswomengoiania.sh` | Remove todos os recursos criados |
| `demo-kiro-na-real.sh` | Demo do Kiro CLI em ação |

## Como usar

### 1. Setup inicial (primeira vez)

```bash
bash install-setup.sh
```

Instala e configura todas as ferramentas necessárias.

### 2. Deploy da landing page

```bash
bash deploy-landingpage-awswomengoiania.sh
```

O script executa automaticamente:

1. Valida pré-requisitos (AWS CLI, Node.js, Git)
2. Assume a role `role-time-dev` (credenciais temporárias de 1h)
3. Clona o repositório [awswomengoiania](https://github.com/LiviaMor/awswomengoiania.git)
4. Configura Next.js para export estático
5. Instala dependências e faz build
6. Cria o bucket S3 (verifica se já existe antes)
7. Configura hospedagem estática e acesso público
8. Faz upload dos arquivos
9. Cria distribuição CloudFront (verifica se já existe antes)
10. Exibe as URLs de acesso

### 3. Teardown (destruir tudo)

```bash
bash teardown-landingpage-awswomengoiania.sh
```

Remove bucket S3, distribuição CloudFront e clone local.

## URLs geradas

- **S3 (HTTP):** `http://awswomengoiania-landingpage.s3-website-us-east-1.amazonaws.com`
- **CloudFront (HTTPS):** exibida ao final do deploy

## Configurações

| Parâmetro | Valor |
|-----------|-------|
| Conta AWS | `794038217446` |
| Região | `us-east-1` |
| Profile | `awscli` |
| Role | `role-time-dev` |
| Bucket | `awswomengoiania-landingpage` |

## Segurança

### Por que não tem Security Groups (inbound/outbound)?

Security Groups controlam tráfego de rede para recursos dentro de uma VPC (como EC2, RDS). Este projeto **não usa VPC** — S3 e CloudFront são serviços gerenciados que ficam fora de rede privada. Por isso não existem regras de inbound/outbound aqui.

### Como a segurança é feita neste projeto

| Camada | Mecanismo | O que protege |
|--------|-----------|---------------|
| Acesso ao deploy | IAM Role + credenciais temporárias (1h) | Só quem pode assumir a role consegue fazer deploy |
| Acesso aos arquivos | S3 Bucket Policy | Permite apenas leitura pública (GET), ninguém externo pode modificar |
| Transporte | CloudFront + HTTPS | Certificado SSL automático, dados criptografados em trânsito |
| DDoS | AWS Shield Standard (incluso no CloudFront) | Proteção básica contra ataques de negação de serviço |
| Auditoria | CloudTrail | Registra quem assumiu a role e quando |

### Resumo do modelo de credenciais

- IAM User (`awscli`) só tem permissão para `sts:AssumeRole` — não faz nada diretamente
- Credenciais temporárias expiram em 1 hora
- Se as access keys vazarem, não há permissão direta para nenhum serviço
