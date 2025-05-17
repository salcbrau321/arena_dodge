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

; state/game_state
extern entities
extern entity_count

section .text
    global create_entity
    global delete_entity
    global get_entity
    global create_player
    global create_mob

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

    mov rdx, rbx
    imul rdx, rdx, ENTITY_SIZE
    ; compute address of entities[rbx]
    lea rax, [rel entities + rdx]

    ; store 32-bit positions
    mov dword [rax + ENTITY_X], esi
    mov dword [rax + ENTITY_Y], edx
    ; init last-pos = pos
    mov dword [rax + ENTITY_LAST_X], esi
    mov dword [rax + ENTITY_LAST_Y], edx

    ; store type (low 8 bits of edi)
    mov byte [rax + ENTITY_TYPE], dil

    ; pick glyph & lives by type
    cmp dil, ENTITY_TYPE_PLAYER
    je .L_player
    cmp dil, ENTITY_TYPE_MOB
    je .L_mob
    cmp dil, ENTITY_TYPE_PROJECTILE
    je .L_proj
    jmp .L_done_type

.L_player:
    mov byte [rax + ENTITY_GLYPH], 0x40 
    mov byte [rax + ENTITY_LIVES], PLAYER_LIVES
    jmp .L_inc

.L_mob:
    mov byte [rax + ENTITY_GLYPH], 0x26 
    mov byte [rax + ENTITY_LIVES], MOB_LIVES
    jmp .L_inc

.L_proj:
    mov byte [rax + ENTITY_GLYPH], 0x2A 
    mov byte [rax + ENTITY_LIVES], PROJECTILE_LIVES
    jmp .L_inc

.L_done_type:
    ; unknown type → zero them
    mov byte [rax + ENTITY_GLYPH], 0
    mov byte [rax + ENTITY_LIVES], 0

.L_inc:
    ; bump entity_count and return the index in RAX
    inc byte [rel entity_count]
    mov rax, rbx
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

    cmp rax, -1
    je .handle_error

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
