P3_DIR = p3
K3D_CLUSTER = inception
P3_PORT ?= 8888
P3_PORT2 ?= 8080

.PHONY: p3 p3-status p3-creds p3-destroy p3-argocd-status p3-argocd-refresh p3-wait-rollout p3-upgrade

p3:
	$(P3_DIR)/scripts/setup.sh

p3-argocd-status:
	$(P3_DIR)/scripts/argocd-status.sh

p3-argocd-refresh:
	$(P3_DIR)/scripts/argocd-refresh.sh

p3-wait-rollout:
	$(P3_DIR)/scripts/wait-rollout.sh

p3-status:
	$(P3_DIR)/scripts/status.sh

p3-destroy:
	-$(P3_DIR)/scripts/destroy.sh

p3-upgrade:
	$(P3_DIR)/scripts/upgrade.sh

p3-creds:
	$(P3_DIR)/scripts/creds.sh
