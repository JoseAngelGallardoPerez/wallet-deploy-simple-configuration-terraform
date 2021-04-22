variable "name" {
  description = "Name to use on all resources created (VPC, SG, etc)"
  type        = string
  default     = "velmie_wallet"
}

variable "env" {
  description = "Working environment such as dev, test, prod or whatever else that suits your requirements"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}

variable "vw_security_group_tags" {
  description = "Additional tags to put on the velmie wallet security group"
  type        = map(string)
  default     = {}
}

# VPC
variable "vpc_id" {
  description = "ID of an existing VPC where resources will be created"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "A list of IDs of existing public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "A list of IDs of existing private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "cidr" {
  description = "The CIDR block for the VPC which will be created if `vpc_id` is not specified"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "A list of availability zones in the region (default is all available AZs in the current region)"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC (default is one subnet per AZ)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC (no private subnets by default)"
  type        = list(string)
  default     = []
}

# EC2
variable "api_instance_type" {
  description = "Velmie Wallet EC2 instance type"
  type        = string
  default     = ""
}

variable "api_root_volume_size" {
  description = "The size of the volume in gibibytes (GiB)"
  type        = number
  default     = 30
}

variable "api_root_volume_type" {
  description = "The type of volume. Can be 'standard', 'gp2', 'io1', 'io2', 'sc1', or 'st1'"
  type        = string
  default     = "gp2"
}

variable "web_instance_type" {
  description = "Velmie Wallet EC2 instance type"
  type        = string
  default     = ""
}

variable "web_root_volume_size" {
  description = "The size of the volume in gibibytes (GiB)"
  type        = number
  default     = 20
}

variable "web_root_volume_type" {
  description = "The type of volume. Can be 'standard', 'gp2', 'io1', 'io2', 'sc1', or 'st1'"
  type        = string
  default     = "gp2"
}

variable "ami_id" {
  description = "AMI id which will be used for the EC2 instances (default is ubuntu latest)"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "The key is used to control login access to EC2 instances"
  type        = string
  default     = ""
}

variable "allow_ports" {
  description = "List of open ports (sg)"
  type        = list(number)
  default     = [80, 443]
}

# ECR
variable "ecr_region" {
  description = "Name of the region where the ECR is (used for ec2 role)"
  type        = string
}

# RDS
variable "rds_password_version" {
  description = "This variable is used as RDS password random string keeper"
  type        = string
  default     = "v1"
}

variable "rds_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = string
  default     = 5
}

# Route53
variable "r53_zone_id" {
  description = "Hosted zone ID where to create records."
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "Subdomain name which is used in order to create AWS route 53 record to point to EC2 instance."
  type        = string
  default     = ""
}

variable "web_subdomain" {
  description = "Subdomain name which is used in order to create AWS route 53 record to point to EC2 instance."
  type        = string
  default     = ""
}