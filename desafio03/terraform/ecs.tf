# ==========================================
# ECS Cluster
# ==========================================
resource "aws_ecs_cluster" "bia" {
  name = "bia-cluster"
}


# ==========================================
# ECS Task Definition
# ==========================================
resource "aws_ecs_task_definition" "bia" {
  family                   = "bia"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "bia"
    image     = var.bia_image
    essential = true
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "PORT", value = tostring(var.container_port) },
      { name = "DB_HOST", value = var.db_host },
      { name = "DB_PORT", value = var.db_port },
      { name = "DB_USER", value = var.db_user },
      { name = "DB_PWD", value = var.db_password },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/bia"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "bia"
      }
    }
  }])
}

# ==========================================
# ECS Service
# ==========================================
resource "aws_ecs_service" "bia" {
  name            = "bia-service"
  cluster         = aws_ecs_cluster.bia.id
  task_definition = aws_ecs_task_definition.bia.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [data.aws_security_group.bia_ec2_test.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bia.arn
    container_name   = "bia"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.https]
}
