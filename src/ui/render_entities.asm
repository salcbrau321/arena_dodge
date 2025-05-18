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

;=============================================================================
; EXTERNAL DATA
;=============================================================================

; src/state/game_state.asm 
extern entities
extern entity_count

; src/state/layout_state.asm
extern board_x_offset
extern board_y_offset

;=============================================================================
; EXTERNAL METHODS 
;=============================================================================

; src/ui/terminal_io.asm
extern set_cursor

section .data
    space_char db " "
    tw db "drwaing glyph", 10
    twLen equ $ - tw

section .text
    global render_entities
    global re_render_entities

;--------------------------------------------------------
; render_entities 
;   description: renders all the r8 in the game 
;   clobbers: r12, r8, rdx, rax 
;--------------------------------------------------------
render_entities:
    movzx r12, byte [entity_count] ; get the entity count (counter for our loop)
    lea r8, [rel entities] ; get references to entities buffer

.render_loop: ; loop through each entity in buffer
    movzx edx, byte [r8 + ENTITY_X] ; get current x
    movzx edi, byte [r8 + ENTITY_LAST_X] ; get last y
    cmp edx, edi ; if they are not equal, we need to render the entity
    jne .render_entity

    movzx edx, byte [r8 + ENTITY_Y] ; repeat process with Y
    movzx edi, byte [r8 + ENTITY_LAST_Y]
    cmp edx, edi
    jne .render_entity

.go_next_entity:
    add r8, ENTITY_SIZE ; increment the buffer reference by size of an entity
    dec r12 ; decrement our entity counter
    jnz .render_loop ; if it has not reached zero we continue rendering
    ret

.render_entity:
    movzx esi, byte [r8 + ENTITY_LAST_X] ; writes empty space to previous entity location 
    movzx ecx, word [rel board_x_offset]
    add esi, ecx ; add board offset to draw in proper position
    
    movzx edi, byte [r8 + ENTITY_LAST_Y]
    movzx ecx, word [rel board_y_offset]
    add edi, ecx
        
    call set_cursor
    WRITE space_char, 1

    movzx esi, byte [r8 + ENTITY_X] ; writes glyph to current entity location
    movzx ecx, word [rel board_x_offset]
    add esi, ecx ; add board offset to draw in proper position
    
    movzx edi, byte [r8 + ENTITY_Y]
    movzx ecx, word [rel board_y_offset]
    add edi, ecx
    
    call set_cursor
    WRITE r8 + ENTITY_GLYPH, 1
    
    movzx esi, byte [r8 + ENTITY_X] ; sets last X and Y to current X and Y to avoid further rendering
    mov byte [r8 + ENTITY_LAST_X], sil
    movzx esi, byte [r8 + ENTITY_Y]
    mov byte [r8 + ENTITY_LAST_Y], sil
    
    jmp .go_next_entity ; go to next entity after rendering


;--------------------------------------------------------
; re_render_entities 
;   description: renders all the r8 in the game 
;   clobbers: r12, r8, rdx, rax 
;--------------------------------------------------------
re_render_entities:
    movzx r12, byte [entity_count] ; get the entity count (counter for our loop)
    lea r8, [rel entities] ; get references to entities buffer

.re_render_loop: ; loop through each entity in buffer

.re_render_entity:
    movzx esi, byte [r8 + ENTITY_LAST_X] ; writes glyph to current entity location
    movzx ecx, word [rel board_x_offset]
    add esi, ecx ; add board offset to draw in proper position
    
    movzx edi, byte [r8 + ENTITY_LAST_Y]
    movzx ecx, word [rel board_y_offset]
    add edi, ecx
    
    call set_cursor
    WRITE r8 + ENTITY_GLYPH, 1
    
    add r8, ENTITY_SIZE ; increment the buffer reference by size of an entity
    dec r12 ; decrement our entity counter
    jnz .re_render_loop ; if it has not reached zero we continue rendering
    ret
