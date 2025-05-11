; constants.inc — global constants for the Arena Dodge game

; Syscall numbers (x86-64 Linux)
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60
%define SYS_IOCTL 16
%define SYS_CLONE 56
%define SYS_EXIT_GROUP 231
%define SYS_FCNTL 72

; FCNTL call options
%define F_GETFL 3
%define F_SETFL 4
%define O_NONBLOCK 0x800


; Flags for clone call
%define CLONE_VM      0x00000100
%define CLONE_FS      0x00000200
%define CLONE_FILES   0x00000400
%define CLONE_SIGHAND 0x00000800
%define CLONE_THREAD  0x00010000

; IOCTL call options 
%define TCGETS 0x5401
%define TCSETS 0x5402
%define TIOCGWINSZ 0x5413

; Flags for IOTCL
%define ICANON 0x0002
%define ECHO 0x0008
%define ISIG 0x0001

%define THREAD_FLAGS (CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD)

; Standard file descriptors
%define STDIN 0
%define STDOUT 1
%define STDERR 2

; Screen dimensions (columns × rows)
%define MAX_COLS 80
%define MAX_ROWS 30

; ANSI escape parsing for arrow keys
%define ESC 27 ; ASCII Escape
%define CSI '[' ; Control Sequence Introducer

; After ESC CSI one of these
%define KEY_UP 'A'
%define KEY_DOWN 'B'
%define KEY_RIGHT 'C'
%define KEY_LEFT 'D'

; Optional WASD controls
%define KEY_W 'w'
%define KEY_A 'a'
%define KEY_S 's'
%define KEY_D 'd'

; Entity struct
ENTITY_X: equ 0
ENTITY_Y: equ 1
ENTITY_LAST_X: equ 2
ENTITY_LAST_Y: equ 3
ENTITY_TYPE: equ 4
ENTITY_GLYPH: equ 5
ENTITY_ALIVE: equ 6
ENTITY_LIVES: equ 7
ENTITY_FLAGS: equ 8
ENTITY_SIZE: equ 16

; Settings
MAX_ENTITIES: equ 64
