#!/bin/sh

# Server provision
echo ">> Installing k3s..."

if [ ! -f /usr/local/bin/k3s  ]; then
	curl -sfL 'https://get.k3s.io' | K3S_KUBECONFIG_MODE="0644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -
fi

echo ">> Waiting for k3s to be ready..."

until kubectl get ns default >/dev/null 2>&1; do
	sleep 1
done

NODE_TOKEN='/var/lib/rancher/k3s/server/node-token'
cp $NODE_TOKEN /vagrant/

cp /etc/rancher/k3s/k3s.yaml /vagrant/