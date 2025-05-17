;=============================================================================
; File:    render_r8.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-17
; 
; Description:
;   Entry point and main game loop.  Sets up terminal, reads input,
;   updates r8, draws frame, and exits.
;
; Build:
;   nasm -f elf64 -o build/main.o src/main.asm
;   ld -o arena_dodge build/*.o
;=============================================================================

%include "constants.inc"
%include "utils.asm"

; src/state/game_state.asm 
extern entities
extern entity_count

; src/ui/terminal_io.asm
extern set_cursor

section .data
    space_char db ' '

section .text
    global render_r8

;--------------------------------------------------------
; render_entities 
;   description: renders all the r8 in the game 
;   clobbers: rcx, r8, rdx, rax 
;--------------------------------------------------------
render_entities:
    movzx rcx, byte [entity_count] 
    lea r8, [rel entities]

.render_loop:
    movzx edx, byte [r8 + ENTITY_X]
    movzx edi, byte [r8 + ENTITY_LAST_X]
    cmp edx, edi
    jne .render_entity

    movzx edx, byte [r8 + ENTITY_Y]
    movzx edi, byte [r8 + ENTITY_LAST_Y]
    cmp edx, edi
    jne .render_entity

.go_next_entity:
    add r8, ENTITY_SIZE
    dec rcx
    jnz .render_loop
    ret

.render_entity:
    movzx esi, byte [r8 + ENTITY_LAST_X]
    movzx edi, byte [r8 + ENTITY_LAST_Y]
    call set_cursor
    WRITE space_char, 1

    movzx esi, byte [r8 + ENTITY_X]
    movzx edi, byte [r8 + ENTITY_Y]
    call set_cursor
    WRITE r8 + ENTITY_GLYPH, 1
  
    movzx esi, byte [r8 + ENTITY_X]
    mov byte [r8 + ENTITY_LAST_X], sil
    movzx esi, byte [r8 + ENTITY_Y]
    mov byte [r8 + ENTITY_LAST_Y], sil
    
    jmp .go_next_entity
