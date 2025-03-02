# Terraform AWS Infrastructure Project

## Overview
This Terraform project sets up a fully functional AWS infrastructure, including:

- **Remote Backend**: S3 bucket for storing Terraform state.
- **Networking**:
  - VPC
  - Public & private subnets
  - Internet Gateway (IGW)
  - Route tables and routes
- **Security**:
  - Security groups for controlled access
  - Key pair for SSH access
- **Compute & Scaling**:
  - Launch templates
  - Auto Scaling Group (ASG)
  - Application Load Balancer (ALB)

## Prerequisites
Ensure you have the following installed:
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI](https://aws.amazon.com/cli/)
- AWS credentials configured (`aws configure`)

## Setup Instructions

### 1. Clone the Repository
```sh
git clone https://github.com/pell-a/terraform-1.git
```

### 2. Initialize Terraform
```sh
terraform init
```
This command initializes the Terraform working directory and downloads the required providers and modules.

### 3. Plan the Deployment
```sh
terraform plan
```
This command shows what changes will be applied without making any modifications.

### 4. Apply the Configuration
```sh
terraform apply -auto-approve
```
This will provision the AWS infrastructure.

### 5. Create an SSH Key (if applicable)
```sh
ssh-keygen -t rsa -b 4096 -f my-key.pem -N ""
chmod 400 my-key.pem
```

## Verifying the Deployment

- **Check Auto Scaling Group:**
  ```sh
  aws autoscaling describe-auto-scaling-groups --region <your-region>
  ```
- **Check ALB Endpoint:**
  ```sh
  echo "Application Load Balancer URL: $(terraform output -raw alb_dns_name)"
  ```

## Destroying the Infrastructure
To tear down the entire infrastructure:
```sh
terraform destroy -auto-approve
```

## Additional Notes
- Ensure your AWS IAM user has the necessary permissions for creating and managing resources.
- The Terraform state is stored remotely in an S3 bucket for collaboration and state locking.

---
✅ **Author:** *Your Name*  
📜 **License:** MIT  
🚀 **Happy Terraforming!**

