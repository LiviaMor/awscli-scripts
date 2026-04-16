#!/bin/bash
# Scripts S3 - Amazon Simple Storage Service (S3)
# Operações: ls, cp, sync, storage class, dry-run, presigned URL
# Fonte: https://docs.aws.amazon.com/cli/latest/reference/s3/

echo "=========================================="
echo "       S3 - Menu Interativo"
echo "=========================================="
echo "1) Listar buckets"
echo "2) Listar conteúdo de um bucket"
echo "3) CP    - Copiar arquivo para S3"
echo "4) CP    - Baixar arquivo do S3"
echo "5) SYNC  - Sincronizar pasta local → S3"
echo "6) SYNC  - Sincronizar S3 → pasta local"
echo "7) CP    - Upload com Storage Class (Standard_IA, Glacier, etc)"
echo "8) DRY-RUN - Simular sync sem executar"
echo "9) Gerar URL pré-assinada (Presign)"
echo "0) Sair"
echo ""
read -p "Escolha uma opção: " OPCAO

case $OPCAO in
  1)
    # Lista todos os buckets da conta
    echo "Listando buckets..."
    aws s3 ls
    ;;

  2)
    # Lista objetos dentro de um bucket
    read -p "Nome do bucket: " BUCKET_NAME
    [[ -z "$BUCKET_NAME" ]] && echo "Erro: nome do bucket vazio." && exit 1
    aws s3 ls "s3://$BUCKET_NAME" --recursive --human-readable
    ;;

  3)
    # aws s3 cp - Copia um arquivo local para o S3
    read -p "Caminho do arquivo local: " LOCAL_FILE
    [[ ! -f "$LOCAL_FILE" ]] && echo "Erro: arquivo '$LOCAL_FILE' não encontrado." && exit 1
    read -p "Nome do bucket: " BUCKET_NAME
    read -p "Chave no S3 (ex: pasta/arquivo.txt) [padrão: nome do arquivo]: " S3_KEY
    S3_KEY=${S3_KEY:-$(basename "$LOCAL_FILE")}
    echo "Copiando '$LOCAL_FILE' → s3://$BUCKET_NAME/$S3_KEY ..."
    aws s3 cp "$LOCAL_FILE" "s3://$BUCKET_NAME/$S3_KEY"
    ;;

  4)
    # aws s3 cp - Baixa um arquivo do S3 para local
    read -p "Nome do bucket: " BUCKET_NAME
    [[ -z "$BUCKET_NAME" ]] && echo "Erro: nome do bucket vazio." && exit 1
    echo "Objetos disponíveis:"
    aws s3 ls "s3://$BUCKET_NAME" --recursive
    echo ""
    read -p "Chave do objeto no S3: " OBJECT_KEY
    read -p "Caminho local de destino (ex: ./arquivo.txt): " LOCAL_DEST
    echo "Baixando s3://$BUCKET_NAME/$OBJECT_KEY → $LOCAL_DEST ..."
    aws s3 cp "s3://$BUCKET_NAME/$OBJECT_KEY" "$LOCAL_DEST"
    ;;

  5)
    # aws s3 sync - Sincroniza pasta local com bucket S3
    # Envia apenas arquivos novos ou modificados
    read -p "Pasta local de origem: " LOCAL_DIR
    [[ ! -d "$LOCAL_DIR" ]] && echo "Erro: pasta '$LOCAL_DIR' não encontrada." && exit 1
    read -p "Nome do bucket: " BUCKET_NAME
    read -p "Prefixo no S3 (ex: backup/) [padrão: raiz]: " S3_PREFIX
    echo "Sincronizando '$LOCAL_DIR' → s3://$BUCKET_NAME/$S3_PREFIX ..."
    aws s3 sync "$LOCAL_DIR" "s3://$BUCKET_NAME/$S3_PREFIX"
    ;;

  6)
    # aws s3 sync - Sincroniza bucket S3 com pasta local
    read -p "Nome do bucket: " BUCKET_NAME
    read -p "Prefixo no S3 (ex: backup/) [padrão: raiz]: " S3_PREFIX
    read -p "Pasta local de destino: " LOCAL_DIR
    mkdir -p "$LOCAL_DIR"
    echo "Sincronizando s3://$BUCKET_NAME/$S3_PREFIX → '$LOCAL_DIR' ..."
    aws s3 sync "s3://$BUCKET_NAME/$S3_PREFIX" "$LOCAL_DIR"
    ;;

  7)
    # aws s3 cp com --storage-class
    # Standard_IA: acesso infrequente, custo menor de armazenamento
    # Glacier: arquivamento de longo prazo, custo muito baixo
    read -p "Caminho do arquivo local: " LOCAL_FILE
    [[ ! -f "$LOCAL_FILE" ]] && echo "Erro: arquivo '$LOCAL_FILE' não encontrado." && exit 1
    read -p "Nome do bucket: " BUCKET_NAME
    read -p "Chave no S3 [padrão: nome do arquivo]: " S3_KEY
    S3_KEY=${S3_KEY:-$(basename "$LOCAL_FILE")}
    echo ""
    echo "Classes de armazenamento disponíveis:"
    echo "  a) STANDARD_IA      - Acesso infrequente, custo menor"
    echo "  b) ONEZONE_IA       - Acesso infrequente, uma única AZ"
    echo "  c) GLACIER           - Arquivamento, recuperação em minutos/horas"
    echo "  d) DEEP_ARCHIVE      - Arquivamento longo prazo, recuperação em horas"
    echo "  e) INTELLIGENT_TIERING - Move automaticamente entre tiers"
    read -p "Escolha (a/b/c/d/e): " CLASS_OPT
    case $CLASS_OPT in
      a) STORAGE_CLASS="STANDARD_IA" ;;
      b) STORAGE_CLASS="ONEZONE_IA" ;;
      c) STORAGE_CLASS="GLACIER" ;;
      d) STORAGE_CLASS="DEEP_ARCHIVE" ;;
      e) STORAGE_CLASS="INTELLIGENT_TIERING" ;;
      *) echo "Opção inválida." && exit 1 ;;
    esac
    echo "Enviando com storage class $STORAGE_CLASS ..."
    aws s3 cp "$LOCAL_FILE" "s3://$BUCKET_NAME/$S3_KEY" --storage-class "$STORAGE_CLASS"
    ;;

  8)
    # aws s3 sync --dryrun
    # Simula a sincronização sem transferir nenhum arquivo
    read -p "Pasta local de origem: " LOCAL_DIR
    [[ ! -d "$LOCAL_DIR" ]] && echo "Erro: pasta '$LOCAL_DIR' não encontrada." && exit 1
    read -p "Nome do bucket: " BUCKET_NAME
    read -p "Prefixo no S3 (ex: backup/) [padrão: raiz]: " S3_PREFIX
    echo "Simulando sync (dry-run) '$LOCAL_DIR' → s3://$BUCKET_NAME/$S3_PREFIX ..."
    echo "(Nenhum arquivo será transferido)"
    aws s3 sync "$LOCAL_DIR" "s3://$BUCKET_NAME/$S3_PREFIX" --dryrun
    ;;

  9)
    # aws s3 presign - Gera URL temporária para acessar um objeto sem autenticação
    read -p "Nome do bucket: " BUCKET_NAME
    [[ -z "$BUCKET_NAME" ]] && echo "Erro: nome do bucket vazio." && exit 1
    echo ""
    echo "Objetos em s3://$BUCKET_NAME:"
    aws s3 ls "s3://$BUCKET_NAME" --recursive
    echo ""
    read -p "Chave do objeto: " OBJECT_KEY
    [[ -z "$OBJECT_KEY" ]] && echo "Erro: chave do objeto vazia." && exit 1
    read -p "Expiração em segundos (padrão 3600): " EXPIRES
    EXPIRES=${EXPIRES:-3600}
    echo "URL pré-assinada (válida por ${EXPIRES}s):"
    aws s3 presign "s3://$BUCKET_NAME/$OBJECT_KEY" --expires-in "$EXPIRES"
    ;;

  0)
    echo "Saindo."
    exit 0
    ;;

  *)
    echo "Opção inválida."
    exit 1
    ;;
esac
