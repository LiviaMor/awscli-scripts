FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

RUN dnf install -y aws-cli python3 jq && dnf clean all

WORKDIR /app

COPY processar-mensagem-sqs.sh .
RUN chmod +x processar-mensagem-sqs.sh

# Variáveis de ambiente necessárias
ENV AWS_DEFAULT_REGION=us-east-1
ENV QUEUE_URL=""

CMD ["bash", "-c", "./processar-mensagem-sqs.sh $QUEUE_URL"]
