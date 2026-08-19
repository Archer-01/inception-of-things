#!/bin/sh

set -e

GITLAB_PORT="${BONUS_GITLAB_PORT:-8080}"
TOKEN_FILE=".gitlab-token"
REPO_NAME="${1:-stamim-config}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFS_DIR="$SCRIPT_DIR/../confs"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: $TOKEN_FILE not found. Run 'make bonus' first."
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")
API="http://localhost:$GITLAB_PORT/api/v4"

echo "=== Waiting for GitLab API ==="
until curl -sf -o /dev/null -H "PRIVATE-TOKEN: $TOKEN" "$API/user" 2>/dev/null; do
    echo "Waiting for GitLab API..."
    sleep 5
done

echo "=== Creating GitLab project: $REPO_NAME ==="
curl -sf -X POST "$API/projects" \
    -H "PRIVATE-TOKEN: $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$REPO_NAME\", \"visibility\": \"public\"}" > /dev/null 2>&1 || echo "Project may already exist"

echo "=== Pushing config to GitLab ==="
python3 "$SCRIPT_DIR/push-to-gitlab.py" "$REPO_NAME"

echo "=== Configuring ArgoCD repo ==="
ARGOCD_PORT="${BONUS_ARGOCD_PORT:-9090}"
ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

ARGOCD_SESSION=$(curl -sk -X POST "https://localhost:$ARGOCD_PORT/api/v1/session" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"admin\",\"password\":\"$ARGOCD_PWD\"}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

if [ -n "$ARGOCD_SESSION" ]; then
    curl -sk -X POST "https://localhost:$ARGOCD_PORT/api/v1/repositories" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ARGOCD_SESSION" \
        -d "{
            \"repo\": \"http://gitlab-webservice-default.gitlab.svc.cluster.local/root/${REPO_NAME}.git\",
            \"username\": \"oauth2\",
            \"password\": \"$TOKEN\",
            \"insecure\": true
        }" > /dev/null 2>&1 || echo "Repo may already be configured"
else
    echo "Warning: Could not login to ArgoCD. Repo may need manual configuration."
fi

echo "=== Deploying application via ArgoCD ==="
# Note: ArgoCD watches only one repo at a time. Applying this manifest
# switches ArgoCD to the new repo — any previous repo is no longer watched.
# Upgrade/downgrade will auto-detect the current repo from ArgoCD.
TMP_APP=$(mktemp)
sed "s|stamim-config.git|${REPO_NAME}.git|g" "$CONFS_DIR/application.yaml" > "$TMP_APP"
kubectl apply -f "$TMP_APP"
rm -f "$TMP_APP"
echo "Waiting for ArgoCD to sync..."
sleep 10
kubectl wait --namespace dev --for=create pod --selector=app=wil-playground --timeout=120s
kubectl wait --namespace dev --for=condition=ready pod --selector=app=wil-playground --timeout=120s

echo "=== Applying Ingress ==="
kubectl apply -f "$CONFS_DIR/ingress.yaml"

APP_PORT="${P3_PORT:-8888}"
echo "Waiting for app to become healthy..."
until curl -sf "http://localhost:$APP_PORT/" > /dev/null 2>&1; do sleep 2; done
echo "App is healthy: $(curl -s "http://localhost:$APP_PORT/")"
