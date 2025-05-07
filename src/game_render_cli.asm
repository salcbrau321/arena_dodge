;=============================================================================
; File:    client_render_cli.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-04
; 
; Description:
;   Contains the rendering functionality 
;=============================================================================

global set_cursor
global init_game_board 
global draw_player
global clear_player
global clear_screen
global show_cursor
global hide_cursor

extern player_y
extern player_x

%include "constants.inc"
%include "utils.asm"

section .data
    cursor_seq db 27, '[', '0', '0', ';', '0', '0', 'H'
    cursor_len equ $ - cursor_seq

    hide_cursor_seq db 0x1B, '[', '?', '2', '5', 'l'
    hide_len equ $ - hide_cursor_seq

    show_cursor_seq db 0x1B, '[', '?', '2', '5', 'h'
    show_len equ $ - show_cursor_seq
    
    clear_seq db 27, '[', '2', 'J', 27, '[', 'H'
    clear_len equ $ - clear_seq

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

    player_char db '@'
    player_len equ $ - player_char

    blank db ' '
    blank_len equ $ - blank

section .bss
    offset_row resq 1
    offset_col resq 1
    top_padding resq 1
    
section .text

;--------------------------------------------------------
; set_cursor
;   description: updates cursor to new location based on row and column number 
;   inputs: rdi = row number, rsi = column number
;   clobbers: rdi, rsi, rax, rcx, rdx 
;--------------------------------------------------------
set_cursor:
    mov rcx, 10
    
    mov rax, rdi ; takes row number and divides by 10 
    xor rdx, rdx
    div rcx 

    add dl, '0' ; converts values to ascii
    add al, '0'

    mov [rel cursor_seq + 2], al ; updates row part of our cursor sequence
    mov [rel cursor_seq + 3], dl
   
    mov rax, rsi ; repeats same step for the column 
    xor rdx, rdx
    div rcx 

    add dl, '0'
    add al, '0'
    mov [rel cursor_seq + 5], al
    mov [rel cursor_seq + 6], dl
    
    mov rax, SYS_WRITE ; writes cursor sequence 
    mov rdi, STDOUT
    mov rsi, cursor_seq 
    mov rdx, cursor_len
  
    syscall
    ret

;--------------------------------------------------------
; init_game_board
;   description: clears the screen and then initializes the game board 
;   clobbers: rdi, rsi, rbx, rax, rdx
;--------------------------------------------------------
init_game_board:
    call clear_screen

    mov rdi, 1 ; set row number to 1 
    mov rsi, 2 ; set column number to 3

    call set_cursor
    
    mov rbx, MAX_COLS ; get the max number of columns

.top_border_loop: ; loop draws top border

    mov rax, SYS_WRITE ; writes horizontal dash
    mov rdi, STDOUT
    mov rsi, top_border_char 
    mov rdx, tb_len
    syscall
    
    dec rbx ; decremnt rbx 

    jnz .top_border_loop

    mov rdi, 2 ; set row number to 2
    mov rsi, 1 ; set column number to 1 
    call set_cursor    

    mov rbx, MAX_ROWS

.left_border_loop: ; loop draws left border
    
    mov rax, SYS_WRITE ; writes vertical dash
    mov rdi, STDOUT
    mov rsi, left_border_char
    mov rdx, lb_len
    syscall
    
    mov rax, SYS_WRITE ; moves one column left 
    mov rdi, STDOUT
    mov rsi, move_left
    mov rdx, ml_len
    syscall

    mov rax, SYS_WRITE ; moves one column down 
    mov rdi, STDOUT
    mov rsi, move_down
    mov rdx, md_len
    syscall
    
    dec rbx ; decremnt rbx 

    jnz .left_border_loop

    mov rdi, MAX_ROWS ; set row number to MAX_ROWS + 2
    add rdi, 2
    mov rsi, 2 ; set column number to 3 
    call set_cursor    

    mov rbx, MAX_COLS

.bottom_border_loop:
    
    mov rax, SYS_WRITE ; writes vertical dash
    mov rdi, STDOUT
    mov rsi, bottom_border_char 
    mov rdx, bb_len
    syscall
    
    dec rbx ; decremnt rbx 

    jnz .bottom_border_loop

    mov rdi, 2 ; set row number to 1
    mov rsi, MAX_COLS ; set column number to MAXCOLS + 4
    add rsi, 2 
    call set_cursor    

    mov rbx, MAX_ROWS

.right_border_loop: ; loop draws left border
    
    mov rax, SYS_WRITE ; writes vertical dash
    mov rdi, STDOUT
    mov rsi, right_border_char 
    mov rdx, rb_len
    syscall
    
    mov rax, SYS_WRITE ; moves one column left 
    mov rdi, STDOUT
    mov rsi, move_left
    mov rdx, ml_len
    syscall

    mov rax, SYS_WRITE ; moves one column down 
    mov rdi, STDOUT
    mov rsi, move_down
    mov rdx, md_len
    syscall
    
    dec rbx ; decremnt rbx 

    jnz .right_border_loop
    ret

;--------------------------------------------------------
; clear_player 
;   description: clears the player at its current location 
;   clobbers: rdi, rsi, rax, rdx
;--------------------------------------------------------
clear_player:
    mov rdi, [player_y]
    inc rdi
    mov rsi, [player_x] 
    inc rsi

    call set_cursor
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, blank
    mov rdx, blank_len
    syscall
    ret

;--------------------------------------------------------
; clear_player 
;   description: clears the player at its current location 
;   clobbers: rdi, rsi, rax, rdx
;--------------------------------------------------------
draw_player:
    mov rdi, [player_y]
    inc rdi
    mov rsi, [player_x] 
    inc rsi

    call set_cursor
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, player_char 
    mov rdx, player_len 
    syscall
    ret

;--------------------------------------------------------
; clear_screen 
;   description: clears the entire terminal amd move cursor to 1, 1 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------
clear_screen:
    WRITE clear_seq, clear_len 
    syscall
    ret

;--------------------------------------------------------
; hide_cursor 
;   description: stops the cursor from displaying 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------
hide_cursor:
    WRITE hide_cursor_seq, hide_len 
    syscall
    ret

;--------------------------------------------------------
; show_cursor 
;   description: turns cursor back on 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------
show_cursor:
    WRITE show_cursor_seq, show_len 
    syscall
    ret
