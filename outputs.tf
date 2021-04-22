# VPC
output "vpc_id" {
  description = "ID of the VPC that was created or passed in"
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the VPC private subnets that were created or passed in"
  value       = local.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the VPC public subnets that were created or passed in"
  value       = local.public_subnet_ids
}

# AMI
output "ubuntu20_ami_id" {
  value = data.aws_ami.ubuntu18_latest.id
}

//output "domains" {
//  value = {
//    web = aws_route53_record.web[0].name
//    api = aws_route53_record.api[0].name
//  }
//}

output "rds_endpoint" {
  value = module.db.this_db_instance_endpoint
}

output "s3_bucket_name" {
  value = replace(aws_s3_bucket.srv_files.bucket_domain_name, ".s3.amazonaws.com", "")
}