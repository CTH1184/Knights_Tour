# Variables
SIMULATOR = vsim
TEST_DIR = ./tests
WORK_DIR = work
FILES = $(wildcard $(TEST_DIR)/*.sv)
TARGETS = $(FILES:.sv=.out)

# Default target
all: $(WORK_DIR) $(TARGETS)

# Create work directory
$(WORK_DIR):
	vlib $(WORK_DIR)

# Compile and run each test
%.out: %.sv
	@echo "Running test: $<"
	vlog -work $(WORK_DIR) $< || { echo "Compilation failed for $<"; exit 1; }
	$(SIMULATOR) -c -do "run -all; quit" -work $(WORK_DIR) $(basename $(notdir $<)) || { echo "Simulation failed for $<"; exit 1; }
	@echo "Test $< completed successfully."

# Clean up
clean:
	rm -rf $(WORK_DIR) *.out

.PHONY: all clean
