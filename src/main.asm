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

; src/logic/entity.asm
extern update_player_location

; game_state.asm
extern init_game_state

; client_render_cli.asm
extern clear_screen
extern show_cursor
extern hide_cursor

; src/ui/render_entitites.asm
extern render_entities
extern re_render_entities

; src/ui/render_board.asm
extern render_board

; src/ui/resize_window_handler.asm
extern setup_win_resize 
extern window_resized

; layout_state.asm
extern calculate_layout
extern get_window_size

;=============================================================================
; EXTERNAL DATA 
;=============================================================================

; src/state/game_state.asm
extern entity_count

%include "constants.inc"
%include "utils.asm"

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

    WRITE welcomeMsg, welcomeMsgLen
    WRITE startMsg, startMsgLen
 
    call enable_raw_mode
    call read_key

    call clear_screen
    call get_window_size
    call calculate_layout
    call render_board 
    call init_game_state
    call setup_win_resize 
    ;call draw_player

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
    jne render_loop  

kb_thread:

kb_loop_start:
    call read_key 
    
    cmp al, 0x45
    je kb_loop_exit 

    cmp al, 0x65
    je kb_loop_exit 
    
    call update_player_location

    jmp kb_loop_start 

kb_loop_exit:
    call restore_mode
    call show_cursor
    call clear_screen

    SYSCALL SYS_EXIT_GROUP, 0

render_loop:
    cmp byte [rel window_resized], 1
    je handle_resize
    jne no_resize

handle_resize:
    call clear_screen
    call get_window_size
    call calculate_layout
    call render_board 
    call re_render_entities
    mov byte [rel window_resized], 0

no_resize:
    call render_entities
    jmp render_loop 
