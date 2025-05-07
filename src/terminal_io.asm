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

global enable_raw_mode
global restore_mode
global read_key
global enable_nonblocking_input 

section .bss
    orig_tios resb 60
    updated_tios resb 60
    key_buffer resb 1

section .text

;--------------------------------------------------------
; Function: enable_raw_mode
;
; Purpose:
;   - Puts terminal into raw input mode (disable ICANON and ECHO)
;
; Clobbers:
;   - rax, rdi, rsi, rdx, rcx
;
; Notes:
;   - Must call restore_mode before exiting program
;--------------------------------------------------------
enable_raw_mode:
    mov rax, SYS_IOCTL ; Makes call to put the current tios settings into orig_tios
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [orig_tios]
    syscall

    lea rsi, [orig_tios] ; Copy contents (60 bytes) from orig_tios to updated_tios
    lea rdi, [updated_tios]
    mov rcx, 60
    rep movsb

    mov eax, [rel updated_tios + 12] ; Sets bits 1 and 3 to 0
    and eax, ~(ICANON|ECHO|ISIG) 
    mov [rel updated_tios + 12], eax
       
    mov rax, SYS_IOCTL ; Makes call to update the tios settings  
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [updated_tios]
    syscall
    ret

;--------------------------------------------------------
; Function: restore_mode 
;
; Purpose:
;   - Puts the terminal back into canonical mode 
;
; Clobbers:
;   - rax, rdi, rsi, rdx
;
; Notes:
;   - Must call before exiting program
;--------------------------------------------------------
restore_mode:
    mov rax, SYS_IOCTL ; Makes call to update the tios settings back to original values  
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [orig_tios]
    syscall
    ret

;--------------------------------------------------------
; Function: enable_nonblocking_input 
;
; Purpose:
;   - Enables non-blocking input so we are getting a constant stream of data from our sysread call 
;
; Clobbers:
;   - rax, rdi, rsi, rdx
;
; Notes:
;   - Must call before exiting program
;--------------------------------------------------------
enable_nonblocking_input:
    mov rax, SYS_FCNTL ; get current flags
    mov rdi, STDIN
    mov rsi, F_GETFL
    xor rdx, rdx
    syscall

    or rax, O_NONBLOCK

    mov rdi, STDIN
    mov rsi, F_SETFL
    mov rdx, rax 
    mov rax, SYS_FCNTL
    syscall
    ret

;--------------------------------------------------------
; Function: read_key 
;
; Purpose:
;   - Reads a single key press from the keyboard and returns the character pressed 
;
; Inputs:
;   - None
;
; Outputs:
;   - al = key pressed (1 byte, ASCII)
;
; Clobbers:
;   - rax, rdi, rsi, rdx
;
; Notes:
;   - Must call restore_mode before exiting program
;--------------------------------------------------------
read_key:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, key_buffer 
    mov rdx, 1
    syscall
  
    mov al, [key_buffer]
    ret


