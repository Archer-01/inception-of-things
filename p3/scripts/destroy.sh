#!/bin/sh

CLUSTER="${K3D_CLUSTER:-inception}"
k3d cluster delete "$CLUSTER"
