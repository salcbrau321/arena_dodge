; src/utils/sprites.asm
section .data
    global sprite_table
    global player_sprite
    global mob_sprite
    global projectile_sprite

player_sprite:
    db 3, 3
    db 0b111,
    db 0b101,
    db 0b111

mob_sprite:
    db 3, 3
    db 0b010, 
    db 0b111,
    db 0b010 

projectile_sprite:
    db 1, 1
    db 0x01

sprite_table:
    dq player_sprite
    dq mob_sprite
    dq projectile_sprite
