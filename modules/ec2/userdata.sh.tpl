#!/bin/bash
# Script de démarrage généré par templatefile()
# Les variables ${environment} et ${db_password} sont injectées par Terraform.
echo "Déploiement en environnement : ${environment}"
# NOTE pédagogique : en vrai, ne JAMAIS faire transiter un secret en clair
# dans le userdata (visible via l'API EC2). Utiliser Secrets Manager côté
# instance (aws secretsmanager get-secret-value) à la place.
export APP_ENV="${environment}"
