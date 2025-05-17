global last_key

%include "constants.inc"
%include "game_layout.inc"

; src/logic/entity.asm
extern create_player
extern get_entity

section .bss
    global entities
    global entity_count

    entities resb MAX_ENTITIES * ENTITY_SIZE
    entity_count resb 1

    last_key resb 1

section .text
    global init_game_state

init_game_state:

    mov qword rax, BOARD_WIDTH 
    inc rax
    shr rax, 1
    mov rsi, rax

    mov qword rax, BOARD_HEIGHT 
    inc rax
    shr rax, 1
    mov rdx, rax

    call create_player
    mov qword [rel last_key], 0 
    ret
 
; Inputs: RDI = index, al = new_x, dl = new_y
; Output: RSI = pointer to entity[RDI]
; Clobbers: CL
change_entity_position:
    mov rax, rdi
    call get_entity
   
    mov cl, [rsi + ENTITY_X] ; update last X to current X
    mov [rsi + ENTITY_LAST_X], cl 
    
    mov cl, [rsi + ENTITY_Y] ; update last Y to current Y
    mov [rsi + ENTITY_LAST_Y], cl 

    mov [rsi + ENTITY_X], al 
    mov [rsi+ ENTITY_Y], dl
    ret


