# Terraform Ops

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.5-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Provider%20%3E%3D%205.0-FF9900?logo=amazonaws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![CI](https://github.com/<TON-USER>/terraform-ops/actions/workflows/terraform.yml/badge.svg)](https://github.com/<TON-USER>/terraform-ops/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Infrastructure AWS as Code — structure modulaire, environnements isolés, backend distant et pipeline CI/CD.

---

## Aperçu

Projet Terraform professionnel déployant un **VPC + Security Groups + EC2 Auto Scaling** avec les patterns utilisés en entreprise :

- **Modules réutilisables** (DRY) — VPC, Security Group, EC2
- **Environnements isolés** (`dev` / `prod`) — un state par environnement
- **Backend distant** — S3 (stockage) + DynamoDB (verrouillage)
- **CI/CD** — `fmt`, `validate`, `plan`, scan sécurité sur chaque PR
- **Sécurité** — secrets jamais versionnés, variables `sensitive`, principe du moindre privilège

---

## Structure

```
terraform-ops/
├── modules/                # Modules réutilisables
│   ├── vpc/                # VPC, subnets, route tables, IGW
│   ├── security-group/     # Règles de pare-feu dynamiques
│   └── ec2/                # EC2 + Auto Scaling Group
├── environments/           # Un dossier = un environnement = un state
│   ├── dev/
│   └── prod/
├── scripts/                # Scripts utilitaires (userdata, bootstrap)
├── .github/workflows/      # Pipeline CI GitHub Actions
└── README.md
```

---

## Démarrage rapide

### Prérequis

- Terraform `>= 1.5`
- AWS CLI `>= 2.0` configuré (`aws configure`)
- Git

### Déploiement

```bash
git clone https://github.com/<TON-USER>/terraform-ops.git
cd terraform-ops/environments/dev

cp terraform.tfvars.example terraform.tfvars   # éditer avec vos valeurs

terraform init
terraform fmt -recursive
terraform validate
terraform plan  -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## Concepts couverts

| Domaine | Notions |
|---|---|
| **HCL** | `provider`, `resource`, `data`, `variable`, `output`, `locals` |
| **Méta-arguments** | `count`, `for_each`, `dynamic`, `depends_on`, `lifecycle` |
| **State** | Backend S3 + DynamoDB, `state mv/rm/import`, drift |
| **Modules** | Entrées/sorties typées, versioning via tags Git |
| **CI/CD** | Plan automatique sur PR, apply manuel sur `main` |
| **Sécurité** | `sensitive = true`, scan `checkov`, OIDC AWS |

---

## Bonnes pratiques appliquées

- ✅ Versions Terraform & providers verrouillées (`required_version`, `required_providers`)
- ✅ Backend distant avec **state locking** (S3 + DynamoDB)
- ✅ **Un state par environnement** — isolation stricte dev / prod
- ✅ Modules sans valeurs codées en dur
- ✅ `terraform plan` obligatoire avant `apply`, review en PR
- ✅ Aucun secret versionné (`.tfstate`, `*.tfvars` dans `.gitignore`)
- ✅ Chaîne qualité : `fmt` + `validate` + `tflint` + `checkov`
- ✅ Tags cohérents : `Environment`, `Owner`, `ManagedBy=terraform`
- ✅ `prevent_destroy` sur les ressources critiques
- ✅ Nommage `<projet>-<env>-<ressource>`

---

## Commandes utiles

```bash
terraform init                          # Providers + modules + backend
terraform fmt -recursive                # Formatage HCL
terraform validate                      # Validation syntaxique
terraform plan                          # Dry-run
terraform apply -replace=<resource>     # Force la recréation d'une ressource
terraform state list                    # Inspecter le state
terraform import <resource> <id>        # Importer une ressource existante
terraform destroy                       # Détruire l'infrastructure
```

---

## CI/CD

Pipeline GitHub Actions (`.github/workflows/terraform.yml`) :

| Étape | Déclencheur | Action |
|---|---|---|
| `fmt`, `validate`, `tflint`, `checkov` | Pull Request | Contrôles qualité & sécurité |
| `plan` | Pull Request | Plan posté en commentaire |
| `apply` | Merge sur `main` | Après approbation manuelle |

**Secrets requis :** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`  
> 🔒 Préférer **OIDC + rôle IAM** en production plutôt que des clés statiques.

---

## Contribution

1. Fork & branche : `git checkout -b feat/ma-feature`
2. Commit : [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`)
3. `terraform fmt` avant commit
4. Ouvrir une Pull Request (review obligatoire avant merge sur `main`)

---

## Licence

Distribué sous licence **MIT** — voir [`LICENSE`](./LICENSE).