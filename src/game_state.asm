global player_x
global player_y
global last_key
global init_game_state

%include "constants.inc"

section .bss
    player_x resq 1
    player_y resq 1
    last_key resb 1

section .text

init_game_state:
    mov qword rax, MAX_COLS
    inc rax
    shr rax, 1
    mov [rel player_x], rax

    mov qword rax, MAX_ROWS 
    inc rax
    shr rax, 1
    mov [rel player_y], rax

    mov qword [rel last_key], 0 
    ret
    
