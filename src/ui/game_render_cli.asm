;=============================================================================
; File:    client_render_cli.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-04
; 
; Description:
;   Contains the rendering functionality 
;=============================================================================

; state/layout_state.asm
extern board_x_offset
extern board_y_offset

extern set_cursor

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

