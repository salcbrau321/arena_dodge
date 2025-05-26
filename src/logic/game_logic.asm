;=============================================================================
; author: Braulio Salcedo 
; date: 2025-05-04
; 
; description:
;   contains logic to track state, handle game events, etc. 
;
; build:
;   nasm -f elf64 -o build/game_logic.o src/game_logic.asm
;   ld -o arena_dodge build/*.o
;=============================================================================

; src/logic/entity.asm
extern get_entity

%include "constants.inc"
%include "game_layout.inc"

section .text

