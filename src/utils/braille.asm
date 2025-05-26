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
utf8_buffer:   resb 3

section .bss
cell_buffer:   resb BOARD_INNER_WIDTH * BOARD_INNER_HEIGHT

section .text
global emit_utf8_codepoint
global draw_cell_mask
global draw_sprite

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

draw_cell_mask:
	; RDI = cellX, RSI = cellY, RDX = mask, RBX = &cell_buffer
	mov rcx, rsi
	imul rcx, rcx, BOARD_INNER_WIDTH
	add rcx, rdi
	lea r8, [rbx + rcx]

	movzx r9d, byte [r8]
	mov al, dl
	or r9b, al
	cmp r9b, byte [r8]
	je .dcm_done
	mov [r8], r9b

	push rdi
	push rsi
    add rsi, board_y_offset
    add rdi, board_x_offset
	xchg rdi, rsi
	call set_cursor
	pop rsi
	pop rdi

	movzx ecx, r9b
	add ecx, 0x2800
	call emit_utf8_codepoint

.dcm_done:
	ret
; Updated draw_sprite in src/utils/braille.asm

draw_sprite:
 ; RDI = Xpix, RSI = Ypix, RDX = sprite_ptr
 push  r12
 push  r13
 push  r14
 push  r15
 push  r11

 mov   r12, rdi           ; Xpix
 mov   r13, rsi           ; Ypix
 mov   r10, rdx           ; sprite_ptr

 ; compute cellX and subX
 mov   rax, r12
 shr   rax, 1
 mov   r14, rax           ; cellX
 mov   rcx, r12
 and   rcx, 1
 mov   r11, rcx           ; subX

 ; compute cellY and subY
 mov   rax, r13
 shr   rax, 2
 mov   r15, rax           ; cellY
 mov   rcx, r13
 and   rcx, 3
 mov   r13, rcx           ; subY

 lea   rbx, [rel cell_buffer]
 lea   rsi, [r10 + 2]     ; baseMask pointer

 xor   rcx, rcx           ; row = 0
.row_loop:
 movzx r9d, byte [r10 + 1] ; height_in_cells
 cmp   rcx, r9
 jge   .done
 xor   rbp, rbp           ; col = 0

.col_loop:
 movzx r8d, byte [r10]    ; width_in_cells
 cmp   rbp, r8
 jge   .next_row

 ; compute index = row*width + col
 mov   rdx, rcx
 imul  rdx, r8
 add   rdx, rbp

 ; load base mask
 mov   al, [rsi + rdx]
 mov   bl, al

 ; horizontal shift (swap nibbles if subX==1)
 cmp   r11, 1
 jne   .no_horz
 movzx eax, bl
 mov   dl, al
 and   dl, 0x0F
 shl   dl, 4
 mov   dh, al
 shr   dh, 4
 mov   bl, dl
 or    bl, dh
.no_horz:

 ; vertical shift by subY (0–3)
 cmp   r13, 0
 je    .no_vert

 mov   dl, bl
 and   dl, 0x0F
 mov   dh, bl
 shr   dh, 4

 cmp   r13, 1
 je    .vert1
 cmp   r13, 2
 je    .vert2
 ; subY == 3
 shr   dl, 3
 shr   dh, 3
 jmp   .vert_done

.vert2:
 shr   dl, 2
 shr   dh, 2
 jmp   .vert_done

.vert1:
 shr   dl, 1
 shr   dh, 1

.vert_done:
 shl   dh, 4
 mov   bl, dl
 or    bl, dh

.no_vert:

 ; draw cell
 movzx rdx, bl
 mov   rdi, r14
 add   rdi, rbp         ; cellX + col
 mov   rsi, r15
 add   rsi, rcx         ; cellY + row
 call  draw_cell_mask

 inc   rbp
 jmp   .col_loop

.next_row:
 inc   rcx
 jmp   .row_loop

.done:
 pop   r11
 pop   r15
 pop   r14
 pop   r13
 pop   r12
 ret

