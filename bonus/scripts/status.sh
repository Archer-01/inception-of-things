#!/bin/sh

APP_PORT="${P3_PORT:-8888}"
GITLAB_PORT="${BONUS_GITLAB_PORT:-8080}"
ARGOCD_PORT="${BONUS_ARGOCD_PORT:-9090}"

echo "=== Namespaces ==="
kubectl get ns gitlab argocd dev --no-headers 2>/dev/null || echo "No namespaces found"

echo ""
echo "=== GitLab Pods ==="
kubectl get pods -n gitlab --no-headers 2>/dev/null | head -20 || echo "No gitlab pods"

echo ""
echo "=== ArgoCD Pods ==="
kubectl get pods -n argocd --no-headers 2>/dev/null || echo "No argocd pods"

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
curl -s "http://localhost:$APP_PORT/" 2>/dev/null || echo "App not reachable on localhost:$APP_PORT"

echo ""
echo "=== GitLab ==="
curl -sf -o /dev/null -u "root:Ex@mp3P4ssw0rd" "http://localhost:$GITLAB_PORT/api/v4/user" 2>/dev/null && echo "GitLab accessible on localhost:$GITLAB_PORT" || echo "GitLab not accessible on localhost:$GITLAB_PORT"

echo ""
echo "=== ArgoCD ==="
curl -sk "https://localhost:$ARGOCD_PORT/healthz" 2>/dev/null && echo " (accessible)" || echo "ArgoCD not accessible on localhost:$ARGOCD_PORT"
