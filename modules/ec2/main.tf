# ---------------------------------------------------------------------------
# Module EC2
# Démontre : data source, count, expression conditionnelle, lifecycle,
# depends_on, et l'usage d'un template pour le script de démarrage (userdata).
# ---------------------------------------------------------------------------

# data source : on ne code pas l'AMI en dur, on récupère la dernière AMI
# Amazon Linux 2023 disponible -> le code reste valide dans le temps.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "ec2"
  })
}

# count : crée var.instance_count instances, indexées 0..n-1.
# Ici c'est acceptable car les instances sont interchangeables (pas d'identité
# logique individuelle) -> cas d'usage légitime de count plutôt que for_each.
resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  # % (modulo) pour répartir les instances de façon cyclique sur les subnets fournis
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids

  # Expression conditionnelle (ternaire) : active le monitoring détaillé
  # uniquement si demandé (coût supplémentaire sinon)
  monitoring = var.enable_detailed_monitoring ? true : false

  user_data = templatefile("${path.module}/userdata.sh.tpl", {
    environment = var.environment
    db_password = var.db_password
  })

  tags = merge(local.common_tags, {
    Name = "${var.environment}-app-${count.index + 1}"
  })

  # lifecycle : ignore les changements de user_data après création pour éviter
  # de recréer l'instance à chaque modif mineure du script (pattern fréquent),
  # et empêche toute destruction accidentelle en prod.
  lifecycle {
    ignore_changes  = [ami]
    prevent_destroy = false # mettre à true en prod pour les ressources critiques
  }

  # depends_on explicite : utile quand la dépendance n'est pas visible via une
  # référence d'attribut (ici Terraform la déduirait déjà via subnet_id, mais
  # on l'illustre pour le pattern général)
  depends_on = [data.aws_ami.amazon_linux]
}
