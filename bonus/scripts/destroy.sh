#!/bin/sh

CLUSTER="${K3D_CLUSTER_BONUS:-inception-bonus}"
k3d cluster delete "$CLUSTER"
