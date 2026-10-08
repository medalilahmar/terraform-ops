# Projet Terraform Complet — Guide d'apprentissage & préparation entretien

Ce projet déploie une infrastructure AWS réaliste (VPC + Security Groups + EC2 en Auto Scaling)
en utilisant **toutes les notions fondamentales de Terraform**. Le but n'est pas la complexité
de l'infra, mais de te faire manipuler chaque concept que tu peux voir en entretien.

---

## 1. Structure du projet

```
terraform-complete-project/
├── modules/                    # Modules réutilisables (bonne pratique : DRY)
│   ├── vpc/                    # Réseau (VPC, subnets, route tables, IGW)
│   ├── security-group/         # Règles de pare-feu
│   └── ec2/                    # Instances EC2 / Auto Scaling Group
├── environments/                # Un dossier = un environnement = un state
│   ├── dev/
│   └── prod/
├── scripts/                    # Scripts utilitaires (userdata, etc.)
└── README.md
```

**Pourquoi cette structure ?**
- Les **modules** contiennent la logique réutilisable, sans valeurs codées en dur.
- Les **environments** (dev/prod) appellent les modules avec des valeurs différentes.
- Chaque environnement a **son propre state** → isolation totale entre dev et prod
  (une erreur en dev ne peut jamais casser prod).

C'est l'alternative professionnelle aux "workspaces" Terraform pour séparer des environnements
(voir section 9 pour la comparaison, souvent demandée en entretien).

---

## 2. Les briques de base du langage (HCL)

### 2.1 Provider
Le provider indique à Terraform **avec quelle API parler** (AWS, Azure, GCP, Kubernetes...).
Voir `environments/dev/versions.tf`.

### 2.2 Resource
Un `resource` déclare un objet d'infrastructure à créer/gérer.
```hcl
resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t3.micro"
}
```
Format : `resource "<TYPE>" "<NOM_LOCAL>" { ... }`. Le nom local est interne à Terraform,
pas le nom réel de la ressource dans le cloud.

### 2.3 Data source
Un `data` **lit** une ressource existante (créée en dehors de Terraform, ou par un autre state),
sans la gérer. Exemple : récupérer dynamiquement la dernière AMI Amazon Linux.
Voir `modules/ec2/main.tf`.

### 2.4 Variables (input)
Paramètres d'entrée d'un module/projet. Toujours typées, avec description, et validation si besoin.
Voir `modules/vpc/variables.tf` pour des exemples de `type`, `default`, `validation`.

### 2.5 Outputs
Valeurs exposées en sortie d'un module ou d'un projet (ex : IP publique, ID du VPC).
Permettent de chaîner des modules entre eux. Voir `modules/vpc/outputs.tf`.

### 2.6 Locals
Valeurs calculées/intermédiaires, internes au module, pour éviter la répétition.
Voir `environments/dev/main.tf` (bloc `locals`).

---

## 3. Expressions et méta-arguments (très demandés en entretien)

| Concept | Usage | Où le voir dans ce projet |
|---|---|---|
| `count` | Créer N ressources identiques (index numérique) | `modules/ec2/main.tf` |
| `for_each` | Créer une ressource par élément d'une map/set (clé nommée, plus robuste que count) | `modules/vpc/main.tf` (subnets) |
| Expression conditionnelle `condition ? val_true : val_false` | Logique conditionnelle inline | `modules/ec2/main.tf` |
| `dynamic "block" {}` | Générer des blocs répétés dynamiquement (ex : règles SG) | `modules/security-group/main.tf` |
| `depends_on` | Forcer un ordre de création explicite | `modules/ec2/main.tf` |
| `lifecycle { }` | `create_before_destroy`, `prevent_destroy`, `ignore_changes` | `modules/ec2/main.tf` |

