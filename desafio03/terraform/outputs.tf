output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.bia.endpoint
}

output "alb_dns" {
  description = "DNS do ALB"
  value       = aws_lb.bia.dns_name
}

output "app_url" {
  description = "URL da aplicação"
  value       = "https://${var.domain_name}"
}

output "ecs_cluster" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.bia.name
}

output "ecs_service" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.bia.name
}
