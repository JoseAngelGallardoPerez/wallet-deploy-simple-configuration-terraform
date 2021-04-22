# Velmie Wallet Terraform Assets

This repository contains terraform configuration for deploying the AWS infrastructure necessary 
for the Velmie Wallet platform to work.

This configuration supposed to be used for deploying demo environments.   

## Prerequisites

Configure AWS **Administrator** access by providing environment variables:

```
export AWS_ACCESS_KEY_ID=key_id
export AWS_SECRET_ACCESS_KEY=secret
export AWS_DEFAULT_REGION=region
```

> You may use any other way supported by terraform.

**It is highly recommended** to provision [Terraform state storage backend.](https://www.terraform.io/docs/backends/state.html).

Since we are using AWS infrastructure, the recommended state backend is an [AWS S3 bucket](https://www.terraform.io/docs/backends/types/s3.html).

**Security consideration**. 
> Terraform state can contain sensitive data, depending on the resources in use and your definition of "sensitive." The state contains resource IDs and all resource attributes.
For resources such as databases, this may contain initial passwords.

Since we manage sensitive data with Terraform (database password), we must treat the state itself as sensitive data.

The S3 backend supports encryption at rest when the encrypt option is enabled.
IAM policies and logging can be used to identify any invalid access. Requests for the state go over a TLS connection.  

## Resources to be created

* VPC (Could be used existing one.)
* EC2 instance for API
* EC2 instance for Web app
* 2 Elastic IPs
* Key pair
* Security groups (for EC2 instances and RDS instance)
* SSM parameter that stores MySQL master password
* RDS MySQL instance
* Private S3 bucket (for use by the file service)
* IAM role for EC2 instances (see `ec2policy.json.tpl`)
* IAM user for the file service
* Route53 records (if Route53 zone id is provided)

## Steps

1. Run `terraform init`
2. Copy `terraform.tfvars.sample` as `terraform.tfvars`;
3. Edit `terraform.tfvars` in accordance to your requirements (check also `variables.tf` for more options);
4. Run `terraform plan` in order to ensure what is going to be created;
5. Run `terraform apply` and confirm the job.
