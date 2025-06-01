; src/utils/braille.asm

%define FIRST_BYTE 0xE0
%define FIRST_MASK 0x0F
%define CONT_BYTE  0x80
%define CONT_MASK  0x3F

%include "game_layout.inc"

extern set_cursor
extern board_x_offset
extern board_y_offset

section .data
    global do_bits:

utf8_buffer:   resb 3
do_bits:
    db 0x01, 0x08
    db 0x02, 0x10
    db 0x04, 0x20
    db 0x40, 0x80

section .bss
    global player_sprite_variants
    global mob_sprite_variants
    global projectile_sprite_variants

cell_buffer:   resb BOARD_INNER_WIDTH * BOARD_INNER_HEIGHT

player_sprite_variants: resb 8 * 4
mob_sprite_variants: resb 8 * 4
projectile_sprite_variants: resb 8 * 1

section .text
    global emit_utf8_codepoint
    global update_cell_mask
    global update_sprite
    global plot_subpixel

emit_utf8_codepoint:
	lea rax, [rel utf8_buffer]
	mov rdx, rcx
	shr rdx, 12
	and dl, FIRST_MASK
	or dl, FIRST_BYTE
	mov [rax], dl
	inc rax

	mov rdx, rcx
	shr rdx, 6
	and dl, CONT_MASK
	or dl, CONT_BYTE
	mov [rax], dl
	inc rax

	mov rdx, rcx
	and dl, CONT_MASK
	or dl, CONT_BYTE
	mov [rax], dl

	mov edi, 1
	lea rsi, [rel utf8_buffer]
	mov edx, 3
	mov eax, 1
	syscall
	ret

update_cell_mask:
    ; RDI = cellX, RSI = cellY, RDX = mask, RBX = &cell_buffer, rcx = 0 = draw, rcx = 1 clear
    push rcx
    mov rcx, rsi
	imul rcx, rcx, BOARD_INNER_WIDTH
	add rcx, rdi
	lea r8, [rbx + rcx]
    pop rcx

	movzx r9d, byte [r8]
	mov al, dl
    cmp rcx, 0
    je .draw_cell
    not al ; invert and then and the registers to clear the bits from the mask
    and r9b, al
    jmp .cont
.draw_cell:
	or r9b, al ; or the registers to add the bits from the mask
.cont:
	cmp r9b, byte [r8]
	je .dcm_done
	mov [r8], r9b

	push rdi
	push rsi
    push rax
    movzx rax, word [rel board_y_offset]
    add rsi, rax 
    movzx rax, word [rel board_x_offset]
    add rdi, rax 
	xchg rdi, rsi
	call set_cursor
    pop rax
	pop rsi
	pop rdi

    push rcx
	movzx ecx, r9b
	add ecx, 0x2800
	call emit_utf8_codepoint
    pop rcx
.dcm_done:
	ret

;---------------------------------------------------
; update_sprite 
; description: plots a subpixel for a braille mask
; inputs: rdi - x subpixel coordinate 
;         rsi - y subpixel coordinate 
;         rdx - sprite index 
;         rcx - operation (0 = draw, 1 = clear)
; clobbers: rax
;---------------------------------------------------
update_sprite:
    ; Select variants buffer based on spriteID (rdx)
    cmp   rdx, 0
    je    .use_player
    cmp   rdx, 1
    je    .use_mob
    cmp   rdx, 2
    je    .use_projectile
    ret

.use_player:
    lea   r8, [rel player_sprite_variants]
    jmp   .got_variants

.use_mob:
    lea   r8, [rel mob_sprite_variants]
    jmp   .got_variants

.use_projectile:
    lea   r8, [rel projectile_sprite_variants]

.got_variants:
    ; Compute subX = baseX & 1, subY = baseY & 3
    mov   rax, rdi
    and   rax, 1
    mov   r9, rax

    mov   rax, rsi
    and   rax, 3
    mov   r10, rax

    ; variantIndex = subY*2 + subX
    mov   rax, r10
    shl   rax, 1
    add   rax, r9

    ; Point to 4-byte group
    lea   r8, [r8 + rax*4]

    ; Compute cellBaseX = baseX >> 1, cellBaseY = baseY >> 2
    mov   rax, rdi
    shr   rax, 1
    mov   r11, rax
    inc r11

    mov   rax, rsi
    shr   rax, 2
    mov   r12, rax
    inc r12

    ; Load masks
    movzx r13d, byte [r8 + 0]
    movzx r14d, byte [r8 + 1]
    movzx r15d, byte [r8 + 2]
    movzx r10d, byte [r8 + 3]

    ; Set RBX = &cell_buffer for update_cell_mask
    lea   rbx, [rel cell_buffer]

    ; Draw maskTL
    cmp   r13b, 0
    je    .skip_TL
    mov   edi, r11d
    mov   esi, r12d
    mov   edx, r13d
    push r11
    push rcx
    call  update_cell_mask
    pop rcx
    pop r11
.skip_TL:

    ; Draw maskTR
    cmp   r14b, 0
    je    .skip_TR
    mov   edi, r11d
    add   edi, 1
    mov   esi, r12d
    mov   edx, r14d
    push r11
    push rcx
    call  update_cell_mask
    pop rcx
    pop r11
.skip_TR:

    ; Draw maskBL
    cmp   r15b, 0
    je    .skip_BL
    mov   edi, r11d
    mov   esi, r12d
    add   esi, 1
    mov   edx, r15d
    push r11
    push rcx
    call  update_cell_mask
    pop rcx
    pop r11
.skip_BL:

    ; Draw maskBR
    cmp   r10b, 0
    je    .skip_BR
    mov   edi, r11d
    add   edi, 1
    mov   esi, r12d
    add   esi, 1
    mov   edx, r10d
    push r11
    push rcx
    call  update_cell_mask
    pop rcx
    pop r11
.skip_BR:

    ret
;---------------------------------------------------
; plot_subpixel
; description: plots a subpixel for a braille mask
; inputs: rdi - pointer to one byte from a buffer
;         rsi - local x (0 or 1)
;         rdx - local y (0..3)
; clobbers: rax
;---------------------------------------------------
plot_subpixel:
    push rbx
    mov rax, rdx
    shl rax, 1
    add rax, rsi

    mov bl, [rel do_bits + rax]
    or byte [rdi], bl
    pop rbx
    ret
