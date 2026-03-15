#!/bin/sh

if [ -z "$1" ]; then
	>&2 echo "Missing argument: node_type (server|worker)"
	exit 1
fi

if [ ! -f "/vagrant/node-token" ]; then
	>&2 echo "vagrant/node-token not found"
	exit 1
fi

K3S_TOKEN="$(cat /vagrant/node-token)"
export K3S_TOKEN

if [ "$1" = "worker" ]; then
	export K3S_URL="https://192.168.56.110:6443"
fi

curl -sfL 'https://get.k3s.io' | sh -
