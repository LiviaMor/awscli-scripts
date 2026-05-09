# 🚀 Passo a Passo: Deploy da Landing Page AWS Women Goiânia

## Visão Geral

Este guia explica como colocar no ar a landing page do **AWS Women User Group Goiânia** usando:

- **Next.js 16** — framework React que gera o site (precisa de build)
- **S3** — para hospedar os arquivos estáticos gerados pelo build
- **CloudFront** — para servir com HTTPS e CDN global (carrega rápido no mundo todo)
- **Git** — para baixar o código do repositório

**Repositório:** https://github.com/LiviaMor/awswomengoiania.git  
**Projeto:** `aws-women-landing/` (Next.js 16 + React 19 + Tailwind CSS)  
**Profile AWS:** `awscli`  
**Região:** `us-east-1`  
**Conta:** `794038217446`

### ⚠️ Importante: Não é um site estático simples!

O repositório contém um projeto **Next.js** (framework React). Isso significa que:
1. Precisa de **Node.js 18+** instalado
2. Precisa rodar `npm install` (baixar dependências)
3. Precisa rodar `npm run build` (gerar os arquivos HTML/CSS/JS)
4. Precisa configurar `output: 'export'` no `next.config.ts` (gerar site estático)

O script automatizado cuida de tudo isso pra você.

---

## Pré-requisitos

Antes de começar, você precisa ter:

| Ferramenta | Como verificar | Como instalar |
|-----------|---------------|---------------|
| AWS CLI v2 | `aws --version` | `bash install-setup.sh` |
| Git | `git --version` | `sudo apt install git` |
| Node.js 18+ | `node --version` | `curl -fsSL https://deb.nodesource.com/setup_20.x \| sudo -E bash - && sudo apt install -y nodejs` |
| npm | `npm --version` | Vem junto com o Node.js |
| Profile `awscli` configurado | `aws sts get-caller-identity --profile awscli` | `aws configure --profile awscli` |

---

## Opção 1: Script Automatizado (Recomendado)

Se quiser fazer tudo de uma vez:

```bash
bash deploy-landingpage-awswomengoiania.sh
```

O script faz tudo automaticamente e mostra as URLs no final.

---

## Opção 2: Passo a Passo Manual

Se preferir entender cada etapa e executar manualmente:

---

### Passo 1: Validar suas credenciais

```bash
aws sts get-caller-identity --profile awscli
```

**Saída esperada:**
```json
{
    "UserId": "AIDA...",
    "Account": "794038217446",
    "Arn": "arn:aws:iam::794038217446:user/seu-usuario"
}
```

Se der erro, configure o profile:
```bash
aws configure --profile awscli
```

Ou use credenciais temporárias:
```bash
source ../desafio01/set-aws-temp-creds.sh
```

---

### Passo 2: Clonar o repositório

```bash
git clone https://github.com/LiviaMor/awswomengoiania.git /tmp/awswomengoiania
```

O projeto Next.js está na subpasta `aws-women-landing/`:
```bash
ls /tmp/awswomengoiania/aws-women-landing/package.json
```

---

### Passo 3: Configurar Next.js para export estático

O Next.js por padrão gera um app que precisa de servidor Node.js rodando. Para hospedar no S3 (que só serve arquivos estáticos), precisamos configurar o **Static Export**.

Edite o arquivo `next.config.ts`:

```bash
cat > /tmp/awswomengoiania/aws-women-landing/next.config.ts << 'EOF'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
EOF
```

**O que cada opção faz:**
- `output: 'export'` → gera HTML/CSS/JS puros na pasta `out/` (sem precisar de servidor)
- `images.unoptimized: true` → desabilita otimização de imagens server-side (necessário para export)

---

### Passo 4: Instalar dependências e fazer build

```bash
cd /tmp/awswomengoiania/aws-women-landing

# Instalar dependências (React, Next.js, Tailwind, etc.)
npm install

# Gerar o site estático
npm run build
```

Após o build, os arquivos prontos estarão em:
```
/tmp/awswomengoiania/aws-women-landing/out/
```

Verifique:
```bash
ls /tmp/awswomengoiania/aws-women-landing/out/index.html
```

---

### Passo 5: Criar o bucket S3

```bash
aws s3api create-bucket \
    --bucket awswomengoiania-landingpage \
    --region us-east-1 \
    --profile awscli
```

