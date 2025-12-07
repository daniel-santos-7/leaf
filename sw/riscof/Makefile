PYTHON   = python3
VENV_DIR = venv
PIP      = ./$(VENV_DIR)/bin/pip
RISCOF   = ./$(VENV_DIR)/bin/riscof

$(VENV_DIR): 
	$(PYTHON) -m venv $(VENV_DIR)
	$(PIP) install riscof

riscv-arch-test: $(VENV_DIR)
	$(RISCOF) --verbose info arch-test --clone

validateyaml: $(VENV_DIR) config.ini
	$(RISCOF) validateyaml --config=config.ini

testlist: $(VENV_DIR) riscv-arch-test config.ini
	$(RISCOF) testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

run: $(VENV_DIR) riscv-arch-test config.ini
	$(RISCOF) run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env --no-browser

clean:
	rm -rf $(VENV_DIR)