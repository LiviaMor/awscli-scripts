# Além do Dashboard: 5 Realidades do AWS RDS que Ninguém te Conta

## Pra quem é esse artigo?

Se você está começando na AWS e já ouviu falar do RDS (Relational Database Service), esse artigo é pra você. Vou te mostrar 5 coisas que pegam muita gente de surpresa — inclusive profissionais experientes — quando trabalham com banco de dados na nuvem da Amazon.

Não vou usar "tecniquês" sem explicar. Cada conceito novo vai ter uma explicação simples antes de entrar no detalhe.

---

## Antes de tudo: o que é esse tal de "Multi-Conta"?

Imagina que você tem uma casa. No começo, tudo fica num quarto só: suas roupas, seus documentos, suas ferramentas. Funciona quando é pouco. Mas conforme cresce, você precisa de cômodos separados: um quarto pra dormir, um escritório pra trabalhar, uma garagem pra ferramentas.

Na AWS é igual. As empresas começam com **uma conta só** (o "sandbox"), mas conforme crescem, separam em contas diferentes:

- **Conta de Desenvolvimento** — onde os devs testam código novo
- **Conta de Homologação** — onde se valida antes de ir pro ar
- **Conta de Produção** — onde os clientes reais acessam

Isso é ótimo pra segurança (se alguém fizer besteira no dev, não derruba a produção), mas cria um problema: **como mover dados de banco entre essas contas?**

É aí que as 5 realidades abaixo entram.

---

## 1. A Armadilha da Chave de Criptografia Padrão

### O que é criptografia no RDS?

Quando você cria um banco no RDS, a AWS oferece criptografar seus dados "em repouso" (ou seja, os dados gravados no disco ficam embaralhados). Pra fazer isso, ela usa uma **chave de criptografia** gerenciada pelo serviço KMS (Key Management Service).

### Onde tá a armadilha?

Por padrão, a AWS usa uma chave chamada `aws/rds`. Ela é gratuita e fácil — você não precisa configurar nada. Parece perfeito, né?

O problema: **snapshots criptografados com essa chave padrão não podem ser compartilhados com outras contas AWS.**

Pensa assim: é como se você trancasse um documento num cofre, mas a chave desse cofre só funciona dentro da sua casa. Se você quiser mandar o documento pro vizinho, o cofre não abre lá.

### Como resolver?

Você precisa usar uma **Customer Managed Key (CMK)** — uma chave que *você* cria e controla. Com ela, você pode dar permissão pra outras contas usarem a mesma chave.

Se você já criou bancos com a chave padrão, o caminho é:

1. Tirar um snapshot do banco
2. **Copiar** esse snapshot escolhendo sua CMK como chave de criptografia
3. Compartilhar o snapshot copiado com a outra conta

**Dica de ouro:** sempre crie seus bancos RDS com uma CMK desde o início. Isso evita essa dor de cabeça lá na frente.

