#!/bin/sh

set -e

CLUSTER="${K3D_CLUSTER_BONUS:-inception-bonus}"
APP_PORT="${P3_PORT:-8888}"
GITLAB_PORT="${BONUS_GITLAB_PORT:-8080}"
ARGOCD_PORT="${BONUS_ARGOCD_PORT:-9090}"
GITLAB_PASS="Ex@mp3P4ssw0rd"
GITLAB_TOKEN="stamim-gitlab-token"
TOKEN_FILE=".gitlab-token"
SCRIPT_DIR="$(dirname "$0")"

if ! command -v kubectl > /dev/null 2>&1; then
    echo "kubectl not found, installing..."
    sudo apt install -y kubectl
fi

if ! command -v k3d > /dev/null 2>&1; then
    echo "k3d not found, installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "=== Creating K3d cluster ==="
k3d cluster create "$CLUSTER" \
    --port "$APP_PORT":80@loadbalancer

echo "Waiting for cluster networking..."
kubectl wait --namespace kube-system --for=condition=ready pod -l k8s-app=kube-dns --timeout=180s
kubectl wait --namespace kube-system --for=condition=ready pod -l app=local-path-provisioner --timeout=120s

echo "=== Installing Helm ==="
if ! command -v helm >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "=== Creating namespaces ==="
kubectl create namespace gitlab
kubectl create namespace argocd
kubectl create namespace dev

echo "=== Installing GitLab ==="
helm repo add gitlab https://charts.gitlab.io/
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
    --version 9.11.8 \
    --namespace gitlab \
    --wait \
    --timeout 15m \
    -f "$SCRIPT_DIR/../confs/gitlab-values.yaml"

echo "=== Waiting for GitLab to be fully ready ==="
# We only need webservice (web UI/API) and toolbox (rails runner for password/PAT).
# Other pods (gitaly, sidekiq, redis, postgresql, minio, etc.) are dependencies
# of the webservice — if they're not ready, webservice won't be ready either.
# So waiting for webservice implicitly ensures its deps are healthy.
kubectl wait --namespace gitlab --for=condition=ready pod -l app=webservice --timeout=300s
kubectl wait --namespace gitlab --for=condition=ready pod -l app=toolbox --timeout=300s

echo "=== Starting GitLab port-forward on port $GITLAB_PORT ==="
nohup kubectl port-forward -n gitlab svc/gitlab-webservice-default "$GITLAB_PORT":8181 > /dev/null 2>&1 &
sleep 3
echo "GitLab: http://localhost:$GITLAB_PORT"

echo "=== Setting root password and creating PAT ==="
TOOLBOX=$(kubectl get pod -n gitlab -l app=toolbox -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n gitlab "$TOOLBOX" -c toolbox -- bash -c \
    "cd /srv/gitlab && bundle exec rails runner \"u = User.find_by_username('root'); u.password = '$GITLAB_PASS'; u.password_confirmation = '$GITLAB_PASS'; u.save!; puts 'password set'\"" 2>&1 | grep -v "^Defaulted"

kubectl exec -n gitlab "$TOOLBOX" -c toolbox -- bash -c \
    "cd /srv/gitlab && bundle exec rails runner \"u = User.find_by_username('root'); t = u.personal_access_tokens.create!(name: 'setup-token', scopes: [:api, :read_repository, :write_repository], expires_at: 30.days.from_now); t.set_token('$GITLAB_TOKEN'); t.save!; puts t.token\"" 2>&1 | grep -v "^Defaulted" > "$TOKEN_FILE"

echo "GitLab token saved to $TOKEN_FILE"

echo "=== Installing ArgoCD ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.14.0/manifests/install.yaml
kubectl wait --namespace argocd --for=create pod --selector=app.kubernetes.io/name=argocd-server --timeout=30s
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s

ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "=== Starting ArgoCD port-forward on port $ARGOCD_PORT ==="
nohup kubectl port-forward -n argocd svc/argocd-server "$ARGOCD_PORT":443 > /dev/null 2>&1 &
sleep 2
echo "ArgoCD: https://localhost:$ARGOCD_PORT"
echo "ArgoCD password: $ARGOCD_PWD"

echo ""
echo "=== Setup complete ==="
echo "GitLab:  http://localhost:$GITLAB_PORT (root / $GITLAB_PASS)"
echo "ArgoCD:  https://localhost:$ARGOCD_PORT (admin / $ARGOCD_PWD)"
echo ""
echo "Next: run 'make bonus-create-repo' to create a GitLab repo and deploy the app"
