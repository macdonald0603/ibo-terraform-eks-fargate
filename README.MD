# Independent Bookstore Online - Cloud Infrastructure (Terraform)

This repository defines the infrastructure for an **Independent Online Bookstore (IBO)** using **Terraform** and **EKS** on **AWS**. The infrastructure is highly available, secure, and scalable, supporting production-grade deployment using Amazon EKS, RDS, and supporting services.

## 📦 Components Overview

### ☁️ AWS Provider
- Configured using a variable-defined region.

### 🌐 Networking
- **VPC**: Custom VPC with CIDR `10.0.0.0/16`.
- **Subnets**: 
  - 2 Public Subnets (across AZs for HA)
  - 2 Private Subnets (used for EKS and RDS)
- **Internet Gateway**: Attached to VPC for public access.
- **NAT Gateway**: Provides internet access for private subnets.
- **Route Tables**: Public and Private route tables with appropriate associations.

### 🛡️ Security
- **Security Groups**:
  - Web: Allows HTTP access
  - Database: Allows MySQL access from the web SG
  - Internal App: Allows internal traffic only
- **IAM Roles and Policies**:
  - EKS Cluster Role
  - EKS Node Role (with CNI, Worker Node, and ECR policies)
  - EKS Fargate Role
  - EC2 Role with Secrets Manager policy

### ☸️ Kubernetes (EKS)
- **EKS Cluster**: Deployed in private subnets with both public and private API access.
- **Node Group**: EC2 worker nodes using `t3.medium` instances.
- **Fargate Profile**: Optional, for serverless pod deployment.
- **Kubernetes Provider**: Authenticated via `aws_eks_cluster_auth`.
- **Kubernetes Deployment**: 
  - App: Docker container deployed to `default` namespace
  - Image from private ECR repository

### 💾 Storage and Data
- **RDS**: MySQL database in private subnets
  - Username: `admin` (use Secrets Manager for production!)
  - Security: Allows connections only from web tier SG
- **DB Subnet Group**: Ensures RDS is highly available across AZs.
- **Secrets Manager**: IAM role and policy created to access secrets (resources for actual secrets are commented).

### 📊 Monitoring and Logging 
- CloudWatch integration for:
  - EKS control plane logs
  - Node monitoring and application logs
  - Alarming and metric collection
- Potential use of Prometheus/Grafana for Kubernetes metrics

### 🔐 Security Best Practices 
- Encrypted S3 backend for Terraform state
- DynamoDB for state locking
- IAM roles scoped to least privilege where possible
- Placeholder values for sensitive data (e.g., DB password)

### 🛠️ Backend Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "ibo-prod-bucket"
    key            = "path/to/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "ibo-prod-app-db"
    encrypt        = true
  }
}
```

---

## 🚀 Getting Started

### Prerequisites
- AWS CLI configured with appropriate IAM permissions
- Terraform v1.x
- kubectl (for interacting with EKS)

### Initialize and Apply
```bash
terraform init
terraform apply
```

### Destroy
If the cluster is deleted manually, comment out or remove Kubernetes resources before running:
```bash
terraform destroy
```

---

## 📝 Notes
- Store secrets (DB credentials, tokens) in AWS Secrets Manager or Parameter Store.
- Consider enabling AWS Shield/Firewall Manager for production security.
- Use CI/CD pipelines for automated Terraform deployment and validation.

---

## 📁 Project Structure *(Recommended)*
```bash
terraform/
├── provider.tf
├── variables.tf
├── storage.tf
├── eks.tf
├── networking.tf
├── rds.tf
├── security.tf
├── backend.tf
├── database.tf
├── monitoring.tf
├── cost.tf
├── alb.tf
├── waf.tf
└── README.md
```
