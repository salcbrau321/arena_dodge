; src/utils/sprites.asm
section .data
global sprite_table

player_sprite:
    db 2, 1
    db 0x57, 0x07

mob_sprite:
    db 2, 1
    db 0x72, 0x02

projectile_sprite:
    db 1, 1
    db 0x01

sprite_table:
    dq player_sprite
    dq mob_sprite
    dq projectile_sprite
