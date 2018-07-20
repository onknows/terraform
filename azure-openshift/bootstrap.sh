#!/bin/bash
set -e

echo "Synchronizing Terraform state..."
terraform refresh -var-file=azure.tfvars -var-file=bootstrap.tfvars

echo "Planning Terraform changes..."
terraform plan -out openshift.plan -var-file=azure.tfvars -var-file=bootstrap.tfvars

echo "Deploying Terraform plan..."
terraform apply openshift.plan
