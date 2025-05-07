;=============================================================================
; File:    main.asm
; Project: Arena Dodge (x64 Assembly)
; Author:  Braulio Salcedo 
; Date:    2025-05-04
; 
; Description:
;   Entry point and main game loop.  Sets up terminal, reads input,
;   updates entities, draws frame, and exits.
;
; Build:
;   nasm -f elf64 -o build/main.o src/main.asm
;   ld -o arena_dodge build/*.o
;=============================================================================

;=============================================================================
; EXTERNAL METHODS 
;=============================================================================

; terminal_io.asm
extern enable_raw_mode
extern restore_mode
extern read_key
extern enable_nonblocking_input

; game_logic.asm
extern update_player

; game_state.asm
extern init_game_state
extern player_x
extern player_y

; client_render_cli.asm
extern init_game_board 
extern clear_player
extern draw_player
extern clear_screen
extern show_cursor
extern hide_cursor

%include "constants.inc"

section .data
    welcomeMsg db "Welcome to Arena Dodge!", 10
    welcomeMsgLen equ $ - welcomeMsg
    startMsg db "Press any key to continue...", 10
    startMsgLen equ $ - startMsg

section .bss
    keyBuffer resb 1
    keyInputThreadStack resb 4096
    dbg_buf resb 4

section .text
    global _start

_start:
    call clear_screen
    call hide_cursor

    mov rax, SYS_WRITE ; welcome message
    mov rdi, STDOUT
    mov rsi, welcomeMsg
    mov rdx, welcomeMsgLen
    syscall

    mov rax, SYS_WRITE ; write continue message
    mov rdi, STDOUT
    mov rsi, startMsg 
    mov rdx, startMsgLen 
    syscall
 
    call enable_raw_mode
    call read_key

    call init_game_board
    call init_game_state
    
    call draw_player

clone:
    mov rax, SYS_CLONE ; starts a thread
    mov rdi, THREAD_FLAGS 
    lea rsi, [keyInputThreadStack + 4096] 
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall

    test rax, rax ; if rax is 0, go to je (start thread), other wise run main loop
    je kb_thread 
    jne main_loop

kb_thread:

kb_loop_start:
    call read_key 
    
    cmp al, 0x45
    je kb_loop_exit 

    cmp al, 0x65
    je kb_loop_exit 
    
    push rax
    call clear_player
    pop rax
    call update_player
    call draw_player

    jmp kb_loop_start 

kb_loop_exit:
    call restore_mode
    call show_cursor
    call clear_screen

    mov rax, SYS_EXIT_GROUP
    mov rdi, 0
    syscall

main_loop:
    jmp main_loop 

