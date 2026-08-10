bucket         = "acmeparts-stage-terraform-states"
key            = "infrastructure/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "terraform-locks"
encrypt        = true
