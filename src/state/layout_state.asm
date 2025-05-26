;=============================================================================
; File:    layout_state.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-06
; 
; Description:
;   Utility routines and macros 
;=============================================================================

%include "game_layout.inc"
%include "constants.inc"
%include "utils.asm"

extern debug_u8

section .bss
    global board_x_offset
    global board_y_offset

winsize resw 4

game_x_offset resw 1
game_y_offset resw 1

board_x_offset resw 1
board_y_offset resw 1

braille_buff: resb BRAILLE_BOARD_WIDTH * BRAILLE_BOARD_HEIGHT

section .text
    global calculate_layout
    global get_window_size

;--------------------------------------------------------
; calculate_layout 
;   description: calculates current offsets of the game based in current winsize 
;   clobbers: eax, ebx, ecx
;--------------------------------------------------------
calculate_layout:
    movzx eax, word [rel winsize+2]   ; ws_col
    shr eax, 1                      ; cols/2
    mov ecx, BOARD_WIDTH
    shr ecx, 1                      ; BOARD_WIDTH/2
    sub eax, ecx                    ; (cols/2)-(board/2)
    cmp eax, 0
    jge .H_OK
    xor eax, eax                    ; clamp to 0
.H_OK:
    mov [rel board_x_offset], ax
    mov ebx, eax
    add ebx, GAME_AREA_PADDING_X
    mov [rel game_x_offset], bx

    movzx eax, word [rel winsize]   ; ws_col
    shr eax, 1                      ; rows/2
    mov ecx, BOARD_HEIGHT
    shr ecx, 1                      ; BOARD_HEIGHT/2
    sub eax, ecx                    ; (rows/2)-(board/2)
    cmp eax, 0
    jge .V_OK
    xor eax, eax
.V_OK:
    mov [rel board_y_offset], ax
    mov ebx, eax
    add ebx, GAME_AREA_PADDING_Y
    mov [rel game_y_offset], bx 
    
    ret

get_window_size:
    IOCTL STDOUT, TIOCGWINSZ, winsize
    ret
