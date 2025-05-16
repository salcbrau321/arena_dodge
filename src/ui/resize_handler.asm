;=============================================================================
; File:    winresize_handler.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-15
; 
; Description:
;   Handler to catch when the window gets resized
;=============================================================================

%include "utils.asm"

section .bss
    global window_resized

    window_resized resb 1

section .data
    SIGWINCH equ 28
    SA_RESTART equ 0x10000000
    SA_RESTORER equ 0x04000000
    test_msg db "Window resized", 10 
    test_len equ $ - test_msg
    fail_msg db "Fail to register hook", 10 
    fail_len equ $ - fail_msg

sigaction_struct:
    dq resize_handler
    dq SA_RESTART | SA_RESTORER
    dq sigreturn_trampoline
    dq 0

section .text

global setup_win_resize

;--------------------------------------------------------
;  setups_win_resize 
;    description: "hooks" to the window resize event to trigger the resize_handler
;                whenever the window gets resized
;    clobbers: rax, rdi, rsi, rdx, r10 
;--------------------------------------------------------
setup_win_resize:
    mov rax, 13
    mov rdi, SIGWINCH
    lea rsi, [rel sigaction_struct]
    xor rdx, rdx
    mov r10, 8 
    syscall

    cmp rax, 0
    js .sig_fail
    ret

.sig_fail:
    WRITE fail_msg, fail_len
    ret
;--------------------------------------------------------
;  resize_handler 
;    description: updates the window_rezized flag to 1 
;--------------------------------------------------------
resize_handler:
    mov byte [rel window_resized], 1
    ret

sigreturn_trampoline:
    mov rax, 15
    syscall
