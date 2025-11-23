# sg-only.tf (egress -> VPC CIDR only)
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "specific_web_sg" {
  name_prefix = var.sg_name_prefix
  description = "Specific SG: only allow access from a single CIDR to a single port"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "Allow specific IP to access port ${var.port}"
  }

  # 出站仅限于 VPC 内（使用 VPC 的 CIDR）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    description = "Restrict egress to within the VPC"
  }

  tags = {
    Name = "${var.sg_name_prefix}${var.port}"
    Env  = "dev"
  }
}
