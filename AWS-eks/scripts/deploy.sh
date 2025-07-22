#!/bin/bash

echo "=== Deploying Travel Webapp ==="

# Apply Kubernetes manifests
echo "=== Applying Kubernetes manifests ==="
kubectl apply -f k8s-manifests/namespace.yaml
kubectl apply -f k8s-manifests/rbac.yaml
kubectl apply -f k8s-manifests/configmap.yaml
kubectl apply -f k8s-manifests/secret.yaml
kubectl apply -f k8s-manifests/deployment.yaml
kubectl apply -f k8s-manifests/service.yaml
kubectl apply -f k8s-manifests/ingress.yaml

# Wait for deployment to be ready
echo "=== Waiting for deployment to be ready ==="
kubectl wait --for=condition=available --timeout=300s deployment/travel-webapp -n travel-webapp

# Install Prometheus and Grafana
echo "=== Installing Prometheus and Grafana ==="
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f monitoring/prometheus-values.yaml

# Wait for Prometheus to be ready
echo "=== Waiting for Prometheus to be ready ==="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Get application URL
echo "=== Getting application URL ==="
echo "Waiting for ingress to get an address..."
sleep 30
INGRESS_URL=$(kubectl get ingress travel-webapp-ingress -n travel-webapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$INGRESS_URL"

# Get Grafana URL
GRAFANA_URL=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Grafana URL: http://$GRAFANA_URL (admin/admin123)"

echo "=== Deployment complete! ==="