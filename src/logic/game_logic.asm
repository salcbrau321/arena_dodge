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

global update_player

%include "constants.inc"
%include "game_layout.inc"

extern player_x
extern player_y
extern last_key

;--------------------------------------------------------
; update_player 
;   inputs: al = key code (ASCII or KEY_*)
;   outputs: updates [player_x], [player_y] 
;   clobbers:  rax, rdi, rsi, rdx
;--------------------------------------------------------
update_player:
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
    mov rax, [rel player_x]
    cmp rax, 1
    jle .ret
    dec rax
    mov [rel player_x], rax
    ret

.do_right:
    mov rax, [rel player_x]
    cmp rax, BOARD_WIDTH 
    jge .ret
    inc rax
    mov [rel player_x], rax
    ret

.do_up:
    mov rax, [rel player_y]
    cmp rax, 1 
    jle .ret
    dec rax
    mov [rel player_y], rax
    ret

.do_down:
    mov rax, [rel player_y]
    cmp rax, BOARD_HEIGHT 
    jge .ret
    inc rax
    mov [rel player_y], rax
    ret

.ret:
    ret
