# ---------------------------------------------------------------------------
# Backend distant : state stocké sur S3, verrouillage via DynamoDB.
# Le bucket et la table DynamoDB doivent exister AVANT le premier `init`
# (souvent créés par un mini-projet Terraform "bootstrap" à part, ou à la main
# une seule fois).
#
# IMPORTANT : ce bloc ne peut PAS utiliser de variables (${var.x}) car il est
# lu avant même l'évaluation des variables. Les valeurs doivent être en dur
# ou passées via `terraform init -backend-config=...`.
# ---------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "myapp-terraform-locks"
    encrypt        = true
  }
}
