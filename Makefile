# -------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------
ASM      := nasm
ASMFLAGS := -f elf64 -I src/ # output 64-bit ELF .o files
LD       := ld
LDFLAGS  :=

SRCDIR   := src
BUILDDIR := build
BINDIR   := bin

# Find all .asm files automatically
SRC      := $(wildcard $(SRCDIR)/*.asm)

# Turn src/foo.asm -> build/foo.o
OBJ      := $(patsubst $(SRCDIR)/%.asm, $(BUILDDIR)/%.o, $(SRC))

# Final output binary
TARGET   := $(BINDIR)/arena_dodge_cli

# -------------------------------------------------------------------
# Targets
# -------------------------------------------------------------------
all: $(TARGET)

# Link step: link all object files into final binary
$(TARGET): $(OBJ) | $(BINDIR)
	$(LD) $(LDFLAGS) -o $@ $^

# Assemble step: rule for building .o files from .asm files
$(BUILDDIR)/%.o: $(SRCDIR)/%.asm | $(BUILDDIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Create build/ and bin/ directories if missing
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BINDIR):
	mkdir -p $(BINDIR)

# Clean target: remove build artifacts
clean:
	rm -rf $(BUILDDIR) $(BINDIR)

.PHONY: all clean

