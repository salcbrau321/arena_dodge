# -------------------------------------------------------------------
# Tools and Flags
# -------------------------------------------------------------------
ASM             := nasm
ASMFLAGS_BASE   := -f elf64 -I src/ -I src/constants/ -I src/utils
LD              := ld

ASMFLAGS_DEBUG    := $(ASMFLAGS_BASE) -g -F dwarf
LDFLAGS_DEBUG     := -g

ASMFLAGS_RELEASE  := $(ASMFLAGS_BASE)
LDFLAGS_RELEASE   := -s

# -------------------------------------------------------------------
# Directory Structure
# -------------------------------------------------------------------
SRCDIR        := src
SRC           := $(shell find $(SRCDIR) -type f -name '*.asm')

BUILDDIR_DBG  := build/debug
BUILDDIR_REL  := build/release

BINDIR_DBG    := bin/debug
BINDIR_REL    := bin/release

OBJ_DBG       := $(patsubst $(SRCDIR)/%.asm,$(BUILDDIR_DBG)/%.o,$(SRC))
OBJ_REL       := $(patsubst $(SRCDIR)/%.asm,$(BUILDDIR_REL)/%.o,$(SRC))

TARGET_DBG    := $(BINDIR_DBG)/arena_dodge_cli
TARGET_REL    := $(BINDIR_REL)/arena_dodge_cli

# -------------------------------------------------------------------
# High‐level Targets
# -------------------------------------------------------------------
.PHONY: all debug release clean

all: debug

debug: $(TARGET_DBG)

release: $(TARGET_REL)

# -------------------------------------------------------------------
# Link Targets
# -------------------------------------------------------------------
$(TARGET_DBG): ASMFLAGS := $(ASMFLAGS_DEBUG)
$(TARGET_DBG): LDFLAGS  := $(LDFLAGS_DEBUG)
$(TARGET_DBG): $(OBJ_DBG) | $(BINDIR_DBG)
	$(LD) $(LDFLAGS) -o $@ $^

$(TARGET_REL): ASMFLAGS := $(ASMFLAGS_RELEASE)
$(TARGET_REL): LDFLAGS  := $(LDFLAGS_RELEASE)
$(TARGET_REL): $(OBJ_REL) | $(BINDIR_REL)
	$(LD) $(LDFLAGS) -o $@ $^

# -------------------------------------------------------------------
# Assemble Rules
# -------------------------------------------------------------------
# Debug objects
$(BUILDDIR_DBG)/%.o: $(SRCDIR)/%.asm | $(BUILDDIR_DBG)
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Release objects
$(BUILDDIR_REL)/%.o: $(SRCDIR)/%.asm | $(BUILDDIR_REL)
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) -o $@ $<

# -------------------------------------------------------------------
# Directory Creation
# -------------------------------------------------------------------
$(BUILDDIR_DBG):
	mkdir -p $(BUILDDIR_DBG)

$(BUILDDIR_REL):
	mkdir -p $(BUILDDIR_REL)

$(BINDIR_DBG):
	mkdir -p $(BINDIR_DBG)

$(BINDIR_REL):
	mkdir -p $(BINDIR_REL)

# -------------------------------------------------------------------
# Clean
# -------------------------------------------------------------------
clean:
	rm -rf build/debug build/release bin/debug bin/release


