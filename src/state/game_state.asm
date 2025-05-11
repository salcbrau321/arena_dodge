global player_x
global player_y
global last_key
global init_game_state

%include "constants.inc"
%include "game_layout.inc"

section .bss
    entities: resb MAX_ENTITIES * ENTITY_SIZE
    player_x resq 1
    player_y resq 1
    last_key resb 1

section .text

init_game_state:
    mov qword rax, BOARD_WIDTH 
    inc rax
    shr rax, 1
    mov [rel player_x], rax

    mov qword rax, BOARD_HEIGHT 
    inc rax
    shr rax, 1
    mov [rel player_y], rax

    mov qword [rel last_key], 0 
    ret
 
; Output: RSI = pointer to entity[RDI]
get_player:
    lea rsi, [rel entities]
    ret

; Inputs: RDI = index
; Output: RSI = pointer to entity[RDI]
get_entity:
    imul rdi, ENTITY_SIZE
    lea rsi, [rel entities + rdi]
    ret

; Inputs: RDI = index, al = new_x, dl = new_y
; Output: RSI = pointer to entity[RDI]
; Clobbers: CL
change_entity_position:
    call get_entity
   
    mov cl, [rsi + ENTITY_X] ; update last X to current X
    mov [rsi + ENTITY_LAST_X], cl 
    
    mov cl, [rsi + ENTITY_Y] ; update last Y to current Y
    mov [rsi + ENTITY_LAST_Y], cl 

    mov [rsi + ENTITY_X], al 
    mov [rsi+ ENTITY_Y], dl
    ret


