
terraform {
  backend "s3" {
    bucket         = "tmapp2"             
    key            = "eks/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true

   # dynamodb_table = "terraform-locks"
  }
}
