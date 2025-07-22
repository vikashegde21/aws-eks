#!/bin/bash

echo "=== AWS EKS Setup Script ==="

# Set AWS region
export AWS_DEFAULT_REGION=ap-south-1

# Check if AWS CLI is configured
echo "Checking AWS configuration..."
aws sts get-caller-identity || {
    echo "Please configure AWS CLI first: aws configure"
    exit 1
}

# Initialize and apply Terraform
echo "=== Setting up infrastructure with Terraform ==="
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# Update kubeconfig
echo "=== Updating kubeconfig ==="
aws eks update-kubeconfig --region ap-south-1 --name twapp

# Verify cluster connection
echo "=== Verifying cluster connection ==="
kubectl cluster-info
kubectl get nodes

# Add Helm repositories
echo "=== Setting up Helm repositories ==="
helm repo add eks https://aws.github.io/eks-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install AWS Load Balancer Controller

echo "=== Installing AWS Load Balancer Controller ==="
# Apply CRDs from the official repo
kubectl apply -f https://github.com/aws/eks-charts/raw/master/stable/aws-load-balancer-controller/crds/crds.yaml

# Get the role ARN from Terraform output
ALB_ROLE_ARN=$(cd terraform && terraform output -raw aws_load_balancer_controller_role_arn)

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=twapp \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ALB_ROLE_ARN \
  --set region=ap-south-1 \
  --set vpcId=$(cd terraform && terraform output -raw vpc_id)

# Wait for ALB controller to be ready
echo "=== Waiting for AWS Load Balancer Controller to be ready ==="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s

echo "=== Infrastructure setup complete! ==="