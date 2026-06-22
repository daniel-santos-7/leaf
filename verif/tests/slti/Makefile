DUMP_SIZE = 5376
include ../common/common.mk

# override build rules to exclude common.S (store_regs causes Spike +signature corruption)
$(APP_OUT).spike.elf: $(APP_SRC) $(COMMON_DIR)/spike.S $(COMMON_DIR)/spike.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T $(COMMON_DIR)/spike.ld $(APP_SRC) $(COMMON_DIR)/spike.S -o $@

$(APP_OUT).leaf.elf: $(APP_SRC) $(COMMON_DIR)/leaf.S $(COMMON_DIR)/leaf.ld
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -T $(COMMON_DIR)/leaf.ld $(APP_SRC) $(COMMON_DIR)/leaf.S -o $@
