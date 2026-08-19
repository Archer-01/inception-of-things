P3_DIR = p3
BONUS_DIR = bonus
K3D_CLUSTER = inception
K3D_CLUSTER_BONUS = inception-bonus
P3_PORT ?= 8888
P3_PORT2 ?= 8080
BONUS_GITLAB_PORT ?= 8080
BONUS_ARGOCD_PORT ?= 9090

.PHONY: p3 p3-status p3-creds p3-destroy p3-argocd-status p3-argocd-refresh p3-wait-rollout p3-upgrade
.PHONY: bonus bonus-create-repo bonus-status bonus-creds bonus-destroy bonus-argocd-status bonus-argocd-refresh bonus-wait-rollout bonus-upgrade bonus-downgrade

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

bonus:
	$(BONUS_DIR)/scripts/setup.sh

bonus-create-repo:
	$(BONUS_DIR)/scripts/create-repo.sh $(REPO_NAME)

bonus-argocd-status:
	$(BONUS_DIR)/scripts/argocd-status.sh

bonus-argocd-refresh:
	$(BONUS_DIR)/scripts/argocd-refresh.sh

bonus-wait-rollout:
	$(BONUS_DIR)/scripts/wait-rollout.sh

bonus-status:
	$(BONUS_DIR)/scripts/status.sh

bonus-destroy:
	-$(BONUS_DIR)/scripts/destroy.sh

bonus-upgrade:
	$(BONUS_DIR)/scripts/upgrade.sh $(REPO_NAME)

bonus-downgrade:
	$(BONUS_DIR)/scripts/downgrade.sh $(REPO_NAME)

bonus-creds:
	$(BONUS_DIR)/scripts/creds.sh
