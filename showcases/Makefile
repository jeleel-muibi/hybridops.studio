SHELL := /bin/bash
ROOT ?= $(shell git rev-parse --show-toplevel 2>/dev/null || echo ../..)
INV  ?= $(ROOT)/deployment/inventories/dev/hosts.ini
DRVARS ?= $(ROOT)/showcases/hybrid-failover-migration-showcase/vars/dr.env.yml

EVIDENCE := $(ROOT)/showcases/hybrid-failover-migration-showcase/evidence

.PHONY: demo evidence clean

demo: ## Run DR demo end-to-end using deployment targets
	$(MAKE) -C $(ROOT) sanity env.setup
	# (Optional) pass scenario vars to specific playbooks if you wire them
	$(MAKE) -C $(ROOT) dr.db.promote
	$(MAKE) -C $(ROOT) dr.cluster.attach
	$(MAKE) -C $(ROOT) dr.gitops.sync
	$(MAKE) -C $(ROOT) dr.dns.cutover
	$(MAKE) evidence

evidence: ## Collect artifacts from out/ into this showcase folder
	mkdir -p $(EVIDENCE)
	# copy ansible run logs (adjust patterns as needed)
	cp -r $(ROOT)/out/artifacts/ansible-runs $(EVIDENCE)/ 2>/dev/null || true
	# copy any DR drill exports
	cp -r $(ROOT)/out/artifacts/dr-drills $(EVIDENCE)/ 2>/dev/null || true
	@echo "Evidence collected under $(EVIDENCE)"

clean:
	rm -rf $(EVIDENCE)
