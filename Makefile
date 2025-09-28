# —— Makefile for development tasks ——

.PHONY: lint clean
lint:
	@pre-commit run --all-files -c .config/pre-commit-config.yaml

clean:
	@find . -type f -name '*.pyc' -delete
	@find . -type d -name '__pycache__' -delete
	@find . -type f -name '*~' -delete
	@find . -type f -name '.*.swp' -delete
	@find . -type f -name '.DS_Store' -delete
	@pre-commit clean
