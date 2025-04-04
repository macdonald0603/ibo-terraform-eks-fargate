terraform {
  backend "s3" {
    bucket = "ibo-prod-bucket"            #Create your s3 bucket 
    key    = "path/to/terraform.tfstate"  # Define your desired path for the state file within the bucket
    region = "us-east-2"                  # Define the appropriate AWS region
    dynamodb_table = "ibo-prod-app-db"    # Dynamo table for prod
    encrypt = true                        # Enable encryption for the state file
  }
}
