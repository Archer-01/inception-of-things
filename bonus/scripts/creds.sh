#!/bin/sh

echo "=== GitLab ==="
echo "URL:      http://localhost:${BONUS_GITLAB_PORT:-8080}"
echo "Username: root"
echo "Password: Ex@mp3P4ssw0rd"
echo -n "PAT:      "
cat ".gitlab-token" 2>/dev/null || echo "(not created yet)"

echo ""
echo "=== ArgoCD ==="
echo "URL:      https://localhost:${BONUS_ARGOCD_PORT:-9090}"
echo "Username: admin"
echo -n "Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
