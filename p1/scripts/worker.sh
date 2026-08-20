#!/bin/sh

## Worker provision
echo ">> Installing k3s..."

NODE_TOKEN="$(cat /vagrant/node-token)"
echo "NODE_TOKEN: $NODE_TOKEN"

K3S_URL="https://192.168.56.110:6443"
echo "K3S_URL: $K3S_URL"

echo ">> Installing k3s..."

if [ ! -f /usr/local/bin/k3s  ]; then
	curl -sfL 'https://get.k3s.io' | K3S_KUBECONFIG_MODE="0644" K3S_TOKEN="$NODE_TOKEN" K3S_URL="$K3S_URL" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -
fi

echo ">> Setting up kubeconfig for kubectl access..."

# # Copy the kubeconfig from the server (shared via /vagrant)
mkdir -p /home/vagrant/.kube
cp /vagrant/k3s.yaml /home/vagrant/.kube/config

# # Replace localhost with the actual server IP
sed -i 's/127.0.0.1/192.168.56.110/g' /home/vagrant/.kube/config
sed -i 's/localhost/192.168.56.110/g' /home/vagrant/.kube/config

# # Set proper permissions
chmod 660 /home/vagrant/.kube/config

# echo ">> Waiting for k3s to be ready..."

# until kubectl get ns default >/dev/null 2>&1; do
# 	sleep 1
# done