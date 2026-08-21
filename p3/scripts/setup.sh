#!/bin/sh

set -e

CLUSTER="${K3D_CLUSTER:-inception}"
PORT="${P3_PORT:-8888}"
ARGOCD_PORT="${P3_PORT2:-8080}"

if ! command -v kubectl > /dev/null 2>&1; then
    echo "kubectl not found, installing..."
    sudo apt install -y kubectl
fi

if ! command -v k3d > /dev/null 2>&1; then
    echo "k3d not found, installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "Running p3 directly on host (requires Docker + k3d)"
# Port mapping: host:8888 -> Docker -> loadbalancer:80 -> Traefik -> Ingress -> Service -> Pod
# Required: the subject mandates showing the Ingress works, which needs traffic to go through Traefik
k3d cluster create "$CLUSTER" \
    --port "$PORT":80@loadbalancer

echo "Waiting for cluster networking..."
kubectl wait --namespace kube-system --for=condition=ready pod -l k8s-app=kube-dns --timeout=180s
kubectl wait --namespace kube-system --for=condition=ready pod -l app=local-path-provisioner --timeout=120s

kubectl create namespace argocd
kubectl create namespace dev

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.14.0/manifests/install.yaml
kubectl wait --namespace argocd --for=create pod --selector=app.kubernetes.io/name=argocd-server --timeout=30s
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s

kubectl apply -f p3/confs/application.yaml
kubectl wait --namespace dev --for=create pod --selector=app=wil-playground --timeout=120s
kubectl wait --namespace dev --for=condition=ready pod --selector=app=wil-playground --timeout=120s

kubectl apply -f p3/confs/ingress.yaml

echo "Waiting for app to become healthy..."
until curl -sf "http://localhost:$PORT/" > /dev/null 2>&1; do sleep 2; done
echo "App is healthy: $(curl -s "http://localhost:$PORT/")"

echo "Starting Argo CD port-forward on port $ARGOCD_PORT..."
# Port-forward: host:8080 -> kubectl -> argocd-server:443 (direct tunnel, bypasses Traefik)
# Used because Argo CD has its own TLS server, no Ingress requirement from subject
# The argocd-server Service is declared inside the install.yaml manifest we apply above
# Could use Traefik Ingress instead, but would require TLS passthrough config which is unnecessarily complex
nohup kubectl port-forward -n argocd svc/argocd-server "$ARGOCD_PORT":443 > /dev/null 2>&1 &
sleep 2
echo "Argo CD: https://localhost:$ARGOCD_PORT"
