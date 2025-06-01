;=============================================================================
; File:    entity.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-15
; 
; Description:
;   Contains all the calls needed to work with entities in the game (creation, updating, removing, etc.)
;
; Build:
;   nasm -f elf64 -o build/logic/logic.o src/logic/entity.asm
;   ld -o arena_dodge build/logic/*.o
;=============================================================================

%include "constants.inc"
%include "game_layout.inc"
%include "utils.asm"
%include "directions.inc"

; state/game_state
extern entities
extern entity_count

section .data
    debugMsg db "Is In Right", 10
    debugLen equ $ - debugMsg 

    dir_to_move_func:
        dq mv_up
        dq mv_down
        dq mv_left
        dq mv_right

    dir_to_shoot_func:
        dq sht_up
        dq sht_down
        dq sht_left
        dq sht_right

section .text
    global create_entity
    global delete_entity
    global get_entity
    global create_player
    global create_mob
    global move_player 
    global shoot_projectile
    global update_entities

;--------------------------------------------------------
; create_entity 
;   description: creates an entity in the next open slot in the entities buffer
;                based on the inputs provided
;   inputs: edi - type 
;           esi - x-position
;           edx - y-position
;   output: rax - operation status
;             -1  - out of space
;           >=0 - success (index entity was placed in) 
;   clobbers rax, rbx, rcx, rdi, rsi, rdx   
;--------------------------------------------------------
create_entity:
    push rbx
    ; load current count (zero-extend byte → rbx)
    movzx rbx, byte [rel entity_count]
    cmp rbx, MAX_ENTITIES
    jae .err_full

    mov rcx, rbx
    imul rcx, rcx, ENTITY_SIZE
    ; compute address of entities[rbx]
    lea rax, [rel entities + rcx]

    ; store 32-bit positions
    mov dword [rax + ENTITY_X], esi
    mov dword [rax + ENTITY_Y], edx
    ; init last-pos = pos
    mov dword [rax + ENTITY_LAST_X], 0
    mov dword [rax + ENTITY_LAST_Y], 0 

    ; store type (low 8 bits of edi)
    mov byte [rax + ENTITY_TYPE], dil

    mov byte [rax + ENTITY_SPRITE_ID], dil

    ; pick glyph & lives by type
    cmp dil, ENTITY_TYPE_PLAYER
    je .L_player
    cmp dil, ENTITY_TYPE_MOB
    je .L_mob
    cmp dil, ENTITY_TYPE_PROJECTILE
    je .L_proj
    jmp .L_done_type

.L_player:
    mov byte [rax + ENTITY_LIVES], PLAYER_LIVES
    jmp .L_inc

.L_mob:
    mov byte [rax + ENTITY_LIVES], MOB_LIVES
    jmp .L_inc

.L_proj:
    mov byte [rax + ENTITY_LIVES], PROJECTILE_LIVES
    jmp .L_inc
.L_done_type:
    ; unknown type → zero them
    mov byte [rax + ENTITY_SPRITE_ID], 0
    mov byte [rax + ENTITY_LIVES], 0

.L_inc:
    ; bump entity_count and return the index in RAX
    inc byte [rel entity_count]
    mov rax, rbx
    pop rbx
    ret

.err_full:
    mov rax, -1
    pop rbx
    ret

;--------------------------------------------------------
; delete_entity 
;   description: deletes an entity at a specific index 
;   inputs: rax - entity index 
;   clobbers: rcx, rdx, rsi, rdi 
;--------------------------------------------------------
delete_entity:
    push rbx
    movzx rbx, byte [rel entity_count] ; get number of entities in game
    cmp rax, rbx ; jump to done if index is >= count (provided index is not valid number)
    jae .done

    mov rcx, rbx ; move entity count to rcx
    sub rcx, rax ; subtract index
    dec rcx ; subtract 1 (account for zero indexing) - now rcx is number of entities to move
 
    test rcx, rcx ; if rcx is 0, we are deleting last entity, no need to shift
    jz .skip_shift

    mov rdx, rcx ; numbers of entities we need to move
    imul rdx, rdx, ENTITY_SIZE ; now rdx holds number of bytes to move

    mov r8, rax
    imul r8, r8, ENTITY_SIZE
    lea rdi, [rel entities + r8] ; get address for entity we want to remove
    add r8, ENTITY_SIZE
    lea rsi, [rel entities + r8] ; get address for entity in front of entity we want to remove
    cld
    mov rcx, rdx ; set number of bytes we are moving
    rep movsb ; copies the data

.skip_shift:
    dec qword [rel entity_count]
    mov rbx, [rel entity_count]
    
    mov rbx, [rel entity_count]
    imul rbx, rbx, ENTITY_SIZE
    lea rdi, [rel entities + rbx]
    mov rcx, ENTITY_SIZE
    xor al, al
    cld 
    rep stosb

.done:
    pop rbx
    ret


;--------------------------------------------------------
; get_entity 
;   description: gets an entity at a specific index 
;   inputs: rax - entity index
;   output: rdi - pointer to entity
;   clobbers: rcx, rdx, rsi, rdi 
;--------------------------------------------------------
get_entity:
    movzx rbx, byte [rel entity_count]
    cmp rax, rbx
    jae .invalid
    mov rcx, rax
    imul rcx, rcx, ENTITY_SIZE
    lea rdi, [rel entities + rcx]
    ret

.invalid:
    xor rdi, rdi
    ret

;--------------------------------------------------------
; create_player 
;   description: creates the player at specified index 
;   inputs: esi - initial X, edx - initial Y
;   outpus: rax = operation status (0 = success, 1 = failure) 
;   clobbers: rcx, rdx, rsi, rdi 
;--------------------------------------------------------
create_player:  
    movzx rbx, byte [rel entity_count]
    test rbx, rbx
    jnz .player_created

    mov edi, ENTITY_TYPE_PLAYER
    call create_entity

;    cmp rax, -1
;    je .handle_error

.player_created:
    mov rax, 0
    ret

.handle_error:
    mov rax, 1
    ret

;--------------------------------------------------------
; create_mob 
;   description: creates a mob at specified index 
;   inputs: esi - initial X, edx - initial Y
;   outpus: rax = operation status (0 = success, 1 = failure) 
;   clobbers: rcx, rdx, rsi, rdi 
;--------------------------------------------------------
create_mob:
    mov edi, ENTITY_TYPE_MOB
    call create_entity

    cmp rax, -1
    je .handle_error
    mov rax, 0

.handle_error:
    mov rax, 1
    ret

;--------------------------------------------------------
; create_mob 
;   description: creates a mob at specified index 
;   inputs: esi - initial X, edx - initial Y, rcx - vx, r8 - vy
;   outpus: rax = operation status (0 = success, 1 = failure) 
;   clobbers: rcx, rdx, rsi, rdi 
;--------------------------------------------------------
create_projectile:
    push rcx
    push r8
    
    mov edi, ENTITY_TYPE_PROJECTILE
    call create_entity

    cmp rax, -1
    je .handle_error

    pop r8
    pop rcx

    imul rax, rax, ENTITY_SIZE
    lea rdi, [rel entities + rax]

    mov byte [rdi + ENTITY_VEL_X], cl
    mov byte [rdi + ENTITY_VEL_Y], r8b

    mov rax, 0

.handle_error:
    mov rax, 1
    ret

;--------------------------------------------------------
; move_player 
;   inputs: cl = DIR_* (0-3) 
;   outputs: updates [player_x], [player_y] 
;   clobbers:  rax, rdi, rsi, rdx
;--------------------------------------------------------
move_player:
    xor al, al
    
    mov rax, 0
    push rcx
    call get_entity
    pop rcx 
    
    movzx rax, cl
    
    lea rbx, [rel dir_to_move_func]
    mov rax, [rbx + rax * 8]
   
    call rax
    ret

mv_left:
    movzx rax, byte [rdi + ENTITY_X]
    cmp rax, 1
    jle mv_exit 
    dec rax
    mov byte [rdi + ENTITY_X], al 
    ret

mv_right:
    movzx rax, byte [rdi + ENTITY_X]
    mov rcx, BRAILLE_BOARD_WIDTH
    cmp rax, rcx 
    jge mv_exit 
    inc rax
    mov byte [rdi + ENTITY_X], al 
    ret

mv_up:
    movzx rax, byte [rdi + ENTITY_Y]
    cmp rax, 1 
    jle mv_exit 
    dec rax
    mov byte [rdi + ENTITY_Y], al 
    ret
  
mv_down:
    movzx rax, byte [rdi + ENTITY_Y]
    mov rcx, BRAILLE_BOARD_HEIGHT 
    cmp rax, rcx 
    jge mv_exit 
    inc rax
    mov byte [rdi + ENTITY_Y], al 
    ret

mv_exit:
    ret

;--------------------------------------------------------
; shoot_projectile 
;   inputs: cl = DIR_* (0-3) 
;   outputs: updates [player_x], [player_y] 
;   clobbers:  rax, rdi, rsi, rdx
;--------------------------------------------------------
shoot_projectile:
    push rcx
    xor al, al
    mov rax, 0
    call get_entity

    movzx rsi, byte [rdi + ENTITY_X]
    movzx rdx, byte [rdi + ENTITY_Y]
   
    pop rcx
    movzx rax, cl
    
    lea rbx, [rel dir_to_shoot_func]
    mov rax, [rbx + rax * 8]
    
    call rax
    ret

sht_left:
    dec rsi
    mov rcx, -1
    mov r8, 0
    call create_projectile
    ret

sht_right:
    inc rsi
    mov rcx, 1
    mov r8, 0
    call create_projectile
    ret

sht_up:
    dec rdx 
    mov rcx, 0
    mov r8, -1
    call create_projectile
    ret

sht_down:
    inc rdx 
    mov rcx, 0
    mov r8, -1
    call create_projectile
    ret

;--------------------------------------------------------
; update_entities 
;   inputs: cl = DIR_* (0-3) 
;   outputs: updates [player_x], [player_y] 
;   clobbers:  rax, rdi, rsi, rdx
;--------------------------------------------------------
update_entities:
    mov     rcx, 0
    mov     rdx, [entity_count]

.loop:
    cmp     rcx, rdx
    jge     .done

    ; ptr = &entities[rcx]
    mov     rax, rcx
    imul    rax, rax, ENTITY_SIZE
    lea     rdi, [rel entities + rax]

    ; skip if not projectile
    cmp     byte [rdi + ENTITY_TYPE], ENTITY_TYPE_PROJECTILE
    jne     .next

    ; skip if out of lives
    movzx   r9, byte [rdi + ENTITY_LIVES]
    test    r9, r9
    jz      .next

    ;–– update X ––
    movsx   rax, byte [rdi + ENTITY_X]
    movsx   rbx, byte [rdi + ENTITY_VEL_X]
    add     rax, rbx
    cmp     al,  BOARD_WIDTH
    jae     .out_of_bounds
    mov     byte [rdi + ENTITY_X], al

    ;–– update Y ––
    movsx   rax, byte [rdi + ENTITY_Y]
    movsx   rbx, byte [rdi + ENTITY_VEL_Y]
    add     rax, rbx
    cmp     al,  BOARD_HEIGHT
    jae     .out_of_bounds
    mov     byte [rdi + ENTITY_Y], al

    jmp     .next

.out_of_bounds:
    ; decrement lives only
    dec     byte [rdi + ENTITY_LIVES]

.next:
    inc     rcx
    jmp     .loop

.done:
    ret
