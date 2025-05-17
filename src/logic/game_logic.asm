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
    global update_player

;--------------------------------------------------------
; update_player 
;   inputs: al = key code (ASCII or KEY_*)
;   outputs: updates [player_x], [player_y] 
;   clobbers:  rax, rdi, rsi, rdx
;--------------------------------------------------------
update_player:
    mov rax, 0
    call get_entity

    cmp al, KEY_LEFT
    je .do_left
    cmp al, KEY_RIGHT
    je .do_right
    cmp al, KEY_UP
    je .do_up
    cmp al, KEY_DOWN
    je .do_down
    ret

.do_left:
    mov rax, [rdi + ENTITY_X]
    cmp rax, 1
    jle .ret
    dec rax
    mov [rdi + ENTITY_X], rax
    ret

.do_right:
    mov rax, [rdi + ENTITY_X]
    cmp rax, BOARD_WIDTH 
    jge .ret
    inc rax
    mov [rdi + ENTITY_X], rax
    ret

.do_up:
    mov rax, [rdi + ENTITY_Y]
    cmp rax, 1 
    jle .ret
    dec rax
    mov [rdi + ENTITY_Y], rax
    ret

.do_down:
    mov rax, [rdi + ENTITY_Y]
    cmp rax, BOARD_HEIGHT 
    jge .ret
    inc rax
    mov [rdi + ENTITY_Y], rax
    ret

.ret:
    ret