**Por que `us-east-1` não precisa de `LocationConstraint`?**  
É a região padrão da AWS. Qualquer outra região exigiria o parâmetro extra `--create-bucket-configuration LocationConstraint=REGIAO`.

---

### Passo 6: Desabilitar o bloqueio de acesso público

Por padrão, a AWS bloqueia todo acesso público a buckets (segurança). Como queremos um site público, precisamos desabilitar:

```bash
aws s3api put-public-access-block \
    --bucket awswomengoiania-landingpage \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
    --profile awscli
```

---

### Passo 7: Habilitar hospedagem de site estático

```bash
aws s3api put-bucket-website \
    --bucket awswomengoiania-landingpage \
    --website-configuration '{
        "IndexDocument": {"Suffix": "index.html"},
        "ErrorDocument": {"Key": "404.html"}
    }' \
    --profile awscli
```

Isso diz pro S3: "quando alguém acessar a URL do bucket, sirva o `index.html`". O Next.js gera um `404.html` automaticamente no build.

---

### Passo 8: Aplicar política de acesso público (bucket policy)

Crie um arquivo `policy.json`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::awswomengoiania-landingpage/*"
        }
    ]
}
```

Aplique:

```bash
aws s3api put-bucket-policy \
    --bucket awswomengoiania-landingpage \
    --policy file://policy.json \
    --profile awscli
```

**O que isso faz?** Permite que qualquer pessoa (`"Principal": "*"`) leia (`s3:GetObject`) os arquivos do bucket. É o que torna o site público.

---

### Passo 9: Fazer upload dos arquivos buildados

```bash
aws s3 sync /tmp/awswomengoiania/aws-women-landing/out s3://awswomengoiania-landingpage \
    --delete \
    --profile awscli
```

**Importante:** Estamos enviando a pasta `out/` (resultado do build), não o código-fonte!

**Parâmetros explicados:**
- `sync` — só envia arquivos novos ou modificados (eficiente)
- `--delete` — remove do S3 arquivos que não existem mais no local

---

### Passo 10: Testar o site via S3

Acesse no navegador:

```
http://awswomengoiania-landingpage.s3-website-us-east-1.amazonaws.com
```

Se o site carregar, está funcionando! 🎉

---

### Passo 11: Criar distribuição CloudFront (HTTPS + CDN)

O S3 Website só serve HTTP. Para ter HTTPS (cadeado verde) e performance global, usamos o CloudFront.

Crie um arquivo `cf-config.json`:

```json
{
    "CallerReference": "awswomengoiania-deploy-001",
    "Comment": "AWS Women User Group Goiania - Landing Page",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-awswomengoiania-landingpage",
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
                "Id": "S3-awswomengoiania-landingpage",
                "DomainName": "awswomengoiania-landingpage.s3-website-us-east-1.amazonaws.com",
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
    "PriceClass": "PriceClass_100",
    "HttpVersion": "http2"
}
```

Execute:

```bash
aws cloudfront create-distribution \
    --distribution-config file://cf-config.json \
    --profile awscli
```

**Parâmetros importantes:**
- `ViewerProtocolPolicy: redirect-to-https` — força HTTPS
- `Compress: true` — comprime arquivos (site carrega mais rápido)
- `PriceClass_100` — usa apenas edge locations na América do Norte e Europa (mais barato)
- `DefaultRootObject: index.html` — quando acessar a raiz, serve o index

Anote o `Distribution ID` e o `DomainName` (algo como `d1234abcdef.cloudfront.net`) da saída.

---

### Passo 12: Aguardar propagação e testar

```bash
# Verificar status (precisa estar "Deployed")
aws cloudfront get-distribution \
    --id SEU_DISTRIBUTION_ID \
    --profile awscli \
    --query "Distribution.Status"
```

Quando o status for `"Deployed"`, acesse:

```
https://d1234abcdef.cloudfront.net
```

(substitua pelo seu domínio CloudFront real)

---

## Atualizando o site depois

Quando houver mudanças no repositório:

```bash
# 1. Baixar as mudanças
git -C /tmp/awswomengoiania pull

# 2. Rebuild do Next.js
cd /tmp/awswomengoiania/aws-women-landing && npm run build && cd -

# 3. Sincronizar build com o S3
aws s3 sync /tmp/awswomengoiania/aws-women-landing/out s3://awswomengoiania-landingpage \
    --delete \
    --profile awscli

# 4. Invalidar cache do CloudFront (forçar atualização)
aws cloudfront create-invalidation \
    --distribution-id SEU_DISTRIBUTION_ID \
    --paths "/*" \
    --profile awscli
```

A invalidação leva ~1-2 minutos para propagar.

---

## Destruindo tudo (cleanup)

Se quiser remover todos os recursos:

```bash
# 1. Esvaziar o bucket
aws s3 rm s3://awswomengoiania-landingpage --recursive --profile awscli

# 2. Deletar o bucket
aws s3api delete-bucket --bucket awswomengoiania-landingpage --profile awscli

# 3. Desabilitar a distribuição CloudFront (obrigatório antes de deletar)
# Primeiro, obtenha o ETag:
ETAG=$(aws cloudfront get-distribution-config \
    --id SEU_DISTRIBUTION_ID \
    --profile awscli \
    --query "ETag" --output text)

# Depois desabilite e delete:
# (Nota: precisa baixar o config, mudar Enabled para false, e fazer update)
aws cloudfront get-distribution-config \
    --id SEU_DISTRIBUTION_ID \
    --profile awscli > /tmp/cf-config-disable.json

# Edite o arquivo removendo o campo ETag do topo e mudando "Enabled": true para false
# Depois:
aws cloudfront update-distribution \
    --id SEU_DISTRIBUTION_ID \
    --if-match $ETAG \
    --distribution-config file:///tmp/cf-config-disable.json \
    --profile awscli

# Aguarde ficar "Deployed" novamente, depois delete:
aws cloudfront delete-distribution \
    --id SEU_DISTRIBUTION_ID \
    --if-match NOVO_ETAG \
    --profile awscli

# 4. Limpar clone local
rm -rf /tmp/awswomengoiania
```

---

## Diagrama da Arquitetura

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Usuário    │────▶│   CloudFront     │────▶│   S3 Bucket     │
│  (Browser)   │     │   (CDN + HTTPS)  │     │  (Site Estático)│
└──────────────┘     └──────────────────┘     └─────────────────┘
                                                       ▲
                                                       │
┌──────────────┐     ┌──────────────────┐     ┌───────┴─────────┐
│   GitHub     │────▶│   npm run build  │────▶│   Pasta out/    │
│  (Código)    │     │   (Next.js)      │     │  (HTML/CSS/JS)  │
└──────────────┘     └──────────────────┘     └─────────────────┘
```

**Fluxo de deploy:**
1. Código-fonte vive no GitHub (Next.js + React + Tailwind)
2. `npm run build` gera HTML/CSS/JS estáticos na pasta `out/`
3. `aws s3 sync` envia os arquivos para o bucket S3
4. CloudFront serve com HTTPS e cache global

**Fluxo de acesso do usuário:**
1. Usuário acessa `https://d1234.cloudfront.net`
2. CloudFront verifica se tem cache na edge location mais próxima
3. Se não tem cache, busca no S3
4. Retorna o site com HTTPS e compressão

---

## Custos Estimados

| Recurso | Custo (Free Tier) | Custo (após Free Tier) |
|---------|-------------------|------------------------|
| S3 (5GB) | Grátis (12 meses) | ~$0.12/mês |
| CloudFront (1TB transfer) | Grátis (12 meses) | ~$0.085/GB |
| Total estimado (site pequeno) | **$0.00** | **< $1.00/mês** |

Para uma landing page simples, o custo é praticamente zero dentro do Free Tier.

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `npm run build` falha | Verifique se Node.js é 18+. Tente `rm -rf node_modules && npm install` |
| Build falha com erro de imagem | Confirme que `images.unoptimized: true` está no `next.config.ts` |
| "Access Denied" ao acessar o site | Verifique se a bucket policy foi aplicada (Passo 8) |
| "403 Forbidden" no CloudFront | Aguarde 5-15 min para propagação |
| Site não atualiza após mudanças | Faça rebuild + invalidação do CloudFront (seção "Atualizando") |
| "NoSuchBucket" | Verifique o nome do bucket e a região |
| Credenciais expiradas | Execute `source ../desafio01/set-aws-temp-creds.sh` |
| CSS/JS não carrega (site sem estilo) | Verifique Content-Type dos arquivos no S3 |

---

*AWS Women User Group Goiânia — Zero to Hero 🚀*
