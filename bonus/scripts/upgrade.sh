#!/bin/sh

set -e

APP_PORT="${P3_PORT:-8888}"
SCRIPT_DIR="$(dirname "$0")"
SCRIPTS_DIR="$SCRIPT_DIR"

if [ -n "$1" ]; then
    REPO_NAME="$1"
else
    REPO_NAME=$(kubectl get application wil-app -n argocd -o jsonpath="{.spec.source.repoURL}" 2>/dev/null | grep -oP 'root/\K[^.]+')
    echo "Detected repo from ArgoCD: $REPO_NAME"
fi

echo "=== Updating image to v2 ==="
python3 "$SCRIPT_DIR/push-to-gitlab.py" "$REPO_NAME" "s|wil42/playground:v1|wil42/playground:v2|g" "upgrade"

echo "=== Refreshing ArgoCD ==="
"$SCRIPTS_DIR/argocd-refresh.sh"

echo "=== Waiting for rollout ==="
"$SCRIPTS_DIR/wait-rollout.sh"
sleep 2

echo "App updated: $(curl -s "http://localhost:$APP_PORT/")"
