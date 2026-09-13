TEST_DIRS := $(sort $(patsubst %/,%,$(filter-out common/ dump/,$(wildcard */))))

.PHONY: run compare clean

# The sub-makes run with --no-print-directory, so the name printed here is the
# only thing tying a line of output to the test that produced it -- common.mk
# reports its diff verdict without naming the test.
#
# Every target keeps going after a failing directory and fails at the end, so
# one broken test still leaves a full picture of the suite.
run compare clean:
	@fail=0; for d in $(TEST_DIRS); do \
		printf '== %s\n' $$d; \
		$(MAKE) --no-print-directory -C $$d $@ || fail=1; \
	done; exit $$fail
