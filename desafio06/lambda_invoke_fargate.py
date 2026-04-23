import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs = boto3.client("ecs")


def get_config():
    return {
        "cluster": os.environ["CLUSTER_NAME"],
        "task_definition": os.environ["TASK_DEFINITION"],
        "container_name": os.environ["CONTAINER_NAME"],
        "subnets": os.environ["SUBNETS"].split(","),
        "security_groups": os.environ["SECURITY_GROUPS"].split(","),
        "queue_url": os.environ["QUEUE_URL"],
    }


def extract_messages(event):
    return [
        {
            "message_id": record["messageId"],
            "receipt_handle": record["receiptHandle"],
            "body": record.get("body", ""),
        }
        for record in event.get("Records", [])
    ]


def run_fargate_task(message, config):
    response = ecs.run_task(
        cluster=config["cluster"],
        taskDefinition=config["task_definition"],
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": config["subnets"],
                "securityGroups": config["security_groups"],
                "assignPublicIp": "ENABLED",
            }
        },
        overrides={
            "containerOverrides": [
                {
                    "name": config["container_name"],
                    "environment": [
                        {"name": "RECEIPT_HANDLE", "value": message["receipt_handle"]},
                        {"name": "QUEUE_URL", "value": config["queue_url"]},
                        {"name": "MSG_BODY", "value": message["body"]},
                    ],
                }
            ]
        },
    )

    tasks = response.get("tasks", [])
    if not tasks:
        failures = response.get("failures", [])
        raise Exception(f"Falha ao iniciar task: {failures}")

    task_arn = tasks[0]["taskArn"]
    logger.info(f"Task iniciada: {task_arn}")
    return task_arn


def lambda_handler(event, context):
    config = get_config()
    messages = extract_messages(event)

    for message in messages:
        logger.info(f"Mensagem recebida: {message['message_id']}")
        run_fargate_task(message, config)

    # Erro intencional: impede o Lambda de deletar a mensagem da fila SQS.
    # A exclusão será feita pelo Fargate após processar a mensagem.
    raise Exception("Erro intencional para manter mensagem na fila.")
