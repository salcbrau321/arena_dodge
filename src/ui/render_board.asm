;=============================================================================
; File:    render_board.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-04
; 
; Description:
;   Contains the rendering functionality 
;=============================================================================


%include "constants.inc"
%include "game_layout.inc"
%include "utils.asm"

; from ui/terminal_io.asm
extern set_cursor
extern move_left
extern move_down
extern debug_u8

; from state/game_layout.asm 
extern board_x_offset
extern board_y_offset

section .data
    left_border_char   db '▐'
    lb_len equ $ - left_border_char

    top_border_char db '▄'
    tb_len equ $ - top_border_char

    right_border_char db '▌'
    rb_len equ $ - right_border_char

    bottom_border_char db '▀'
    bb_len equ $ - bottom_border_char

    move_right db 0x1B, '[', 'C'
    mr_len equ $ - move_right

    move_down db 0x1B, '[', '1', 'B'
    md_len equ $ - move_down

    move_left db 0x1B, '[', '1', 'D'
    ml_len equ $ - move_left

section .text
    global render_board

;--------------------------------------------------------
; render_board 
;   description: clears the screen and then initializes the game board
;   clobbers: rdi, rsi, rbx, rax, rdx
;--------------------------------------------------------
render_board:

.top_border_setup:
    movzx rsi, word [rel board_x_offset] ; set x offset 
    inc rsi ; increment by 1 (we will use different symbol for the edge
    movzx rdi, word [rel board_y_offset] ; set y offset 

    call set_cursor

    mov rbx, BOARD_WIDTH ; get the max number of columns
    sub rbx, 2 ; decrement by 1 (to account for the edge symbol)

.top_border_loop: ; loop draws top border

    WRITE top_border_char, tb_len

    dec rbx ; decremnt rbx

    jnz .top_border_loop

.left_boder_setup:
    movzx rsi, word [rel board_x_offset] ; set column number to 1
    movzx rdi, word [rel board_y_offset] ; set row number to 2
    inc rdi
    
    call set_cursor

    mov rbx, BOARD_HEIGHT 
    sub rbx, 2 

.left_border_loop: ; loop draws left border

    WRITE left_border_char, lb_len
    WRITE move_left, ml_len
    WRITE move_down, md_len

    dec rbx ; decremnt rbx

    jnz .left_border_loop

.bottom_border_setup:
    movzx rsi, word [rel board_x_offset] 
    inc rsi
    movzx rdi, word [rel board_y_offset] 
    add rdi, BOARD_HEIGHT
    dec rdi

    call set_cursor

    mov rbx, BOARD_WIDTH
    sub rbx, 2
.bottom_border_loop:

    WRITE bottom_border_char, bb_len

    dec rbx ; decremnt rbx

    jnz .bottom_border_loop

.right_border_setup:
    movzx rsi, word [rel board_x_offset] 
    add rsi, BOARD_WIDTH
    dec rsi
    movzx rdi, word [rel board_y_offset]  
    inc rdi

    call set_cursor

    mov rbx, BOARD_HEIGHT 
    sub rbx, 2

.right_border_loop: ; loop draws left border

    WRITE right_border_char, rb_len
    WRITE move_left, ml_len
    WRITE move_down, md_len

    dec rbx ; decremnt rbx

    jnz .right_border_loop
    ret

