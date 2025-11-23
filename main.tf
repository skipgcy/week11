# sg-only.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  region = "us-west-2"
}

# 如果你没有提供 vpc_id，Terraform 会自动使用默认 VPC
data "aws_vpc" "default" {
  default = true
}

variable "vpc_id" {
  description = "要放置 Security Group 的 VPC ID（可选）。如果留空，将使用默认 VPC。"
  type        = string
  default     = ""
}

variable "allowed_cidr" {
  description = "允许访问的单个 CIDR（例如：你的公网 IP/32）。替换为你自己的 IP。"
  type        = string
  default     = "203.0.113.5/32" # <- 把这个改成你的 IP/CIDR
}

variable "port" {
  description = "要开放的端口（单个端口）"
  type        = number
  default     = 8080
}

variable "sg_name_prefix" {
  description = "security group 名称前缀"
  type        = string
  default     = "specific-web-sg-"
}

resource "aws_security_group" "specific_web_sg" {
  name_prefix = var.sg_name_prefix
  description = "Specific SG: only allow access from a single CIDR to a single port"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  # 仅允许来自 allowed_cidr 的单端口入站（tcp）
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "Allow specific IP to access port ${var.port}"
  }

  # 推荐做法：尽量限制出站；下面示例允许访问 HTTP/HTTPS（80/443）
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTP"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTPS"
  }

  tags = {
    Name = "${var.sg_name_prefix}${var.port}"
    Env  = "dev"
  }
}

output "security_group_id" {
  description = "Created security group id"
  value       = aws_security_group.specific_web_sg.id
}
