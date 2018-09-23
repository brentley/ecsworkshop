    terraform {
      backend "s3" {
        bucket         = "476172414658-us-east-1-ecsworkshop.com-terraform-state-store"
        key            = "terraform.tfstate"
        region         = "us-east-1"
        encrypt        = false
        dynamodb_table = "476172414658-us-east-1-dynamodb-terraform-lock-table"
      }
    }
    