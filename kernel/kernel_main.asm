kernel_main:
    ; mov ch, 0 ; y
    ; mov cl, 1 ; x
    ; mov dl, byte 'U'=222
    ; mov dh, byte 0x5
    ; call vga_textmode_setchar
    ; call clear_textmode_buffer

    ; mov ch, 0
    ; mov cl, 0
    ; mov ebx, test_string
    ; mov dh, byte 0x5
    ; call vga_textmode_setstring

    call VGA_write_regs
    call disable_cursor
    call VGA_clear_screen

    mov bx, 0
    draw_lp_1:
    mov ax, bx
    add ax, 60
    mov cl, 1
    call draw_pixel
    mov ax, 260
    sub ax, bx
    mov cl, 2
    call draw_pixel
    inc bx
    cmp bx, DISPLAY_height
    jl draw_lp_1

    ; mov eax, MEM_START
    ; mov ebx, 0x80400000
    ; call kinit1

    ; mov [0xb8000], byte 'X'

    ret


; test_string db 'test123', 0
