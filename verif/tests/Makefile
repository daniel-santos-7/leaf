TEST_DIRS := $(sort $(patsubst %/,%,$(filter-out common/,$(wildcard */))))

.PHONY: list run compare clean $(TEST_DIRS)

list:
	@printf '%s\n' $(TEST_DIRS)

run: $(addprefix run-,$(TEST_DIRS))

compare: $(addprefix compare-,$(TEST_DIRS))

clean: $(addprefix clean-,$(TEST_DIRS))

$(TEST_DIRS):
	@$(MAKE) -C $@ run

run-%:
	@$(MAKE) -C $* run

compare-%:
	@$(MAKE) -C $* compare

clean-%:
	@$(MAKE) -C $* clean
