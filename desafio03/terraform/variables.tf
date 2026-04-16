variable "region" {
  default = "us-east-1"
}

variable "vpc_id" {
  default = "vpc-007e5bf38148c7121"
}

variable "subnets" {
  default = [
    "subnet-004fc006f214f0ad1", # us-east-1a
    "subnet-03bd03829c971a89a", # us-east-1b
  ]
}

variable "bia_image" {
  default = "794038217446.dkr.ecr.us-east-1.amazonaws.com/bia:latest"
}

variable "container_port" {
  default = 8080
}

variable "domain_name" {
  default = "formacaoaws.ninehealth.com.br"
}

variable "hosted_zone_id" {
  default = "Z0600092UI2ZZMFI10D4"
}

variable "db_host" {
  default = "bia.c4zy4cykm0n7.us-east-1.rds.amazonaws.com"
}

variable "db_port" {
  default = "5432"
}

variable "db_user" {
  default = "postgres"
}

variable "db_password" {
  sensitive = true
  # Defina via: terraform apply -var="db_password=SUA_SENHA"
}
