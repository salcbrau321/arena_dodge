# -------------------------------------------------------------------
# Tools and Flags
# -------------------------------------------------------------------
ASM      := nasm
ASMFLAGS := -f elf64 -I src/ -I src/constants/ -I src/utils
LD       := ld
LDFLAGS  :=

# -------------------------------------------------------------------
# Directory Structure
# -------------------------------------------------------------------
SRCDIR   := src
BUILDDIR := build
BINDIR   := bin

# Recursively find all .asm files in src
SRC      := $(shell find $(SRCDIR) -name '*.asm')

# Convert source paths to build object paths
OBJ      := $(patsubst $(SRCDIR)/%.asm, $(BUILDDIR)/%.o, $(SRC))

# Final output binary
TARGET   := $(BINDIR)/arena_dodge_cli

# -------------------------------------------------------------------
# Build Targets
# -------------------------------------------------------------------
all: $(TARGET)

# Link object files into final binary
$(TARGET): $(OBJ) | $(BINDIR)
	$(LD) $(LDFLAGS) -o $@ $^

# Assemble: .asm -> .o, create output dir as needed
$(BUILDDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Create build/ and bin/ dirs if missing
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BINDIR):
	mkdir -p $(BINDIR)

# Clean target
clean:
	rm -rf $(BUILDDIR) $(BINDIR)

.PHONY: all clean

