;=============================================================================
; File:    terminal_io.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-04
; 
; Description:
;   Contains functionality to turn raw mode on and off and to read keyboard input
;=============================================================================

%include "constants.inc"
%include "utils.asm"

global enable_raw_mode
global restore_mode
global read_key
global enable_nonblocking_input 
global set_cursor
global show_cursor
global hide_cursor
global clear_screen
global debug_u8

section .data
    cursor_seq db 27, '[', '0', '0', '0', '0', ';', '0', '0', '0', '0', 'H'
    cursor_len equ $ - cursor_seq

    hide_cursor_seq db 0x1B, '[', '?', '2', '5', 'l'
    hide_len equ $ - hide_cursor_seq

    show_cursor_seq db 0x1B, '[', '?', '2', '5', 'h'
    show_len equ $ - show_cursor_seq
    
    clear_seq db 27, '[', '2', 'J', 27, '[', 'H'
    clear_len equ $ - clear_seq

    move_right db 0x1B, '[', 'C'
    mr_len equ $ - move_right

    move_down db 0x1B, '[', '1', 'B'
    md_len equ $ - move_down 

    move_left db 0x1B, '[', '1', 'D'
    ml_len equ $ - move_left

section .bss
    orig_tios resb 60
    updated_tios resb 60
    key_buffer resb 1
    debug_buf resb 6

section .text

;--------------------------------------------------------
; enable_raw_mode
;   description: puts terminal into raw input mode (disable ICANON and ECHO)
;   clobbers: rax, rdi, rsi, rdx, rcx
;   notes: must call restore_mode before exiting program
;--------------------------------------------------------
enable_raw_mode:
    IOCTL STDIN, TCGETS, orig_tios ; gets current tios

    lea rsi, [rel orig_tios] ; Copy contents (60 bytes) from orig_tios to updated_tios
    lea rdi, [rel updated_tios]
    mov rcx, 60
    rep movsb

    mov eax, [rel updated_tios + 12] ; Sets bits 1 and 3 to 0
    and eax, ~(ICANON|ECHO|ISIG) 
    mov [rel updated_tios + 12], eax
       
    IOCTL STDIN, TCSETS, updated_tios ; updates tios
    
    ret

;--------------------------------------------------------
; restore_mode 
;   description: Puts the terminal back into canonical mode 
;   clobbers: rax, rdi, rsi, rdx
;   notes: must be called before exiting the program
;--------------------------------------------------------
restore_mode:
    IOCTL STDIN, TCSETS, orig_tios
    ret

;--------------------------------------------------------
; enable_nonblocking_input 
;   description: enables non-blocking input so we are getting a constant stream of data from our sysread call 
;   clobbers: rax, rdi, rsi, rdx
;--------------------------------------------------------
enable_nonblocking_input:
    xor rdx, rdx ; clear to avoid any issues
    SYSCALL SYS_FCNTL, STDIN, F_GETFL ; do get fl
    
    or rax, O_NONBLOCK ; set flag

    mov rdx, rax ; move result to rdx
    
    SYSCALL SYS_FCNTL, STDIN, F_SETFL, rdx ; do set fl
    ret

;--------------------------------------------------------
; read_key 
;   description: reads a single key press from the keyboard and returns the character pressed 
;   outputs: al = key pressed (1 byte, ASCII)
;   clobbers: rax, rdi, rsi, rdx
;--------------------------------------------------------
read_key:
    SYSCALL SYS_READ, STDIN, key_buffer, 1
    mov al, [key_buffer]
    ret

;--------------------------------------------------------
; clear_screen 
;   description: clears the entire terminal amd move cursor to 1, 1 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------
clear_screen:
    WRITE clear_seq, clear_len 
    ret

;--------------------------------------------------------
; hide_cursor 
;   description: stops the cursor from displaying 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------
hide_cursor:
    WRITE hide_cursor_seq, hide_len 
    ret

;--------------------------------------------------------
; show_cursor 
;   description: turns cursor back on 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------
show_cursor:
    WRITE show_cursor_seq, show_len 
    ret

;--------------------------------------------------------
; move_cursor 
;   description: turns cursor back on 
;   clobbers: rdi, rsi, rcx, rax, rdx
;--------------------------------------------------------

;--------------------------------------------------------
; set_cursor
;   description: updates cursor to new location based on row and column number 
;   inputs: rdi = row number, rsi = column number
;   clobbers: rdi, rsi, rax, rcx, rdx 
;--------------------------------------------------------
set_cursor:
    ; convert to 1-based
    inc     rdi
    inc     rsi

    ; ── build row (4 digits) ────────────────────────────────
    mov     rax, rdi      ; RAX = row+1
    mov     rcx, 1000
    xor     rdx, rdx
    div     rcx           ; RAX = row/1000, RDX = row%1000
    add     al, '0'
    mov     [rel cursor_seq+2], al

    mov     rax, rdx      ; remainder
    mov     rcx, 100
    xor     rdx, rdx
    div     rcx           ; RAX = (row%1000)/100, RDX = %100
    add     al, '0'
    mov     [rel cursor_seq+3], al

    mov     rax, rdx      ; remainder
    mov     rcx, 10
    xor     rdx, rdx
    div     rcx           ; RAX = (row%100)/10, RDX = %10
    add     al, '0'
    mov     [rel cursor_seq+4], al

    add     dl, '0'       ; ones digit
    mov     [rel cursor_seq+5], dl

    ; ── build col (4 digits) ────────────────────────────────
    mov     rax, rsi
    mov     rcx, 1000
    xor     rdx, rdx
    div     rcx
    add     al, '0'
    mov     [rel cursor_seq+7], al

    mov     rax, rdx
    mov     rcx, 100
    xor     rdx, rdx
    div     rcx
    add     al, '0'
    mov     [rel cursor_seq+8], al

    mov     rax, rdx
    mov     rcx, 10
    xor     rdx, rdx
    div     rcx
    add     al, '0'
    mov     [rel cursor_seq+9], al

    add     dl, '0'
    mov     [rel cursor_seq+10], dl

    ; emit the CSI sequence
    WRITE   cursor_seq, cursor_len
    ret

;--------------------------------------------------------
; debug_u8
; Prints value in AL as decimal (0–255) + newline
; Input: AL = value
; Clobbers: rax, rbx, rcx, rdx, rdi, rsi
;--------------------------------------------------------
debug_u8:
    movzx   eax, ax                   ; zero-extend full 16-bit value into EAX
    xor     ecx, ecx                  ; digit count = 0
    mov     rbx, 10                   ; divisor
    lea     rdi, [rel debug_buf + 5]  ; pointer to end of buffer

.convert_loop:
    xor     rdx, rdx                  ; clear RDX for div
    div     rbx                       ; EAX = EAX/10, RDX = EAX%10
    dec     rdi                       ; back up one slot
    add     dl, '0'                   ; convert digit to ASCII
    mov     [rdi], dl                 ; store digit
    inc     ecx                       ; count it
    test    rax, rax
    jnz     .convert_loop             ; repeat until quotient = 0

    mov     byte [rel debug_buf + 5], 10  ; append '\n'

    mov     rsi, rdi                  ; RSI = pointer to first digit
    mov     rdx, rcx                  ; RDX = digit count
    inc     rdx                       ; +1 for newline
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    syscall

    ret
