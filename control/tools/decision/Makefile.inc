# Include from your root Makefile:
#   include control/decision/Makefile.inc

DECISION_OUT     ?= out/decision
DECISION_TS      := $(shell date -u +"%Y%m%dT%H%M%SZ")
DECISION_RUN_DIR := $(DECISION_OUT)/$(DECISION_TS)

.PHONY: decision.fetch decision.decide decision.execute decision.all

decision.fetch:
	@mkdir -p $(DECISION_RUN_DIR)
	@cd control/decision && ./fetch_signals.sh
	@cp -a control/decision/signals $(DECISION_RUN_DIR)/
	@ln -snf $(DECISION_RUN_DIR) $(DECISION_OUT)/latest
	@echo "[decision.fetch] signals captured -> $(DECISION_RUN_DIR)/signals"

decision.decide:
	@mkdir -p $(DECISION_RUN_DIR)
	@cd control/decision && ./choose_target.py --policy policy.json --metrics signals/metrics.json --credits signals/credits.env --out "$(PWD)/$(DECISION_RUN_DIR)/decision.json"
	@ln -snf $(DECISION_RUN_DIR) $(DECISION_OUT)/latest
	@echo "[decision.decide] decision -> $(DECISION_RUN_DIR)/decision.json"

decision.execute:
	@cd control/decision && ./run_action.sh "$(PWD)/$(DECISION_OUT)/latest/decision.json" "$(PWD)/$(DECISION_OUT)/latest"

decision.all: decision.fetch decision.decide decision.execute
