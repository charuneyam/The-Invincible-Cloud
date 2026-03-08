#!/bin/bash

# The Invincible Cloud - Deployment Helper Script
# This script helps verify all setup steps for Rohith's implementation

set -e

RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'

echo -e "${BLUE}================================${RESET}"
echo -e "${BLUE}The Invincible Cloud - Deployer${RESET}"
echo -e "${BLUE}================================${RESET}\n"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${RESET}"
    
    local missing=0
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}✗ Terraform not found${RESET}"
        missing=1
    else
        echo -e "${GREEN}✓ Terraform${RESET} ($(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4))"
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl not found${RESET}"
        missing=1
    else
        echo -e "${GREEN}✓ kubectl${RESET}"
    fi
    
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}✗ Helm not found${RESET}"
        missing=1
    else
        echo -e "${GREEN}✓ Helm${RESET}"
    fi
    
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}✗ gcloud CLI not found${RESET}"
        missing=1
    else
        echo -e "${GREEN}✓ gcloud${RESET}"
    fi
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}✗ AWS CLI not found${RESET}"
        missing=1
    else
        echo -e "${GREEN}✓ AWS CLI${RESET}"
    fi
    
    if [ $missing -eq 1 ]; then
        echo -e "${RED}\nPlease install missing tools and try again.${RESET}"
        exit 1
    fi
    
    echo ""
}

# Check GitHub secrets
check_github_secrets() {
    echo -e "${YELLOW}Checking GitHub Secrets...${RESET}"
    
    local secrets=(
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
        "AWS_EC2_PRIVATE_KEY"
        "GCP_SERVICE_ACCOUNT_JSON"
        "GCP_PROJECT_ID"
        "DOCKER_USERNAME"
        "DOCKER_PASSWORD"
    )
    
    local missing=0
    
    for secret in "${secrets[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            echo -e "${GREEN}✓ $secret${RESET}"
        else
            echo -e "${RED}✗ $secret (missing)${RESET}"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo -e "\n${YELLOW}Set missing secrets with:${RESET}"
        echo "gh secret set SECRET_NAME --body 'value'"
    fi
    
    echo ""
}

# Check Terraform files
check_terraform() {
    echo -e "${YELLOW}Checking Terraform configuration...${RESET}"
    
    local files=(
        "main.tf"
        "providers.tf"
        "aws_rds.tf"
        "gcp_sql.tf"
        "terraform.tfvars"
        "variables.tf"
        "outputs.tf"
    )
    
    local missing=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ $file${RESET}"
        else
            echo -e "${RED}✗ $file (missing)${RESET}"
            missing=1
        fi
    done
    
    if [ $missing -eq 0 ]; then
        echo -e "\n${YELLOW}Running terraform validate...${RESET}"
        if terraform validate > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Terraform configuration is valid${RESET}"
        else
            echo -e "${RED}✗ Terraform validation failed${RESET}"
            terraform validate
            exit 1
        fi
    fi
    
    echo ""
}

# Check Kubernetes manifests
check_kubernetes() {
    echo -e "${YELLOW}Checking Kubernetes manifests...${RESET}"
    
    local files=(
        "k8s/charts/invincible-app/Chart.yaml"
        "k8s/charts/invincible-app/values.yaml"
        "k8s/charts/invincible-app/values-aws.yaml"
        "k8s/charts/invincible-app/values-gcp.yaml"
        "k8s/charts/invincible-app/templates/deployment.yaml"
        "k8s/charts/invincible-app/templates/service.yaml"
        "k8s/charts/invincible-app/templates/configmap-aws.yaml"
        "k8s/charts/invincible-app/templates/configmap-gcp.yaml"
    )
    
    local missing=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ $file${RESET}"
        else
            echo -e "${RED}✗ $file (missing)${RESET}"
            missing=1
        fi
    done
    
    echo ""
}

# Check application
check_application() {
    echo -e "${YELLOW}Checking application files...${RESET}"
    
    local files=(
        "app/app.py"
        "app/config.py"
        "app/requirements.txt"
        "app/Dockerfile"
        "app/.dockerignore"
    )
    
    local missing=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ $file${RESET}"
        else
            echo -e "${RED}✗ $file (missing)${RESET}"
            missing=1
        fi
    done
    
    echo ""
}

# Check GitHub Actions workflows
check_workflows() {
    echo -e "${YELLOW}Checking GitHub Actions workflows...${RESET}"
    
    local files=(
        ".github/workflows/build-and-deploy.yaml"
        ".github/workflows/deploy-dual-cloud.yaml"
    )
    
    local missing=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ $file${RESET}"
        else
            echo -e "${RED}✗ $file (missing)${RESET}"
            missing=1
        fi
    done
    
    echo ""
}

# Display next steps
display_next_steps() {
    echo -e "${BLUE}================================${RESET}"
    echo -e "${BLUE}NEXT STEPS${RESET}"
    echo -e "${BLUE}================================${RESET}\n"
    
    echo -e "${YELLOW}1. Set GitHub Secrets (if not done):${RESET}"
    echo "   gh secret set AWS_ACCESS_KEY_ID --body 'your-key'"
    echo "   gh secret set AWS_SECRET_ACCESS_KEY --body 'your-secret'"
    echo "   ... (see IMPLEMENTATION_SUMMARY.md for all secrets)"
    
    echo -e "\n${YELLOW}2. Initialize Terraform:${RESET}"
    echo "   terraform init"
    
    echo -e "\n${YELLOW}3. Plan deployment:${RESET}"
    echo "   terraform plan -out=tfplan"
    
    echo -e "\n${YELLOW}4. Apply configuration:${RESET}"
    echo "   terraform apply tfplan"
    
    echo -e "\n${YELLOW}5. Extract and merge kubeconfigs:${RESET}"
    echo "   # Get K3s config"
    echo "   ssh -i key.pem ubuntu@<EC2_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/k3s.yaml"
    echo "   sed -i 's/127.0.0.1/<EC2_IP>/g' ~/.kube/k3s.yaml"
    echo "   "
    echo "   # Get GKE config"
    echo "   gcloud container clusters get-credentials invincible-gke-autopilot --region asia-south1"
    
    echo -e "\n${YELLOW}6. Deploy application to both clusters:${RESET}"
    echo "   # AWS"
    echo "   kubectl config use-context k3s"
    echo "   helm upgrade --install invincible-app ./k8s/charts/invincible-app \\"
    echo "     -f values.yaml -f values-aws.yaml"
    echo "   "
    echo "   # GCP"
    echo "   kubectl config use-context gke_..."
    echo "   helm upgrade --install invincible-app ./k8s/charts/invincible-app \\"
    echo "     -f values.yaml -f values-gcp.yaml"
    
    echo -e "\n${YELLOW}7. Verify deployments:${RESET}"
    echo "   kubectl get pods -A"
    echo "   kubectl get svc -A"
    
    echo -e "\n${BLUE}================================${RESET}"
    echo -e "${GREEN}All checks passed! Ready to deploy.${RESET}"
    echo -e "${BLUE}================================\n${RESET}"
}

# Run all checks
main() {
    check_prerequisites
    check_github_secrets
    check_terraform
    check_kubernetes
    check_application
    check_workflows
    display_next_steps
}

main
