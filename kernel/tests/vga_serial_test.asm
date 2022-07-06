vga_serial_test:
    call VGA_write_regs
    call disable_cursor
    call VGA_clear_screen

    mov bx, 10
    mov ax, 10
    mov cl, 1
    call draw_pixel

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
    ret
