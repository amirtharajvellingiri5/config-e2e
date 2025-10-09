#!/bin/bash
set -e

# -----------------------------
# Configurable variables
# -----------------------------
DOCKERHUB_TOKEN="<YOUR_DOCKERHUB_TOKEN>"
KEY_NAME="<YOUR_KEY_PAIR>"
ENVIRONMENT="dev"
DOCKERHUB_USER="vishnukanthmca"

# -----------------------------
# Navigate to infra directory
# -----------------------------
cd infra || { echo "infra directory not found"; exit 1; }

# -----------------------------
# Initialize Terraform
# -----------------------------
echo "Initializing Terraform..."
terraform init

# -----------------------------
# Terraform Plan
# -----------------------------
echo "Planning Terraform changes..."
terraform plan \
  -var="dockerhub_password=${DOCKERHUB_TOKEN}" \
  -var="key_name=${KEY_NAME}" \
  -var="environment=${ENVIRONMENT}" \
  -var="dockerhub_user=${DOCKERHUB_USER}"

# -----------------------------
# Terraform Apply
# -----------------------------
echo "Applying Terraform changes..."
terraform apply -auto-approve \
  -var="dockerhub_password=${DOCKERHUB_TOKEN}" \
  -var="key_name=${KEY_NAME}" \
  -var="environment=${ENVIRONMENT}" \
  -var="dockerhub_user=${DOCKERHUB_USER}"

# -----------------------------
# Show Outputs
# -----------------------------
echo "Fetching outputs..."
terraform output

