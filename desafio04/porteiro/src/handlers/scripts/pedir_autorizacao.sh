INSTANCE_ID_PORTEIRO=i-08537b33c66b2b439
IP_PORTEIRO=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID_PORTEIRO} --query 'Reservations[0].Instances[0].PublicIpAddress' --profile cliente --region us-east-1 --output text)
echo $IP_PORTEIRO

PEM_PATH="/home/livia/desafiolabs/keys/formacao.pem"
SERVIDOR_RDS_1="bia.c4zy4cykm0n7.us-east-1.rds.amazonaws.com"
PORTA_LOCAL_RDS_1=5432

SERVDOR_RDS_2=SERVIDOR_2
PORTA_LOCAL_RDS_2=5432

ssh -f -N -i $PEM_PATH ec2-user@$IP_PORTEIRO -L $PORTA_LOCAL_RDS_1:$SERVIDOR_RDS_1:5432 -L $PORTA_LOCAL_RDS_2:$SERVDOR_RDS_2:5432

echo "Porteiro liberou acesso para:"
echo "> RDS 1: $SERVIDOR_RDS_1 na porta $PORTA_LOCAL_RDS_1"
echo "> RDS 2: $SERVDOR_RDS_2 na porta $PORTA_LOCAL_RDS_2"    