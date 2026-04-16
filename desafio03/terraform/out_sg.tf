# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "sg-04721b37b7a06da28"
resource "aws_security_group" "bia_web" {
  description = "acesso do bia-web"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "bia-web para o mundo"
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
  }]
  name                   = "bia-web"
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-007e5bf38148c7121"
}

# __generated__ by Terraform from "sg-0dfdd93e3ddae2f4b"
resource "aws_security_group" "bia_ec2_test" {
  description = "acesso bia ec2 com alb"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "HTTPS para AWS APIs"
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
    }, {
    cidr_blocks      = []
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-0dcd164e0b3a63af1"]
    self             = false
    to_port          = 65535
    }, {
    cidr_blocks      = []
    description      = "saida para bia-db"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-04eb26de8b00feb9b"]
    self             = false
    to_port          = 5432
  }]
  ingress = [{
    cidr_blocks      = []
    description      = "acesso bia alb"
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["aws_security_group.bia_alb.id"]
    self             = false
    to_port          = 65535
  }]
  name                   = "bia-ec2-teste"
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-007e5bf38148c7121"
}

# __generated__ by Terraform from "sg-0dcd164e0b3a63af1"
resource "aws_security_group" "bia_alb" {
  description = "acesso bia-alb"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "acesso geral"
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "acesso vindo de bia-alb"
    from_port        = -1
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "icmp"
    security_groups  = ["sg-0dfdd93e3ddae2f4b"]
    self             = false
    to_port          = -1
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "free"
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "free"
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
  }]
  name                   = "bia-alb-teste"
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-007e5bf38148c7121"
}

# __generated__ by Terraform from "sg-04eb26de8b00feb9b"
resource "aws_security_group" "bia_db" {
  description = "acesso ao bia-db"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["172.31.11.48/32"]
    description      = "acesso da instancia bia-dev"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 5432
    }, {
    cidr_blocks      = []
    description      = ""
    from_port        = 5433
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-04eefe0a11f616aa6"]
    self             = false
    to_port          = 5433
    }, {
    cidr_blocks      = []
    description      = "acesso bia-web"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-04721b37b7a06da28"]
    self             = false
    to_port          = 5432
    }, {
    cidr_blocks      = []
    description      = "acesso do bia-dev"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-01cf577e0933cffe6"]
    self             = false
    to_port          = 5432
    }, {
    cidr_blocks      = []
    description      = "acesso vindo de bia-ec2-teste"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = ["sg-0dfdd93e3ddae2f4b"]
    self             = false
    to_port          = 5432
  }]
  name                   = "bia-db"
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-007e5bf38148c7121"
}
