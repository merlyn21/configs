bucket         = "dev-acmeparts-terraform-states"
key            = "infrstructure/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "terraform-locks"
encrypt        = true
