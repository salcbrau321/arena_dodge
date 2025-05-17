;=============================================================================
; File:    utils_asm.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-06
; 
; Description:
;   Utility routines and macros 
;=============================================================================

%include "constants.inc"

%ifndef UTILS_ASM
%define UTILS_ASM 1

;--------------------------------------------------------
;  Macro: WRITE buf, len
;   description: makes call to sys_write
;   clobbers: rax, rdi, rsi, rdx 
;--------------------------------------------------------
%macro WRITE 2
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [%1]
    mov rdx, %2
    syscall
%endmacro

;--------------------------------------------------------
;  Macro: IOCTL fd, request, butptr
;   description: makes call to sys_ioctl 
;   clobbers: rax, rdi, rsi, rdx 
;--------------------------------------------------------
%macro IOCTL 3
    mov rax, SYS_IOCTL
    mov rdi, %1
    mov rsi, %2
    lea rdx, [rel %3]
    syscall
%endmacro

;--------------------------------------------------------------------------------------
;  Macro: SYSCALL num, arg1?, arg2?, arg2?
;   description: Loads RAX with syscall number %1, RDI/RSI/RDX with %2/%3/%4 (if given)
;                then emits the syscall instruction
;   usage:
;       SYSCALL SYS_WRITE, STDOUT, buf, len
;       SYSCALL SYS_IOCTL, STDIN, TIOCGWINZ, winsize_buf
;   clobbers: rax, rdi, rsi, rdx 
;--------------------------------------------------------------------------------------
%macro SYSCALL 1-4
    mov rax, %1 
%if %0 >= 2
    mov rdi, %2
%endif
%if %0 >= 3
    mov rsi, %3
%endif
%if %0 >= 4
    mov rdx, %4
%endif
    syscall
%endmacro

%endif
