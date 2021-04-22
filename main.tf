locals {
  # VPC - existing or new?
  vpc_id             = var.vpc_id == "" ? module.vpc.vpc_id : var.vpc_id
  private_subnet_ids = coalescelist(module.vpc.private_subnets, var.private_subnet_ids, [""])
  public_subnet_ids  = coalescelist(module.vpc.public_subnets, var.public_subnet_ids, [""])
  azs                = coalescelist(var.azs, data.aws_availability_zones.available.zone_ids)

  ami_id = var.ami_id == "" ? data.aws_ami.ubuntu18_latest.id : var.ami_id

  public_subnets = length(var.public_subnets) != 0 ? var.public_subnets : [for i in range(1, length(local.azs) + 1) : cidrsubnet(var.cidr, 8, i)]
  # private_subnets = length(var.private_subnets) != 0 ? var.private_subnets : [for i in range(10, length(local.azs) + 10) : cidrsubnet(var.cidr, 8, i)]

  name_env = "${var.name}_${var.env}"

  // create or not
  r53count = var.r53_zone_id == "" ? 0 : 1

  tags = merge(
    {
      Name        = var.name
      Environment = var.env
      Terraform   = "true"
    },
    var.tags,
  )
}


###################
# VPC
###################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v2.64.0"

  create_vpc = var.vpc_id == ""

  name = var.name

  cidr            = var.cidr
  azs             = local.azs
  private_subnets = var.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = length(var.private_subnets) != 0
  single_nat_gateway = length(var.private_subnets) != 0

  tags = local.tags
  public_subnet_tags = {
    Scope : "public"
  }
  private_subnet_tags = {
    Scope : "private"
  }
  private_route_table_tags = {
    Scope : "private"
  }
  database_route_table_tags = {
    Purpose : "database route table"
  }
}


###################
# IAM
###################
resource "aws_iam_role" "ec2" {
  name               = local.name_env
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy" "ec2policy" {
  name = local.name_env
  role = aws_iam_role.ec2.id

  policy = templatefile(
    "ec2policy.json.tpl",
    {
      region : var.ecr_region,
      account_id : data.aws_caller_identity.current.id,
    }
  )
}

###################
# EC2
###################

resource "aws_iam_instance_profile" "vw" {
  name = var.name
  role = aws_iam_role.ec2.name
}

resource "random_shuffle" "public_subnet_id" {
  input = local.public_subnet_ids
}

resource "aws_key_pair" "vw" {
  key_name_prefix = var.name

  public_key = var.ssh_public_key
  tags       = local.tags
}

resource "aws_security_group" "vw" {
  name = local.name_env

  vpc_id = local.vpc_id

  dynamic "ingress" {
    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_eip" "vw_api" {
  instance = aws_instance.vw_api.id
  vpc      = true

  tags = local.tags
}

resource "aws_eip" "vw_web" {
  instance = aws_instance.vw_web.id
  vpc      = true

  tags = local.tags
}

resource "aws_instance" "vw_api" {
  ami           = data.aws_ami.ubuntu18_latest.id
  instance_type = var.api_instance_type

  key_name                    = aws_key_pair.vw.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.vw.id]
  subnet_id                   = random_shuffle.public_subnet_id.result[0]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.vw.name

  user_data = templatefile("ec2data.sh.tpl", { name : regex("[a-zA-Z\\-]+", "vw${var.env}-api"), user : "ubuntu" })

  root_block_device {
    volume_size = var.api_root_volume_size
    volume_type = var.api_root_volume_type
  }

  tags = merge(local.tags, { Purpose : "serve VW API" })
}

resource "aws_instance" "vw_web" {
  ami           = data.aws_ami.ubuntu18_latest.id
  instance_type = var.web_instance_type

  key_name                    = aws_key_pair.vw.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.vw.id]
  subnet_id                   = random_shuffle.public_subnet_id.result[0]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.vw.name

  user_data = templatefile("ec2data.sh.tpl", { name : regex("[a-zA-Z\\-]+", "vw${var.env}-web"), user : "ubuntu" })

  root_block_device {
    volume_size = var.web_root_volume_size
    volume_type = var.web_root_volume_type
  }

  tags = merge(local.tags, { Purpose : "serve VW front-end application" })
}

###################
# RDS
###################
locals {
  ssm_param_rds_password_name = "/${var.name}/${var.env}/mysql"
}

resource "aws_security_group" "rds" {
  name = "${local.name_env}_db"

  vpc_id = local.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.vw_api.private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Purpose : "MySQL instance security group" })
}

resource "random_password" "rds_password" {
  length           = 12
  special          = true
  override_special = "!%&*,"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  keepers = {
    version = var.rds_password_version
  }
}

resource "aws_ssm_parameter" "rds_password" {
  name        = local.ssm_param_rds_password_name
  type        = "SecureString"
  value       = random_password.rds_password.result
  description = "Master password for Velmie Wallet MySQL RDS instance"
  tags        = merge(local.tags, { Purpose : "MySQL master password" })
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = regex("[a-zA-Z0-9\\-]+", replace(local.name_env, "_", "-"))

  engine            = "mysql"
  engine_version    = "5.7.31"
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  username = "admin"
  password = random_password.rds_password.result
  port     = "3306"

  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = local.tags

  # DB subnet group
  subnet_ids = [random_shuffle.public_subnet_id.result[0], random_shuffle.public_subnet_id.result[1]]

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  skip_final_snapshot = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]
}

###################
# S3
###################

resource "aws_iam_user" "srv_files" {
  name = "${local.name_env}_files"

  force_destroy = true

  tags = merge(local.tags, { Purpose : "used by the files service" })
}

/*resource "aws_iam_access_key" "srv_files" {
  user = aws_iam_user.srv_files.name
}*/

resource "aws_iam_user_policy" "srv_files" {
  name = "${local.name_env}_files"
  user = aws_iam_user.srv_files.name

  policy = templatefile(
    "s3srvfilespolicy.json.tpl",
    {
      sid    = regex("[0-9A-Za-z]+", replace(local.name_env, "_", ""))
      s3_arn = aws_s3_bucket.srv_files.arn
    }
  )
}


resource "aws_s3_bucket" "srv_files" {
  bucket_prefix = regex("[a-zA-Z]+", "${local.name_env}-")
  acl           = "private"

  tags = merge(local.tags, { Purpose : "used by the files service in order too store uploads" })
}

###################
# ECR Upload user
###################

resource "aws_iam_user" "ecr_upload" {
  name = "${local.name_env}_ecr_upload"

  force_destroy = true

  tags = merge(local.tags, { Purpose : "used for images upload" })
}


resource "aws_iam_user_policy" "ecr_upload" {
  name = "${local.name_env}_ecr_upload"
  user = aws_iam_user.ecr_upload.name

  policy = templatefile(
  "ecrupload2policy.json.tpl",
  {
    region : var.ecr_region,
    account_id : data.aws_caller_identity.current.id,
  }
  )
}



###################
# Route53
###################
//resource "aws_route53_record" "api" {
//  count   = local.r53count
//  zone_id = var.r53_zone_id
//  name    = "${var.api_subdomain}.${data.aws_route53_zone.vw[0].name}"
//  type    = "A"
//  ttl     = "300"
//  records = [aws_eip.vw_api.public_ip]
//}
//
//resource "aws_route53_record" "web" {
//  count   = local.r53count
//  zone_id = var.r53_zone_id
//  name    = "${var.web_subdomain}.${data.aws_route53_zone.vw[0].name}"
//  type    = "A"
//  ttl     = "300"
//  records = [aws_eip.vw_web.public_ip]
//}