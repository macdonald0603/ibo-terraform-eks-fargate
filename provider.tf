# Configure AWS Provider with the target region as variable
provider "aws" {
  region = var.aws_region
}
