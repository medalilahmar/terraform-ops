# ---------------------------------------------------------------------------
# Backend PROD : même bucket que dev est possible, mais une "key" différente
# => un state complètement séparé. C'est ce qui garantit qu'un `terraform
# destroy` lancé par erreur dans environments/dev ne touchera JAMAIS prod.
# ---------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "myapp-terraform-locks"
    encrypt        = true
  }
}
