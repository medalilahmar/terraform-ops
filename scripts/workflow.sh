#!/bin/bash
# ---------------------------------------------------------------------------
# Récapitulatif du cycle de vie Terraform standard en entreprise.
# À exécuter depuis environments/dev ou environments/prod.
# ---------------------------------------------------------------------------
set -e

echo "1. Initialisation (télécharge providers + modules, configure le backend)"
terraform init

echo "2. Formatage automatique du code selon les conventions HCL"
terraform fmt -recursive

echo "3. Validation syntaxique et cohérence (hors-ligne, rapide)"
terraform validate

echo "4. Plan : calcule le diff entre le state et le code (dry-run, aucune modif)"
terraform plan -var-file="terraform.tfvars" -out=tfplan

echo "5. Apply : applique EXACTEMENT le plan généré (bonne pratique : ne jamais"
echo "   relancer un apply sans passer par un plan préalable en CI/CD)"
terraform apply tfplan

echo "6. Affichage des outputs"
terraform output

# Destruction (à ne lancer que volontairement !)
# terraform plan -destroy -var-file="terraform.tfvars"
# terraform destroy -var-file="terraform.tfvars"
