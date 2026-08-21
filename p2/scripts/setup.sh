#!/bin/sh

if [ ! -f /usr/local/bin/k3s  ]; then
	curl -sfL 'https://get.k3s.io' | K3S_KUBECONFIG_MODE="0644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -
fi

until kubectl get ns default >/dev/null 2>&1; do
	sleep 1
done

for deployment in /vagrant/app*-deployment.yaml; do
	kubectl apply -f "$deployment"
done

for service in /vagrant/app*-service.yaml; do
	kubectl apply -f "$service"
done

kubectl apply -f "/vagrant/ingress.yaml"
