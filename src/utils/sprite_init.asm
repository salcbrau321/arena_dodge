extern do_bits
extern player_sprite
extern player_sprite_variants
extern plot_subpixel

section .text
    global init_sprite_variants

init_sprite_variants:
    lea rdi, [rel player_sprite]
    lea rsi, [rel player_sprite_variants]
    movzx rcx, byte [rdi + 1]
    movzx rdx, byte [rdi]
    add rdi, 2
    call init_sprite_variant
    ret

;-----------------------------------------------
; init_sprit_variants
; description: Computes all possible braille mask combinations for our sprites)
; inputs: rdi - pointer to sprite data
;         rsi - pointer to variants buffer
;         rdx - sprite height 
;         rcx - sprite width 
;----------------------------------------------
init_sprite_variant:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r8, 0 
    mov r9, 0
    mov r15, 0

.variant_loop: ; loops through the variant combinations (0,0 -> 0,1 -> 1,0 -> 1,1 -> etc) 
    cmp r9, 3
    jg .done_all ; max y position is 3, if we are going above 3, then we are done

    mov rax, r8 ; get our current x and y
    mov r10, r9
    xor rbx, rbx ; clear rbx (we will use to store byte 
.get_sprite_byte:
    mov r11, 0 ; setup r11 to be our bit index 
.calculate_loop ; loop where we actually build our braille masks
    movzx r12, byte [rdi + rbx] ; get current byte
    push r15
    mov r15, rcx ; subtract bit index from width to get value we need to shift by
    dec r15
    sub r15, r11
    push rcx
    mov rcx, r15
    shr r12, cl ; shift by count
    pop rcx
    and r12, 1 ; mask with 1 to get single bit
    pop r15

    cmp r12, 1 ; if bit is not zet we can go to next one
    jne .go_next

    mov r13, rax ; get copy of x coord 
    mov r14, r10 ; get copy of y coord 
    shr r13, 1 ; divide by two to figure out x coordinate for cell
    shr r14, 2 ; divide by four to figure out y coordinate for cell
    imul r14, r14, 2 ; multiply y cell coordinate by 2
    add r14, r13 ; add x cell coordinate so we can get position in buffer
    push rax
    mov rax, r15
    shl rax, 2
    add r14, rax
    pop rax
    push r15
    lea r15, [rsi + r14] ; load address of cell we want 
    
    mov r13, rax ; reload x and y
    mov r14, r10

    and r13, 1 ; do mod 2 and mod 4 to get the subpixel coordinates
    and r14, 3 

    push rdi ; presevere current register values then setup call to plot sub pixel
    push rsi
    push rdx
    push rax
    mov rdi, r15
    mov rsi, r13
    mov rdx, r14
    call plot_subpixel
    pop rax
    pop rdx
    pop rsi
    pop rdi
    pop r15
.go_next
    inc r11

    inc rax
    cmp r11, rcx
    jl .calculate_loop

    mov rax, r8
    inc r10
    inc rbx

    cmp r10, rdx
    jge .calculate_done

    jmp .get_sprite_byte
   
.calculate_done:

    inc r8 ; go to next sub-pixel
    inc r15

    cmp r8, 1 ; if it is 0 or 1, we contiune, otherwise reset and increment y
    jle .variant_loop

    mov r8, 0
    inc r9

    jmp .variant_loop

.done_all:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret



