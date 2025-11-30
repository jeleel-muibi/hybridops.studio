# —— Nornir showcase (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

VENV := .venv
REQ  := requirements.txt
TASK ?= example
INV  ?= inventories

.PHONY: help deps dry-run apply clean
help:
	@echo "Targets:"
	@echo "  deps        - create venv & install requirements"
	@echo "  dry-run     - run task in check mode"
	@echo "  apply       - run task applying changes"
	@echo "  clean       - remove venv"
	@echo "Vars: TASK=$(TASK)  INV=$(INV)"

deps:
	python3 -m venv $(VENV) || true
	. $(VENV)/bin/activate && pip install -q -r $(REQ)
	@echo "✔ deps ready"

dry-run: deps
	. $(VENV)/bin/activate && python src/runner.py --task $(TASK) --inventory $(INV) --dry-run

apply: deps
	. $(VENV)/bin/activate && python src/runner.py --task $(TASK) --inventory $(INV) --apply

clean:
	rm -rf $(VENV)
	@echo "✔ cleaned"