> Fonte: [Options for changing AWS KMS encryption key for Amazon RDS databases](https://aws.amazon.com/blogs/database/options-for-changing-aws-kms-encryption-key-for-amazon-rds-databases/) — Abril 2026

---

## 2. SQL Server: Agora Vai Até 256 TB (Sem Gambiarras)

### O problema antigo

O RDS for SQL Server tinha um limite de **64 TiB** (tebibytes, aproximadamente 64 terabytes) de armazenamento. Pra maioria das empresas isso é suficiente, mas pra grandes operações (bancos, e-commerces gigantes, sistemas legados), esse limite forçava uma técnica chamada **sharding**.

**Sharding** = dividir um banco de dados enorme em vários bancos menores. Funciona, mas é extremamente complexo de implementar e manter. Imagina ter que dividir uma biblioteca em 4 prédios diferentes e lembrar em qual prédio está cada livro.

### O que mudou (Dezembro 2025)

A AWS lançou o recurso de **Additional Storage Volumes** (Volumes de Armazenamento Adicionais). Agora você pode:

- Adicionar até **3 volumes extras** ao seu banco
- Cada volume suporta até 64 TiB
- Total: **256 TiB** por instância

### Por que isso importa pra quem tá começando?

Mesmo que você não precise de 256 TB hoje, esse recurso traz benefícios práticos:

- **Volume dedicado pra logs** — Separa os logs de transação dos dados. É como ter um caderno separado só pra anotações, sem misturar com os documentos importantes. Isso melhora a performance de escrita.
- **Mix de tipos de armazenamento** — Você pode usar disco rápido (io2) pros dados críticos e disco mais barato (gp3) pros logs. Economia inteligente.

Desde maio de 2026, esse recurso também suporta read replicas e compartilhamento de snapshots entre contas.

> Fonte: [Improving storage with additional storage volumes in Amazon RDS for SQL Server](https://aws.amazon.com/blogs/database/improving-storage-with-additional-storage-volumes-in-amazon-rds-for-sql-server/) — Abril 2026

---

## 3. Nem Todo Snapshot é Igual (Automático vs Manual)

### O que é um snapshot?

Um snapshot é uma "foto" do seu banco de dados num momento específico. Se algo der errado, você pode restaurar o banco a partir dessa foto.

O RDS faz dois tipos:

| Tipo | Quem cria | Pode compartilhar entre contas? |
|------|-----------|-------------------------------|
| **Automático** | O próprio RDS, todo dia | ❌ Não |
| **Manual** | Você, quando quiser | ✅ Sim (até 20 contas) |

### Por que o automático não pode ser compartilhado?

É uma decisão de segurança da AWS. Imagina se uma automação mal configurada começasse a compartilhar backups diários com contas erradas sem ninguém perceber. A AWS força você a ser **intencional**: só snapshots que você criou de propósito podem ser compartilhados.

### Como mover dados entre contas então?

1. Copie o snapshot automático para um **snapshot manual**
2. Compartilhe o snapshot manual com a conta de destino (até 20 contas)
3. Na conta de destino, vá em **"Shared with Me"** (Compartilhado comigo) — o snapshot não aparece na lista normal!
4. Use o **ARN** (o "endereço completo" do recurso na AWS) do snapshot pra restaurar

**Erro comum de iniciante:** ficar procurando o snapshot compartilhado na lista padrão e achar que não funcionou. Ele fica numa aba separada.

> Fonte: [Sharing a DB snapshot for Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ShareSnapshot.html)

---

## 4. Blue/Green Deployment: Atualize Sem Medo

### O problema clássico

Você precisa atualizar a versão do banco de dados (ex: MySQL 8.0 pra 8.4). No mundo antigo, isso significava:

- Agendar uma janela de manutenção (geralmente madrugada de domingo)
- Avisar todo mundo que o sistema vai ficar fora
- Torcer pra dar certo
- Se der errado... pânico

### O que é Blue/Green Deployment?

Pensa em dois palcos de teatro:

- **Blue (azul)** = seu banco de produção atual, funcionando normalmente
- **Green (verde)** = uma cópia exata do seu banco, onde você aplica a atualização

Enquanto o palco verde está sendo preparado, o azul continua funcionando normalmente. Quando tudo estiver testado e validado no verde, a AWS faz o **switchover** — troca os palcos. O verde vira a nova produção.

### O que há de novo (2026)?

- **Janeiro 2026:** O tempo de switchover caiu pra **menos de 5 segundos**. Antes podia levar minutos.
- **Abril 2026:** Suporte ao **RDS Proxy**, que elimina atrasos de DNS. Na prática, sua aplicação nem percebe a troca.

### Pra quais bancos funciona?

- RDS for MySQL
- RDS for PostgreSQL
- RDS for MariaDB
- Aurora MySQL
- Aurora PostgreSQL

### Por que isso importa pra iniciantes?

Mesmo que você esteja só aprendendo, já comece com essa mentalidade: **atualizações não precisam ser eventos traumáticos**. Blue/Green é o padrão moderno.

> Fontes: [RDS Blue/Green reduces downtime to under 5 seconds](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-rds-blue-green-deployments-reduces-downtime/) | [RDS Blue/Green now supports RDS Proxy](https://aws.amazon.com/about-aws/whats-new/2026/04/rds-blue-green-proxy/)

---

## 5. AWS CLI v1 Vai Morrer — Migre Agora

### O que é a AWS CLI?

É a ferramenta de linha de comando da AWS. Em vez de clicar no console (interface web), você digita comandos no terminal. Exemplo:

```bash
aws rds describe-db-instances
```

Isso lista todos os seus bancos RDS. Profissionais usam a CLI pra automatizar tarefas em scripts e pipelines de CI/CD.

### O problema

Existem duas versões da CLI:

| | CLI v1 | CLI v2 |
|--|--------|--------|
| Status | ⚠️ Vai ser descontinuada | ✅ Versão atual |
| Instalação | Via pip (Python) | Instalador nativo |
| Recursos novos | Não recebe mais | Recebe tudo |

### Datas oficiais (preste atenção!)

- **15 de julho de 2026** — CLI v1 entra em **modo de manutenção**. Só recebe correções críticas de segurança.
- **15 de julho de 2027** — **Fim do suporte total**. Pode parar de funcionar com serviços novos.

### O que fazer?

Se você está começando agora: **instale direto a v2**. Não tem motivo pra usar a v1.

Se você já tem scripts com a v1:

1. Use a [ferramenta de migração da AWS](https://aws.amazon.com/blogs/developer/upgrading-aws-cli-from-v1-to-v2-using-the-migration-tool/) pra identificar o que precisa mudar
2. Teste seus scripts com a v2
3. Atualize seus pipelines de CI/CD

**Dica:** A maioria dos comandos funciona igual nas duas versões. As diferenças estão em comportamentos padrão (como formato de saída) e alguns parâmetros específicos.

> Fonte: [CLI v1 Maintenance Mode Announcement](https://aws.amazon.com/blogs/developer/cli-v1-maintenance-mode-announcement/) — Janeiro 2026

---

## Resumo Rápido

| # | Realidade | Ação Imediata |
|---|-----------|---------------|
| 1 | Chave KMS padrão trava seus dados | Use CMK desde o primeiro banco |
| 2 | SQL Server agora vai até 256 TiB | Considere volumes adicionais pra separar logs |
| 3 | Só snapshot manual compartilha entre contas | Automatize a criação de snapshots manuais |
| 4 | Blue/Green faz update em < 5 segundos | Use pra toda atualização de engine |
| 5 | CLI v1 morre em julho/2026 | Instale a v2 hoje |

---

## Conclusão

O RDS não é uma "caixa preta" — é uma ferramenta poderosa que recompensa quem entende como ela funciona por baixo dos panos. Mesmo que você esteja dando os primeiros passos na AWS, entender essas 5 realidades vai te colocar à frente de muitos profissionais que aprenderam na dor.

A pergunta que fica: **sua estratégia de criptografia está preparada pra quando você precisar mover dados entre contas, ou você vai descobrir a armadilha da chave padrão no pior momento possível?**

---

*Artigo atualizado em maio de 2026. Todas as informações foram verificadas contra a documentação oficial da AWS.*
