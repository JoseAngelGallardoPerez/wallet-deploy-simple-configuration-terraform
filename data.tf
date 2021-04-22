data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu18_latest" {
  owners      = ["099720109477"] // Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu20_latest" {
  owners      = ["099720109477"] // Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_role" "ecr" {
  name       = local.name_env
  depends_on = [aws_iam_role.ec2]
}

data "aws_route53_zone" "vw" {
  count   = local.r53count
  zone_id = var.r53_zone_id
}