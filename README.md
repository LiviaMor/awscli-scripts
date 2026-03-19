# AWS CLI Automation Scripts

Este repositório contém scripts para automatizar tarefas de **cloud computing** na AWS usando a **AWS CLI**.

## Objetivo

A ideia principal é criar um conjunto de scripts que:

- Automatizam a criação e listagem de instâncias EC2.
- Usam **perfis de AWS CLI** e assumem roles temporárias (via STS) para evitar o uso de credenciais permanentes.
- Mantêm o mesmo fluxo de trabalho em múltiplos terminais, sem precisar reconfigurar credenciais a cada novo shell.

## Estrutura de scripts

### `desafio01/script-ec2.sh`
Roda `aws ec2 run-instances` para iniciar instâncias EC2 com tags e parâmetros definidos no script.

### `desafio01/describe-ec2-instances.sh`
Lista instâncias EC2 que usam a tag `grupo=AutomacaoAWSCLI`, assumindo uma role temporária para garantir que as credenciais estejam sempre válidas.

### `desafio01/stop-ec2.sh`
Lista as instâncias EC2 disponíveis e permite ao usuário escolher uma instância para parar, perguntando o ID da instância.

### `desafio01/configure-aws.sh`
Mostra os perfis AWS CLI existentes na máquina e permite configurar/editar um perfil usando `aws configure`.

### `desafio01/set-aws-temp-creds.sh`
Gera e exporta variáveis de ambiente (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) ao assumir uma role via STS.

## Como usar

1. Configure seu perfil base (ex: `awscli`) via `aws configure`.
2. Execute o script de credenciais temporárias diretamente no shell atual:

```bash
source ./desafio01/set-aws-temp-creds.sh
```

ou (modo compatível com qualquer shell):

```bash
eval "$(./desafio01/set-aws-temp-creds.sh)"
```

3. Execute o script que você precisar:

```bash
./desafio01/configure-aws.sh   # Configura/edita perfis AWS CLI (usa aws configure)
./desafio01/set-aws-temp-creds.sh  # Gera/execulta credenciais temporárias (STS)
./desafio01/script-ec2.sh              # Criar instâncias
./desafio01/describe-ec2-instances.sh   # Listar instâncias
./desafio01/stop-ec2.sh                # Parar instância (interativo)
```

## Nota

As credenciais retornadas pelo STS expiram (normalmente em 1 hora). Sempre que precisar de uma nova sessão, apenas rode novamente o script `set-aws-temp-creds.sh`.
