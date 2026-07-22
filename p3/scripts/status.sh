#!/bin/sh

PORT="${P3_PORT:-8888}"
ARGOCD_PORT="${P3_PORT2:-8080}"

echo "=== Namespaces ==="
kubectl get ns argocd dev --no-headers 2>/dev/null || echo "No argocd/dev namespaces found"

echo ""
echo "=== ArgoCD Pods ==="
kubectl get pods -n argocd --no-headers 2>/dev/null || echo "No argocd pods"

echo ""
echo "=== ArgoCD Services ==="
kubectl get svc -n argocd --no-headers 2>/dev/null || echo "No argocd services"

echo ""
echo "=== Dev Pods ==="
kubectl get pods -n dev --no-headers 2>/dev/null || echo "No dev pods"

echo ""
echo "=== Dev Services ==="
kubectl get svc -n dev --no-headers 2>/dev/null || echo "No dev services"

echo ""
echo "=== Ingress ==="
kubectl get ingress -n dev --no-headers 2>/dev/null || echo "No ingress in dev"

echo ""
echo "=== ArgoCD Application ==="
kubectl get applications -n argocd --no-headers 2>/dev/null || echo "No ArgoCD applications"

echo ""
echo "=== App ==="
curl -s "http://localhost:$PORT/" 2>/dev/null || echo "App not reachable on localhost:$PORT"

echo ""
echo "=== ArgoCD ==="
curl -sk "https://localhost:$ARGOCD_PORT/healthz" 2>/dev/null && echo " (accessible)" || echo "Argo CD not accessible on localhost:$ARGOCD_PORT"