**Différence count vs for_each (question classique d'entretien)** :
- `count` : liste indexée par un nombre (0,1,2...). Si tu supprimes l'élément du milieu,
  Terraform décale tous les index suivants → risque de recréer/détruire des ressources.
- `for_each` : indexé par une clé stable (string). Supprimer un élément ne touche que lui.
  → **for_each est recommandé dès que les éléments ont une identité logique.**

---

## 4. Le State — LE concept le plus important en entretien

Le fichier `terraform.tfstate` est la **source de vérité** de Terraform : il fait correspondre
les ressources déclarées dans le code à leurs identifiants réels dans le cloud.

### Pourquoi ne jamais utiliser le state local en équipe/prod
- Pas de verrouillage (deux personnes peuvent lancer `apply` en même temps → corruption)
- Pas partagé entre les membres de l'équipe
- Contient des données sensibles en clair (mots de passe, clés...) → ne jamais le commit sur Git

### Backend distant (bonne pratique obligatoire en entreprise)
Voir `environments/dev/backend.tf` : ici un backend **S3 + DynamoDB** :
- **S3** : stocke le fichier `.tfstate` de façon centralisée et versionnée
- **DynamoDB** : fournit le **verrouillage** (state locking) → empêche deux `apply` concurrents

### Commandes state utiles (à connaître par cœur)
```bash
terraform state list                     # lister les ressources du state
terraform state show aws_instance.web    # voir le détail d'une ressource dans le state
terraform state mv                       # renommer/déplacer une ressource dans le state
terraform state rm                       # retirer une ressource du state (sans la détruire !)
terraform import aws_instance.web i-0123 # importer une ressource existante dans le state
```

---

## 5. Modules

Un module est un ensemble de fichiers `.tf` réutilisable avec des `variables` en entrée
et des `outputs` en sortie. Le dossier racine (`environments/dev`) est lui-même le
"module racine".

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}
```

**Bonnes pratiques modules :**
- Un module = une responsabilité claire (réseau, compute, base de données...)
- Ne jamais coder en dur une valeur qui doit varier entre environnements
- Versionner les modules (via un registry Git avec des tags `v1.0.0`) en production
- Toujours documenter les variables (`description`) et mettre des `default` raisonnables

---

## 6. Fichiers spéciaux et conventions de nommage

| Fichier | Rôle |
|---|---|
| `versions.tf` | Contraintes de version Terraform + providers (reproductibilité) |
| `backend.tf` | Configuration du backend distant |
| `providers.tf` | Configuration des providers (région, alias multi-région...) |
| `variables.tf` | Déclaration des variables d'entrée |
| `terraform.tfvars` | Valeurs des variables (souvent gitignore si sensible) |
| `main.tf` | Ressources principales |
| `outputs.tf` | Valeurs de sortie |
| `.gitignore` | Exclure `.terraform/`, `*.tfstate`, `*.tfvars` sensibles |

Pourquoi séparer variables/outputs/main dans des fichiers différents ? Terraform s'en fiche
techniquement (il lit tous les `.tf` d'un dossier), mais c'est une **convention pro**
qui rend le code lisible et navigable en équipe.

---

## 7. Cycle de vie / commandes Terraform (à maîtriser)

```bash
terraform init          # télécharge providers + modules, configure le backend
terraform fmt -recursive # formate le code selon les conventions HCL
terraform validate      # vérifie la syntaxe et la cohérence (hors-ligne)
terraform plan           # calcule le diff entre le state et le code (dry-run)
terraform apply          # applique les changements
terraform destroy        # détruit toute l'infra gérée par ce state
terraform output          # affiche les outputs
terraform graph          # génère un graphe des dépendances (DAG)
```

**Ordre d'exécution réel demandé en entretien :** `init → validate → plan → apply`.
Terraform construit un **graphe de dépendances (DAG)** à partir des références entre
ressources (`aws_subnet.id` utilisé dans `aws_instance` par ex.) pour paralléliser
la création quand c'est possible, et respecter l'ordre quand c'est nécessaire.

---

## 8. Gestion des secrets (souvent demandé)

Ne **jamais** mettre de secret en clair dans un `.tf` ou `.tfvars` versionné. Bonnes pratiques :
- Variables marquées `sensitive = true` (masque la valeur dans les logs `plan`/`apply`)
- Injection via variables d'environnement `TF_VAR_xxx`
- Récupération dynamique via `data` depuis un coffre-fort : AWS Secrets Manager,
  HashiCorp Vault, SSM Parameter Store
- `.gitignore` sur tout `*.tfvars` contenant des valeurs réelles

Voir l'exemple dans `modules/ec2/variables.tf` (variable `db_password` avec `sensitive = true`).

---

## 9. Environnements multiples : workspaces vs dossiers séparés

**Terraform Workspaces** (`terraform workspace new dev`) :
- Un seul code, plusieurs states (un par workspace), même backend
- Simple, mais risque d'erreur humaine (appliquer en prod en pensant être en dev)
- Pas de possibilité de différences structurelles fortes entre environnements

**Dossiers séparés** (utilisé dans ce projet) :
- Chaque environnement a son propre `main.tf`, ses variables, son propre backend
- Isolation maximale, plus explicite, plus sûr en entreprise
- Légèrement plus verbeux (mitigé par l'usage de modules communs)

→ En entretien : **la plupart des équipes pro utilisent des dossiers séparés + modules**
plutôt que les workspaces natifs, précisément pour la sécurité et la clarté.

---

## 10. Bonnes pratiques professionnelles (résumé pour l'entretien)

1. **Toujours** versionner Terraform et les providers (`required_version`, `required_providers`)
2. **Backend distant + state locking** (S3+DynamoDB, Azure Storage, Terraform Cloud...)
3. **Un state par environnement**, jamais un seul state partagé dev/prod
4. **Modules réutilisables**, sans valeurs en dur
5. **`terraform plan` systématique avant tout `apply`**, review en Pull Request (CI/CD)
6. **Ne jamais éditer le state à la main** — utiliser les commandes `terraform state`
7. **Secrets jamais en clair** dans le code ou versionnés
8. **`terraform fmt` + `terraform validate` + linter (tflint) + scanner de sécurité
   (checkov / tfsec)** intégrés en CI
9. **Tags cohérents** sur toutes les ressources (`Environment`, `Owner`, `ManagedBy=terraform`)
10. **Éviter les provisioners** (`local-exec`, `remote-exec`) sauf en dernier recours —
    préférer les images pré-configurées (Packer) ou un outil de configuration (Ansible)
11. **`prevent_destroy`** sur les ressources critiques (bases de données, buckets de logs)
12. **Nommage cohérent** : `<projet>-<environnement>-<ressource>` (ex: `myapp-prod-vpc`)
13. **Revue de code obligatoire** sur toute Pull Request modifiant du Terraform
14. **CI/CD** : `plan` automatique sur chaque PR, `apply` uniquement après validation manuelle

---

## 11. Pour aller plus loin (questions bonus d'entretien)

- **`terraform taint` / `-replace`** : force la recréation d'une ressource spécifique
- **`terraform refresh`** (intégré à `plan` depuis TF 0.15+) : resynchronise le state avec la réalité
- **Drift** : quand l'infra réelle diverge du state (modification manuelle dans la console AWS)
- **Remote state en lecture seule** (`terraform_remote_state` data source) : pour lire les
  outputs d'un autre state (ex: le module réseau) sans le gérer
- **Terraform Cloud / Terragrunt** : outils qui ajoutent orchestration, remote runs, DRY avancé

---

## 12. Comment utiliser ce projet

```bash
cd environments/dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

> Ce projet est fait pour être **lu et compris**, pas nécessairement déployé tel quel
> (il te faudrait un compte AWS + adapter les CIDR/AMI). Chaque fichier est commenté
> pour expliquer le "pourquoi", pas juste le "quoi".
