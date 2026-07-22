#!/bin/sh
kubectl annotate application wil-app -n argocd argocd.argoproj.io/refresh=hard --overwrite
